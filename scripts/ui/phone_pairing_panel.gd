extends PanelContainer
class_name PhonePairingPanel
## Tactile Warm-Walnut QR Code Pairing & Live Telemetry Status Card for iPhone 15 DualSense Web Controller.
## Supports both Local Wi-Fi (<2ms LAN) and 1-Click Global Internet / 5G Tunnel (Cloudflare HTTPS).

const QRGen = preload("res://scripts/ui/qr_code_generator.gd")

var _qr_tex_rect: TextureRect
var _status_badge: PanelContainer
var _status_label: Label
var _url_label: Label
var _lan_btn: Button
var _net_btn: Button
var _sub_label: Label
var _compact_mode: bool = false


func _init(compact: bool = false) -> void:
	_compact_mode = compact


func _ready() -> void:
	var pad_x := 16 if _compact_mode else 20
	var pad_y := 12 if _compact_mode else 16
	add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.08, 0.065, 0.08, 0.92),
		Color(0.98, 0.78, 0.34, 0.42),
		20, pad_x, pad_y, 1
	))
	_build_content()
	PhoneController.connection_changed.connect(_on_connection_changed)
	PhoneController.url_changed.connect(_on_url_changed)
	_refresh_qr_and_status()


func _build_content() -> void:
	var root_v := VBoxContainer.new()
	root_v.alignment = BoxContainer.ALIGNMENT_CENTER
	root_v.add_theme_constant_override("separation", 8 if _compact_mode else 10)
	add_child(root_v)

	# Header Row: Title + Live Connection Pill
	var head_row := HBoxContainer.new()
	head_row.alignment = BoxContainer.ALIGNMENT_CENTER
	head_row.add_theme_constant_override("separation", 8)
	root_v.add_child(head_row)

	var title_lbl := Label.new()
	title_lbl.text = "iPhone 15 DualSense Deck"
	UITheme.apply_font(title_lbl, "extrabold", 14 if _compact_mode else 15, UITheme.INK_PRIMARY)
	head_row.add_child(title_lbl)

	# Live Connection Badge
	_status_badge = PanelContainer.new()
	_status_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_v.add_child(_status_badge)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_badge.add_child(_status_label)

	# QR Code Ivory Frame
	var qr_center := CenterContainer.new()
	root_v.add_child(qr_center)

	var qr_frame := PanelContainer.new()
	var frame_sb := StyleBoxFlat.new()
	frame_sb.bg_color = Color(0.99, 0.97, 0.93, 1.0)
	frame_sb.border_color = Color(0.86, 0.78, 0.64, 1.0)
	frame_sb.set_border_width_all(2)
	frame_sb.set_corner_radius_all(14)
	frame_sb.content_margin_left = 8
	frame_sb.content_margin_right = 8
	frame_sb.content_margin_top = 8
	frame_sb.content_margin_bottom = 8
	frame_sb.shadow_color = Color(0.03, 0.02, 0.04, 0.36)
	frame_sb.shadow_size = 10
	frame_sb.shadow_offset = Vector2(0, 3)
	qr_frame.add_theme_stylebox_override("panel", frame_sb)
	qr_center.add_child(qr_frame)

	_qr_tex_rect = TextureRect.new()
	var qr_px := 136 if _compact_mode else 164
	_qr_tex_rect.custom_minimum_size = Vector2(qr_px, qr_px)
	_qr_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_qr_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_qr_tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	qr_frame.add_child(_qr_tex_rect)

	# Instruction Caption
	_sub_label = Label.new()
	_sub_label.text = "Rotate iPhone horizontally & scan with Camera"
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_font(_sub_label, "semibold", 11 if _compact_mode else 12, UITheme.INK_SECONDARY)
	root_v.add_child(_sub_label)

	# Network Mode Toggle: Local Wi-Fi (1.5ms) vs Internet / 5G Tunnel
	var net_row := HBoxContainer.new()
	net_row.alignment = BoxContainer.ALIGNMENT_CENTER
	net_row.add_theme_constant_override("separation", 6)
	root_v.add_child(net_row)

	_lan_btn = Button.new()
	_lan_btn.text = "Local Wi-Fi (2ms)"
	_lan_btn.custom_minimum_size = Vector2(118, 30)
	_lan_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -3.0, 1.05)
		PhoneController.set_network_mode(false)
		_refresh_qr_and_status()
	)
	net_row.add_child(_lan_btn)

	_net_btn = Button.new()
	_net_btn.text = "Internet / 5G"
	_net_btn.custom_minimum_size = Vector2(112, 30)
	_net_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -3.0, 1.15)
		PhoneController.set_network_mode(true)
		_refresh_qr_and_status()
	)
	net_row.add_child(_net_btn)

	# Live URL Readout
	_url_label = Label.new()
	_url_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_url_label, "bold", 11, UITheme.ACCENT_AMBER)
	root_v.add_child(_url_label)


func _on_connection_changed(_connected: bool, _count: int, _device: String) -> void:
	_refresh_qr_and_status()


func _on_url_changed(_url: String, _is_tunnel: bool) -> void:
	_refresh_qr_and_status()


func _refresh_qr_and_status() -> void:
	if _qr_tex_rect == null:
		return
	var active_url := PhoneController.get_active_url()
	_qr_tex_rect.texture = QRGen.generate_texture(active_url, 6, 3)

	if PhoneController.use_tunnel_mode and PhoneController.tunnel_starting and PhoneController.tunnel_url.is_empty():
		_url_label.text = "Opening 5G HTTPS Tunnel…"
	else:
		_url_label.text = active_url.replace("https://", "").replace("http://", "")

	UITheme.style_secondary_pill(_lan_btn, not PhoneController.use_tunnel_mode, 11)
	UITheme.style_secondary_pill(_net_btn, PhoneController.use_tunnel_mode, 11)

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(999)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4

	if PhoneController.is_connected:
		sb.bg_color = Color(0.14, 0.42, 0.26, 0.92)
		sb.border_color = Color(0.38, 0.95, 0.62, 0.9)
		sb.set_border_width_all(1)
		_status_badge.add_theme_stylebox_override("panel", sb)
		_status_label.text = "● %s Connected · Live" % PhoneController.client_device_name
		UITheme.apply_font(_status_label, "extrabold", 11, Color(0.75, 1.0, 0.86))
		_sub_label.text = "DualSense Web Deck active — Keyboard bypassed"
	else:
		sb.bg_color = Color(0.20, 0.15, 0.08, 0.88)
		sb.border_color = Color(0.98, 0.74, 0.24, 0.55)
		sb.set_border_width_all(1)
		_status_badge.add_theme_stylebox_override("panel", sb)
		_status_label.text = "● Waiting for iPhone Scan…"
		UITheme.apply_font(_status_label, "bold", 11, UITheme.ACCENT_AMBER)
		_sub_label.text = "Rotate iPhone horizontally & scan with Camera"
