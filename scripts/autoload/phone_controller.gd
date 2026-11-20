extends Node
## Embedded Single-Port HTTP + RFC 6455 WebSocket Server & DualSense iPhone 15 Input/Telemetry Bridge.
## Hosts the iPhone landscape web controller locally on LAN (1-2ms latency) and optionally via
## Cloudflare Internet Tunnel (for 5G / cross-network play) with zero external setup required.

signal mode_changed(use_phone: bool)
signal connection_changed(connected: bool, client_count: int, device_label: String)
signal url_changed(active_url: String, is_tunnel: bool)
signal remote_begin_ascent()
signal remote_toggle_pause()
signal remote_resume()
signal remote_restart_climb()
signal remote_teleport_world(world_idx: int)

const WebAsset = preload("res://scripts/autoload/phone_controller_web_asset.gd")
const WS_MAGIC := "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
const DEFAULT_PORT := 8765
const TUNNEL_LOG_PATH := "/tmp/solstice_spire_tunnel.log"

var use_phone_controller: bool = false
var is_connected: bool = false
var client_device_name: String = "iPhone 15"
var server_port: int = DEFAULT_PORT
var lan_ip: String = "127.0.0.1"
var tunnel_url: String = ""
var tunnel_starting: bool = false
var use_tunnel_mode: bool = false

# Live Analog & Button State
var _move_vec: Vector2 = Vector2.ZERO
var _look_stick: Vector2 = Vector2.ZERO
var _look_delta: Vector2 = Vector2.ZERO
var _sprint_held: bool = false
var _jump_held: bool = false
var _dash_held: bool = false
var _slide_held: bool = false
var _rewind_held: bool = false

# Sub-frame edge latches (guarantees even <10ms micro-taps register in _physics_process)
var _jump_just_pressed_latch: bool = false
var _dash_just_pressed_latch: bool = false
var _slide_just_pressed_latch: bool = false
var _rewind_just_pressed_latch: bool = false

var _orb_locked: bool = false
var _telemetry_timer: float = 0.0
var _tunnel_poll_timer: float = 0.0
var _tunnel_pid: int = -1

var _tcp_server: TCPServer = TCPServer.new()
var _http_clients: Array[Dictionary] = []
var _ws_clients: Array[Dictionary] = []
var _closing_clients: Array[Dictionary] = []
var _html_bytes: PackedByteArray
var _font_bytes: PackedByteArray


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_detect_lan_ip()
	_load_web_assets()
	_start_server()


func _exit_tree() -> void:
	stop_internet_tunnel()
	if _tcp_server.is_listening():
		_tcp_server.stop()
	_http_clients.clear()
	_ws_clients.clear()


func set_phone_mode(enabled: bool) -> void:
	if use_phone_controller == enabled:
		return
	use_phone_controller = enabled
	mode_changed.emit(use_phone_controller)


func get_active_url() -> String:
	if use_tunnel_mode and not tunnel_url.is_empty():
		return tunnel_url
	return "http://%s:%d" % [lan_ip, server_port]


func is_active() -> bool:
	return is_connected or _move_vec.length_squared() > 0.001 or _look_stick.length_squared() > 0.001


func get_move_vector() -> Vector2:
	return _move_vec


func get_look_stick() -> Vector2:
	return _look_stick


func consume_look_delta() -> Vector2:
	var d := _look_delta
	_look_delta = Vector2.ZERO
	return d


func is_sprint_active() -> bool:
	return _sprint_held


func is_jump_held() -> bool:
	return _jump_held


func consume_jump_just_pressed() -> bool:
	if _jump_just_pressed_latch:
		_jump_just_pressed_latch = false
		return true
	return false


func consume_dash_just_pressed() -> bool:
	if _dash_just_pressed_latch:
		_dash_just_pressed_latch = false
		return true
	return false


func consume_slide_just_pressed() -> bool:
	if _slide_just_pressed_latch:
		_slide_just_pressed_latch = false
		return true
	return false


func consume_rewind_just_pressed() -> bool:
	if _rewind_just_pressed_latch:
		_rewind_just_pressed_latch = false
		return true
	return false


func set_orb_locked(locked: bool) -> void:
	if _orb_locked != locked:
		_orb_locked = locked
		_broadcast_telemetry()


func send_haptic(kind: String) -> void:
	if _ws_clients.is_empty():
		return
	var msg := JSON.stringify({"t": "haptic", "kind": kind})
	_broadcast_ws_text(msg)


func start_internet_tunnel() -> void:
	use_tunnel_mode = true
	if not tunnel_url.is_empty():
		url_changed.emit(get_active_url(), true)
		return
	if tunnel_starting:
		return
	var cf_path := "/opt/homebrew/bin/cloudflared"
	if not FileAccess.file_exists(cf_path):
		cf_path = "/usr/local/bin/cloudflared"
	if not FileAccess.file_exists(cf_path):
		use_tunnel_mode = false
		url_changed.emit(get_active_url(), false)
		return

	tunnel_starting = true
	if FileAccess.file_exists(TUNNEL_LOG_PATH):
		DirAccess.remove_absolute(TUNNEL_LOG_PATH)
	var cmd := "%s tunnel --url http://127.0.0.1:%d --no-autoupdate > %s 2>&1" % [cf_path, server_port, TUNNEL_LOG_PATH]
	_tunnel_pid = OS.create_process("/bin/zsh", ["-c", cmd])
	url_changed.emit(get_active_url(), true)


func stop_internet_tunnel() -> void:
	use_tunnel_mode = false
	tunnel_starting = false
	tunnel_url = ""
	if _tunnel_pid > 0:
		OS.kill(_tunnel_pid)
		_tunnel_pid = -1
	url_changed.emit(get_active_url(), false)


func set_network_mode(enable_tunnel: bool) -> void:
	if enable_tunnel:
		start_internet_tunnel()
	else:
		use_tunnel_mode = false
		url_changed.emit(get_active_url(), false)


func _detect_lan_ip() -> void:
	var candidates: Array[String] = []
	for addr in IP.get_local_addresses():
		if addr.contains(":"):
			continue
		if addr.begins_with("127.") or addr.begins_with("169.254."):
			continue
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			candidates.append(addr)
	if not candidates.is_empty():
		# Prefer 192.168.x.x primary home/office LAN
		for c in candidates:
			if c.begins_with("192.168."):
				lan_ip = c
				return
		lan_ip = candidates[0]


func _load_web_assets() -> void:
	if FileAccess.file_exists("res://assets/web/phone_controller.html"):
		var f := FileAccess.open("res://assets/web/phone_controller.html", FileAccess.READ)
		if f:
			_html_bytes = f.get_buffer(f.get_length())
	if _html_bytes.is_empty():
		_html_bytes = WebAsset.HTML.to_utf8_buffer()

	if FileAccess.file_exists("res://assets/fonts/Nunito.ttf"):
		var ff := FileAccess.open("res://assets/fonts/Nunito.ttf", FileAccess.READ)
		if ff:
			_font_bytes = ff.get_buffer(ff.get_length())


func _start_server() -> void:
	for p in range(DEFAULT_PORT, DEFAULT_PORT + 10):
		var err := _tcp_server.listen(p, "0.0.0.0")
		if err == OK:
			server_port = p
			break


func _process(delta: float) -> void:
	_accept_new_connections()
	_poll_http_clients()
	_poll_ws_clients()
	_poll_closing_clients()

	if tunnel_starting and tunnel_url.is_empty():
		_tunnel_poll_timer += delta
		if _tunnel_poll_timer >= 0.35:
			_tunnel_poll_timer = 0.0
			_check_tunnel_log()

	if not _ws_clients.is_empty():
		_telemetry_timer += delta
		if _telemetry_timer >= 0.08:
			_telemetry_timer = 0.0
			_broadcast_telemetry()


func _check_tunnel_log() -> void:
	if not FileAccess.file_exists(TUNNEL_LOG_PATH):
		return
	var f := FileAccess.open(TUNNEL_LOG_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	var regex := RegEx.new()
	regex.compile("https://[a-zA-Z0-9-]+\\.trycloudflare\\.com")
	var m := regex.search(txt)
	if m:
		tunnel_url = m.get_string()
		tunnel_starting = false
		url_changed.emit(get_active_url(), true)


func _accept_new_connections() -> void:
	while _tcp_server.is_listening() and _tcp_server.is_connection_available():
		var peer := _tcp_server.take_connection()
		if peer:
			peer.set_no_delay(true)
			_http_clients.append({
				"peer": peer,
				"buf": PackedByteArray(),
				"born": Time.get_ticks_msec()
			})


func _poll_http_clients() -> void:
	var now := Time.get_ticks_msec()
	for i in range(_http_clients.size() - 1, -1, -1):
		var c: Dictionary = _http_clients[i]
		var peer: StreamPeerTCP = c["peer"]
		peer.poll()
		var st := peer.get_status()
		if st == StreamPeerTCP.STATUS_NONE or st == StreamPeerTCP.STATUS_ERROR or (now - int(c["born"]) > 8000):
			_http_clients.remove_at(i)
			continue
		if st != StreamPeerTCP.STATUS_CONNECTED:
			continue

		var avail := peer.get_available_bytes()
		if avail > 0:
			var res := peer.get_partial_data(avail)
			if res[0] == OK:
				var chunk: PackedByteArray = res[1]
				c["buf"].append_array(chunk)

		var buf: PackedByteArray = c["buf"]
		var header_end := _find_header_end(buf)
		if header_end == -1:
			continue

		var header_str := buf.slice(0, header_end).get_string_from_utf8()
		var lines := header_str.split("\r\n")
		if lines.is_empty():
			_http_clients.remove_at(i)
			continue

		var req_parts := lines[0].split(" ")
		var method := req_parts[0] if req_parts.size() > 0 else "GET"
		var path := req_parts[1] if req_parts.size() > 1 else "/"

		var headers: Dictionary = {}
		for l_idx in range(1, lines.size()):
			var line := lines[l_idx]
			var colon := line.find(":")
			if colon != -1:
				var k := line.substr(0, colon).strip_edges().to_lower()
				var v := line.substr(colon + 1).strip_edges()
				headers[k] = v

		# Check WebSocket Upgrade
		if headers.get("upgrade", "").to_lower() == "websocket" and headers.has("sec-websocket-key"):
			var ws_key: String = headers["sec-websocket-key"]
			var accept := Marshalls.raw_to_base64((ws_key + WS_MAGIC).sha1_buffer())
			var hs := (
				"HTTP/1.1 101 Switching Protocols\r\n" +
				"Upgrade: websocket\r\n" +
				"Connection: Upgrade\r\n" +
				"Sec-WebSocket-Accept: %s\r\n\r\n" % accept
			)
			peer.put_data(hs.to_utf8_buffer())
			var leftover := buf.slice(header_end + 4)
			_ws_clients.append({
				"peer": peer,
				"buf": leftover,
				"ua": headers.get("user-agent", "iPhone 15")
			})
			_http_clients.remove_at(i)
			_on_ws_client_connected(headers.get("user-agent", ""))
			continue

		# Check POST /input fallback
		if method == "POST":
			var content_len := int(headers.get("content-length", "0"))
			var body_start := header_end + 4
			if buf.size() < body_start + content_len:
				continue
			var body_str := buf.slice(body_start, body_start + content_len).get_string_from_utf8()
			_handle_json_payload(body_str, null)
			var ok_resp := (
				"HTTP/1.1 200 OK\r\n" +
				"Content-Type: text/plain\r\n" +
				"Access-Control-Allow-Origin: *\r\n" +
				"Content-Length: 2\r\n" +
				"Connection: close\r\n\r\nok"
			)
			peer.put_data(ok_resp.to_utf8_buffer())
			_queue_close_peer(peer)
			_http_clients.remove_at(i)
			continue

		# Serve Font (/Nunito.ttf)
		if path.begins_with("/Nunito.ttf") and not _font_bytes.is_empty():
			var fh := (
				"HTTP/1.1 200 OK\r\n" +
				"Content-Type: font/ttf\r\n" +
				"Content-Length: %d\r\n" % _font_bytes.size() +
				"Cache-Control: public, max-age=86400\r\n" +
				"Connection: close\r\n\r\n"
			)
			peer.put_data(fh.to_utf8_buffer())
			peer.put_data(_font_bytes)
			_queue_close_peer(peer)
			_http_clients.remove_at(i)
			continue

		# Serve Controller Web App (GET /)
		var hh := (
			"HTTP/1.1 200 OK\r\n" +
			"Content-Type: text/html; charset=utf-8\r\n" +
			"Content-Length: %d\r\n" % _html_bytes.size() +
			"Cache-Control: no-store\r\n" +
			"Connection: close\r\n\r\n"
		)
		peer.put_data(hh.to_utf8_buffer())
		peer.put_data(_html_bytes)
		_queue_close_peer(peer)
		_http_clients.remove_at(i)


func _queue_close_peer(peer: StreamPeerTCP) -> void:
	_closing_clients.append({"peer": peer, "at": Time.get_ticks_msec()})


func _poll_closing_clients() -> void:
	var now := Time.get_ticks_msec()
	for i in range(_closing_clients.size() - 1, -1, -1):
		var item: Dictionary = _closing_clients[i]
		var peer: StreamPeerTCP = item["peer"]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or (now - int(item["at"]) >= 350):
			if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				peer.disconnect_from_host()
			_closing_clients.remove_at(i)


func _find_header_end(buf: PackedByteArray) -> int:
	var n := buf.size()
	if n < 4:
		return -1
	for i in range(n - 3):
		if buf[i] == 13 and buf[i + 1] == 10 and buf[i + 2] == 13 and buf[i + 3] == 10:
			return i
	return -1


func _poll_ws_clients() -> void:
	for i in range(_ws_clients.size() - 1, -1, -1):
		var c: Dictionary = _ws_clients[i]
		var peer: StreamPeerTCP = c["peer"]
		peer.poll()
		var st := peer.get_status()
		if st != StreamPeerTCP.STATUS_CONNECTED:
			_ws_clients.remove_at(i)
			_on_ws_client_disconnected()
			continue

		var avail := peer.get_available_bytes()
		if avail > 0:
			var res := peer.get_partial_data(avail)
			if res[0] == OK:
				var chunk: PackedByteArray = res[1]
				c["buf"].append_array(chunk)

		var closed := false
		while true:
			var frame := _try_parse_ws_frame(c["buf"])
			if frame.is_empty():
				break
			c["buf"] = frame["rest"]
			var opcode: int = frame["opcode"]
			var payload: PackedByteArray = frame["payload"]
			if opcode == 0x8:  # Close
				closed = true
				break
			elif opcode == 0x9:  # Ping -> send Pong
				_ws_send_frame(peer, 0xA, payload)
			elif opcode == 0x1:  # Text JSON
				_handle_json_payload(payload.get_string_from_utf8(), peer)

		if closed:
			peer.disconnect_from_host()
			_ws_clients.remove_at(i)
			_on_ws_client_disconnected()


func _try_parse_ws_frame(buf: PackedByteArray) -> Dictionary:
	var n := buf.size()
	if n < 2:
		return {}
	var b0: int = buf[0]
	var b1: int = buf[1]
	var opcode: int = b0 & 0x0F
	var masked: bool = (b1 & 0x80) != 0
	var payload_len: int = b1 & 0x7F
	var offset: int = 2

	if payload_len == 126:
		if n < 4:
			return {}
		payload_len = (int(buf[2]) << 8) | int(buf[3])
		offset = 4
	elif payload_len == 127:
		if n < 10:
			return {}
		payload_len = (int(buf[6]) << 24) | (int(buf[7]) << 16) | (int(buf[8]) << 8) | int(buf[9])
		offset = 10

	var mask_key := PackedByteArray()
	if masked:
		if n < offset + 4:
			return {}
		mask_key = buf.slice(offset, offset + 4)
		offset += 4

	if n < offset + payload_len:
		return {}

	var payload := buf.slice(offset, offset + payload_len)
	if masked:
		for j in range(payload_len):
			payload[j] = payload[j] ^ mask_key[j & 3]

	return {
		"opcode": opcode,
		"payload": payload,
		"rest": buf.slice(offset + payload_len)
	}


func _ws_send_frame(peer: StreamPeerTCP, opcode: int, payload: PackedByteArray) -> void:
	if peer == null or peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	var frame := PackedByteArray()
	frame.append(0x80 | (opcode & 0x0F))
	var length := payload.size()
	if length <= 125:
		frame.append(length)
	elif length <= 65535:
		frame.append(126)
		frame.append((length >> 8) & 0xFF)
		frame.append(length & 0xFF)
	else:
		return
	frame.append_array(payload)
	peer.put_data(frame)


func _ws_send_text(peer: StreamPeerTCP, text: String) -> void:
	_ws_send_frame(peer, 0x1, text.to_utf8_buffer())


func _broadcast_ws_text(text: String) -> void:
	var payload := text.to_utf8_buffer()
	for c in _ws_clients:
		var peer: StreamPeerTCP = c["peer"]
		_ws_send_frame(peer, 0x1, payload)


func _on_ws_client_connected(ua: String) -> void:
	is_connected = true
	if not use_phone_controller:
		use_phone_controller = true
		mode_changed.emit(true)
	if ua.contains("iPhone"):
		client_device_name = "iPhone 15"
	elif ua.contains("iPad"):
		client_device_name = "iPad"
	elif ua.contains("Android"):
		client_device_name = "Phone"
	else:
		client_device_name = "iPhone Controller"
	AudioDirector.play_sfx("checkpoint", -3.0, 1.18)
	connection_changed.emit(true, _ws_clients.size(), client_device_name)
	_broadcast_telemetry()


func _on_ws_client_disconnected() -> void:
	if _ws_clients.is_empty():
		is_connected = false
		_move_vec = Vector2.ZERO
		_look_stick = Vector2.ZERO
		_look_delta = Vector2.ZERO
		_sprint_held = false
		_jump_held = false
		_dash_held = false
		_slide_held = false
		_rewind_held = false
		connection_changed.emit(false, 0, client_device_name)


func _handle_json_payload(json_str: String, peer: StreamPeerTCP) -> void:
	var parsed = JSON.parse_string(json_str)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var msg: Dictionary = parsed
	var t: String = str(msg.get("t", ""))

	if t == "ping":
		if peer:
			_ws_send_text(peer, "{\"t\":\"pong\"}")
		return

	if t == "hello":
		var ua := str(msg.get("ua", ""))
		if ua.contains("iPhone"):
			client_device_name = "iPhone 15"
		_broadcast_telemetry()
		return

	if t == "state":
		# If HTTP fallback used, also mark connected
		if not is_connected:
			is_connected = true
			if not use_phone_controller:
				use_phone_controller = true
				mode_changed.emit(true)
			connection_changed.emit(true, 1, client_device_name)

		_move_vec = Vector2(
			clampf(float(msg.get("mx", 0.0)), -1.0, 1.0),
			clampf(float(msg.get("my", 0.0)), -1.0, 1.0)
		)
		_look_stick = Vector2(
			clampf(float(msg.get("cx", 0.0)), -1.0, 1.0),
			clampf(float(msg.get("cy", 0.0)), -1.0, 1.0)
		)
		_look_delta.x += float(msg.get("ldx", 0.0))
		_look_delta.y += float(msg.get("ldy", 0.0))
		_sprint_held = int(msg.get("sp", 0)) != 0

		var new_jp := int(msg.get("jp", 0)) != 0
		var new_da := int(msg.get("da", 0)) != 0
		var new_sl := int(msg.get("sl", 0)) != 0
		var new_rw := int(msg.get("rw", 0)) != 0

		var ev := str(msg.get("ev", ""))
		if (new_jp and not _jump_held) or ev == "jump_down":
			_jump_just_pressed_latch = true
		if (new_da and not _dash_held) or ev == "dash_down":
			_dash_just_pressed_latch = true
		if (new_sl and not _slide_held) or ev == "slide_down":
			_slide_just_pressed_latch = true
		if (new_rw and not _rewind_held) or ev == "rewind_down":
			_rewind_just_pressed_latch = true

		_jump_held = new_jp
		_dash_held = new_da
		_slide_held = new_sl
		_rewind_held = new_rw
		return

	if t == "cmd":
		var cmd := str(msg.get("cmd", ""))
		var arg = msg.get("arg", null)
		match cmd:
			"select_character":
				var cid := str(arg)
				if GameState.CHARACTERS.has(cid):
					GameState.set_character(cid)
					AudioDirector.play_sfx("ui_click", -2.0, 1.1)
					_broadcast_telemetry()
			"begin_ascent":
				remote_begin_ascent.emit()
			"toggle_pause":
				remote_toggle_pause.emit()
			"resume":
				remote_resume.emit()
			"restart_climb":
				remote_restart_climb.emit()
			"teleport_world":
				remote_teleport_world.emit(int(arg))


func _broadcast_telemetry() -> void:
	if _ws_clients.is_empty():
		return
	var mode_str := "title"
	if GameState.is_playing:
		mode_str = "paused" if GameState.is_paused else "playing"
	var w_idx := clampi(GameState.current_world_idx, 0, GameState.WORLDS.size() - 1)
	var w_name: String = GameState.WORLDS[w_idx]["name"]
	var payload := {
		"t": "telemetry",
		"mode": mode_str,
		"char": GameState.selected_character,
		"alt": snappedf(GameState.current_altitude, 0.1),
		"world": w_idx,
		"wname": w_name,
		"time": GameState.format_time(GameState.run_time),
		"shards": GameState.collected_shards.size(),
		"falls": GameState.total_falls,
		"flow": snappedf(GameState.current_flow, 0.01),
		"streak": GameState.current_streak,
		"orb": _orb_locked
	}
	_broadcast_ws_text(JSON.stringify(payload))
