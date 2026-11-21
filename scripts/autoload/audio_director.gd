extends Node
## Adaptive vertical soundtrack, layered biome ambience, falling wind rush & tactile SFX manager.
## Crossfades smoothly across 6 biome harmonic themes & ambience beds by altitude and swells Flow dynamically.

const BIOME_TRACKS := ["world1", "world2", "world3", "world4", "world5", "world6"]
const PENTATONIC_RATIOS := [1.0, 1.12246, 1.25992, 1.49831, 1.68179, 2.0, 2.24492, 2.51984]

var _base_players: Array[AudioStreamPlayer] = []
var _flow_players: Array[AudioStreamPlayer] = []
var _amb_players: Array[AudioStreamPlayer] = []
var _fall_wind_player: AudioStreamPlayer = null
var _summit_swell_player: AudioStreamPlayer = null
var _music_lpf: AudioEffectLowPassFilter = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _sfx_idx: int = 0

var _target_biome: int = 0
var _biome_weights: Array[float] = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _flow_level: float = 0.0
var _fall_wind_target: float = 0.0
var _fall_wind_current: float = 0.0
var _summit_swell_weight: float = 0.0
var _last_chirp_msec: int = -1000
var _music_ready: bool = false
var _music_mix_gain: float = 1.0
var _target_music_gain: float = 1.0
var _ambience_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_music_bus_filter()
	_preload_sfx()
	_setup_music_stems()
	_setup_ambience()
	GameState.world_entered.connect(func(idx: int, _n: String, _s: String) -> void: _target_biome = clampi(idx, 0, 5))
	GameState.flow_changed.connect(func(fv: float, _st: int) -> void: _flow_level = fv)


func _setup_music_bus_filter() -> void:
	var bus_idx: int = AudioServer.get_bus_index(&"Music")
	if bus_idx < 0:
		return
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var eff: AudioEffect = AudioServer.get_bus_effect(bus_idx, i)
		if eff is AudioEffectLowPassFilter:
			_music_lpf = eff as AudioEffectLowPassFilter
			break
	if _music_lpf == null:
		_music_lpf = AudioEffectLowPassFilter.new()
		_music_lpf.cutoff_hz = 18500.0
		_music_lpf.resonance = 0.5
		AudioServer.add_bus_effect(bus_idx, _music_lpf)
	else:
		_music_lpf.cutoff_hz = 18500.0


func _load_audio_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is AudioStream:
			return res as AudioStream
	if FileAccess.file_exists(path):
		return AudioStreamWAV.load_from_file(path)
	return null


func _configure_wav_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		var sample_cnt: int = int(round(wav.get_length() * float(wav.mix_rate)))
		if sample_cnt <= 0:
			sample_cnt = int(floor(float(wav.data.size()) / (4.0 if wav.stereo else 2.0)))
		wav.loop_end = sample_cnt


func _preload_sfx() -> void:
	for i in range(20):
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_pool.append(p)

	var names: Array[String] = [
		"jump", "double_jump", "dash", "step_stone", "step_brass", "step_paper",
		"step_crystal", "land_thud", "slide", "wall_kick", "bell_ring", "flow_chime",
		"bounce", "crystal_crack", "crystal_shatter", "portal_warp", "tether_zip",
		"checkpoint", "sun_shard", "rewind", "ui_click", "summit_fanfare",
		"chirp_pip_hop", "chirp_pip_joy", "chirp_koko_hop", "chirp_koko_joy",
		"chirp_vesper_hop", "chirp_vesper_joy",
		"firework_pop", "medal_chime", "shortcut_fanfare", "heart_drop"
	]
	for sname in names:
		var path := "res://assets/audio/sfx/%s.wav" % sname
		var stream := _load_audio_stream(path)
		if stream != null:
			_sfx_cache[sname] = stream


func _setup_music_stems() -> void:
	for i in range(BIOME_TRACKS.size()):
		var tname: String = BIOME_TRACKS[i]
		var bp := AudioStreamPlayer.new()
		bp.bus = &"Music"
		bp.volume_db = -60.0
		var bpath := "res://assets/audio/music/%s_base.wav" % tname
		var bstream := _load_audio_stream(bpath)
		if bstream != null:
			_configure_wav_loop(bstream)
			bp.stream = bstream
		add_child(bp)
		_base_players.append(bp)

		var fp := AudioStreamPlayer.new()
		fp.bus = &"Music"
		fp.volume_db = -60.0
		var fpath := "res://assets/audio/music/%s_flow.wav" % tname
		var fstream := _load_audio_stream(fpath)
		if fstream != null:
			_configure_wav_loop(fstream)
			fp.stream = fstream
		add_child(fp)
		_flow_players.append(fp)

	_summit_swell_player = AudioStreamPlayer.new()
	_summit_swell_player.bus = &"Music"
	_summit_swell_player.volume_db = -80.0
	var sstream := _load_audio_stream("res://assets/audio/music/summit_swell.wav")
	if sstream != null:
		_configure_wav_loop(sstream)
		_summit_swell_player.stream = sstream
	add_child(_summit_swell_player)

	_music_ready = true
	for i in range(_base_players.size()):
		if _base_players[i].stream != null:
			_base_players[i].play()
		if _flow_players[i].stream != null:
			_flow_players[i].play()
	if _summit_swell_player.stream != null:
		_summit_swell_player.play()


func _setup_ambience() -> void:
	for i in range(BIOME_TRACKS.size()):
		var tname: String = BIOME_TRACKS[i]
		var ap := AudioStreamPlayer.new()
		ap.bus = &"Ambience"
		ap.volume_db = -80.0
		var apath := "res://assets/audio/ambience/amb_%s.wav" % tname
		var astream := _load_audio_stream(apath)
		if astream != null:
			_configure_wav_loop(astream)
			ap.stream = astream
		add_child(ap)
		_amb_players.append(ap)

	_fall_wind_player = AudioStreamPlayer.new()
	_fall_wind_player.bus = &"Ambience"
	_fall_wind_player.volume_db = -80.0
	var wstream := _load_audio_stream("res://assets/audio/ambience/amb_fall_wind.wav")
	if wstream != null:
		_configure_wav_loop(wstream)
		_fall_wind_player.stream = wstream
	add_child(_fall_wind_player)

	for ap in _amb_players:
		if ap.stream != null:
			ap.play()
	if _fall_wind_player != null and _fall_wind_player.stream != null:
		_fall_wind_player.play()


func _exit_tree() -> void:
	_music_ready = false
	if _ambience_tween and _ambience_tween.is_valid():
		_ambience_tween.kill()
	_ambience_tween = null
	for p in _base_players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	for p in _flow_players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	for p in _amb_players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	if _fall_wind_player != null and is_instance_valid(_fall_wind_player):
		_fall_wind_player.stop()
		_fall_wind_player.stream = null
	_fall_wind_player = null
	if _summit_swell_player != null and is_instance_valid(_summit_swell_player):
		_summit_swell_player.stop()
		_summit_swell_player.stream = null
	_summit_swell_player = null
	_music_lpf = null
	for p in _sfx_pool:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	_base_players.clear()
	_flow_players.clear()
	_amb_players.clear()
	_sfx_pool.clear()
	_sfx_cache.clear()


func _process(delta: float) -> void:
	if not _music_ready:
		return
	_music_mix_gain = lerpf(_music_mix_gain, _target_music_gain, clampf(delta * 1.5, 0.0, 1.0))
	var pause_scale: float = 0.45 if GameState.is_paused else 1.0
	var master_scale: float = GameState.music_volume * _music_mix_gain * pause_scale
	var amb_master_scale: float = GameState.sfx_volume * (0.50 if GameState.is_paused else 1.0)

	for i in range(BIOME_TRACKS.size()):
		var desired: float = 1.0 if i == _target_biome else 0.0
		_biome_weights[i] = lerpf(_biome_weights[i], desired, clampf(delta * 1.4, 0.0, 1.0))
		var w: float = _biome_weights[i] * master_scale
		if w < 0.004:
			_base_players[i].volume_db = -80.0
			_flow_players[i].volume_db = -80.0
		else:
			_base_players[i].volume_db = linear_to_db(w * 0.72)
			var flow_mix: float = w * smoothstep(0.12, 0.85, _flow_level) * 0.78
			_flow_players[i].volume_db = linear_to_db(maxf(flow_mix, 0.0001))

		if i < _amb_players.size() and is_instance_valid(_amb_players[i]):
			var aw: float = _biome_weights[i] * amb_master_scale
			if aw < 0.004:
				_amb_players[i].volume_db = -80.0
			else:
				_amb_players[i].volume_db = linear_to_db(aw * 0.78)

	if _fall_wind_player != null and is_instance_valid(_fall_wind_player):
		var desired_wind: float = 0.0 if GameState.is_paused else _fall_wind_target
		var wind_rate: float = 6.0 if desired_wind > _fall_wind_current else 8.5
		_fall_wind_current = lerpf(_fall_wind_current, desired_wind, clampf(delta * wind_rate, 0.0, 1.0))
		var wind_gain: float = _fall_wind_current * GameState.sfx_volume
		if wind_gain < 0.004:
			_fall_wind_player.volume_db = -80.0
		else:
			_fall_wind_player.volume_db = linear_to_db(wind_gain * 0.92)
			_fall_wind_player.pitch_scale = lerpf(0.88, 1.24, _fall_wind_current)

	# Living Score 1 — Breathless Falls: muffle Music low-pass down to 720 Hz during fast plunge, snap back at delta*14.0 on landing/Clutch Save
	if _music_lpf != null:
		var target_cutoff: float = 18500.0 if _fall_wind_target <= 0.01 else lerpf(18500.0, 720.0, clampf(_fall_wind_current, 0.0, 1.0))
		var lpf_rate: float = 14.0 if _fall_wind_target <= 0.01 else 7.5
		_music_lpf.cutoff_hz = lerpf(_music_lpf.cutoff_hz, target_cutoff, clampf(delta * lpf_rate, 0.0, 1.0))

	# Living Score 2 — Summit Swell: fade in soaring golden celestial choir + strings from 960.0m to 1,075.0m (and keep glowing at Summit)
	if _summit_swell_player != null and is_instance_valid(_summit_swell_player):
		var swell_target: float = smoothstep(960.0, 1075.0, GameState.current_altitude)
		if GameState.summit_reached:
			swell_target = 1.0
		_summit_swell_weight = lerpf(_summit_swell_weight, swell_target, clampf(delta * 1.8, 0.0, 1.0))
		var sw_gain: float = _summit_swell_weight * master_scale
		if sw_gain < 0.004:
			_summit_swell_player.volume_db = -80.0
		else:
			_summit_swell_player.volume_db = linear_to_db(sw_gain * 0.68)


func set_biome_immediate(world_idx: int) -> void:
	_target_biome = clampi(world_idx, 0, 5)
	for i in range(BIOME_TRACKS.size()):
		_biome_weights[i] = 1.0 if i == _target_biome else 0.0


func set_fall_wind_intensity(intensity: float) -> void:
	_fall_wind_target = clampf(intensity, 0.0, 1.0)


func play_loading_ambience() -> void:
	## Gently fades in soft World 1 musical base stem & spaced distant pentatonic chimes.
	set_biome_immediate(0)
	_flow_level = 0.0
	_music_mix_gain = 0.0
	_target_music_gain = 0.42
	if _ambience_tween and _ambience_tween.is_valid():
		_ambience_tween.kill()
	_ambience_tween = create_tween()
	_ambience_tween.tween_interval(0.55)
	_ambience_tween.tween_callback(func() -> void: play_flow_chime(0, -11.5))
	_ambience_tween.tween_interval(1.25)
	_ambience_tween.tween_callback(func() -> void: play_flow_chime(2, -10.5))
	_ambience_tween.tween_interval(1.30)
	_ambience_tween.tween_callback(func() -> void: play_flow_chime(4, -9.8))


func swell_into_cutscene() -> void:
	## Smoothly swells music from soft loading ambience to full lush cutscene volume.
	if _ambience_tween and _ambience_tween.is_valid():
		_ambience_tween.kill()
	_ambience_tween = null
	_target_music_gain = 1.0
	play_flow_chime(5, -7.5)


func set_music_volume(val: float, persist: bool = true) -> void:
	GameState.music_volume = clampf(val, 0.0, 1.0)
	if persist:
		GameState.save_persistent_data()


func set_sfx_volume(val: float, persist: bool = true) -> void:
	GameState.sfx_volume = clampf(val, 0.0, 1.0)
	if persist:
		GameState.save_persistent_data()


func play_sfx(sname: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if _sfx_pool.is_empty() or not _sfx_cache.has(sname):
		return
	if GameState.sfx_volume <= 0.01:
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
	if not is_instance_valid(p):
		return
	p.stream = _sfx_cache[sname]
	p.volume_db = volume_db + linear_to_db(maxf(GameState.sfx_volume, 0.001))
	p.pitch_scale = clampf(pitch, 0.4, 2.8)
	p.play()


func play_character_chirp(char_id: String, kind: String = "hop") -> void:
	var norm_kind: String = "joy" if kind == "joy" else "hop"
	var min_cooldown_ms: int = 120 if norm_kind == "joy" else 240
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_chirp_msec < min_cooldown_ms:
		return
	var cid: String = char_id.to_lower()
	var sname: String = "chirp_%s_%s" % [cid, norm_kind]
	if not _sfx_cache.has(sname):
		sname = "chirp_pip_%s" % norm_kind
	if not _sfx_cache.has(sname):
		return
	_last_chirp_msec = now_ms
	var vol_db: float = -4.0 if norm_kind == "joy" else -7.5
	play_sfx(sname, vol_db, randf_range(0.95, 1.07))


func play_flow_chime(streak_step: int, volume_db: float = -3.5) -> void:
	var idx := clampi(streak_step, 0, PENTATONIC_RATIOS.size() - 1)
	play_sfx("flow_chime", volume_db, PENTATONIC_RATIOS[idx])


func play_bell_ring(pitch_step: int = 0) -> void:
	var idx := clampi(pitch_step % PENTATONIC_RATIOS.size(), 0, PENTATONIC_RATIOS.size() - 1)
	play_sfx("bell_ring", -1.5, PENTATONIC_RATIOS[idx] * 0.85)


func play_footstep(world_idx: int) -> void:
	var pitch := randf_range(0.92, 1.08)
	match world_idx:
		1:
			play_sfx("step_brass", -9.0, pitch)
		2:
			play_sfx("step_paper", -8.0, pitch)
		3:
			play_sfx("step_crystal", -10.0, pitch)
		_:
			play_sfx("step_stone", -8.5, pitch)
