extends Node
## Adaptive vertical soundtrack & tactile SFX manager.
## Crossfades smoothly across 6 biome harmonic themes by altitude and swells the Flow stem dynamically.

const BIOME_TRACKS := ["world1", "world2", "world3", "world4", "world5", "world6"]
const PENTATONIC_RATIOS := [1.0, 1.12246, 1.25992, 1.49831, 1.68179, 2.0, 2.24492, 2.51984]

var _base_players: Array[AudioStreamPlayer] = []
var _flow_players: Array[AudioStreamPlayer] = []
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _sfx_idx: int = 0

var _target_biome: int = 0
var _biome_weights: Array[float] = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _flow_level: float = 0.0
var _music_ready: bool = false
var _music_mix_gain: float = 1.0
var _target_music_gain: float = 1.0
var _ambience_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preload_sfx()
	_setup_music_stems()
	GameState.world_entered.connect(func(idx: int, _n: String, _s: String): _target_biome = clampi(idx, 0, 5))
	GameState.flow_changed.connect(func(fv: float, _st: int): _flow_level = fv)


func _preload_sfx() -> void:
	for i in range(16):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	var names := [
		"jump", "double_jump", "dash", "step_stone", "step_brass", "step_paper",
		"step_crystal", "land_thud", "slide", "wall_kick", "bell_ring", "flow_chime",
		"bounce", "crystal_crack", "crystal_shatter", "portal_warp", "tether_zip",
		"checkpoint", "sun_shard", "rewind", "ui_click", "summit_fanfare"
	]
	for sname in names:
		var path := "res://assets/audio/sfx/%s.wav" % sname
		if ResourceLoader.exists(path):
			_sfx_cache[sname] = load(path)


func _setup_music_stems() -> void:
	for i in range(BIOME_TRACKS.size()):
		var tname: String = BIOME_TRACKS[i]
		var bp := AudioStreamPlayer.new()
		bp.bus = "Music"
		bp.volume_db = -60.0
		var bpath := "res://assets/audio/music/%s_base.wav" % tname
		if ResourceLoader.exists(bpath):
			var stream = load(bpath)
			if stream is AudioStreamWAV:
				var wav := stream as AudioStreamWAV
				wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				wav.loop_begin = 0
				var sample_cnt: int = int(floor(float(wav.data.size()) / (4.0 if wav.stereo else 2.0)))
				wav.loop_end = sample_cnt
			bp.stream = stream
		add_child(bp)
		_base_players.append(bp)

		var fp := AudioStreamPlayer.new()
		fp.bus = "Music"
		fp.volume_db = -60.0
		var fpath := "res://assets/audio/music/%s_flow.wav" % tname
		if ResourceLoader.exists(fpath):
			var fstream = load(fpath)
			if fstream is AudioStreamWAV:
				var fwav := fstream as AudioStreamWAV
				fwav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				fwav.loop_begin = 0
				var fsample_cnt: int = int(floor(float(fwav.data.size()) / (4.0 if fwav.stereo else 2.0)))
				fwav.loop_end = fsample_cnt
			fp.stream = fstream
		add_child(fp)
		_flow_players.append(fp)

	_music_ready = true
	for i in range(_base_players.size()):
		if _base_players[i].stream:
			_base_players[i].play()
		if _flow_players[i].stream:
			_flow_players[i].play()


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
	for p in _sfx_pool:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	_base_players.clear()
	_flow_players.clear()
	_sfx_pool.clear()
	_sfx_cache.clear()


func _process(delta: float) -> void:
	if not _music_ready:
		return
	_music_mix_gain = lerpf(_music_mix_gain, _target_music_gain, clampf(delta * 1.5, 0.0, 1.0))
	var master_scale := GameState.music_volume * _music_mix_gain * (0.45 if GameState.is_paused else 1.0)
	for i in range(BIOME_TRACKS.size()):
		var desired := 1.0 if i == _target_biome else 0.0
		_biome_weights[i] = lerpf(_biome_weights[i], desired, clampf(delta * 1.4, 0.0, 1.0))
		var w := _biome_weights[i] * master_scale
		if w < 0.004:
			_base_players[i].volume_db = -80.0
			_flow_players[i].volume_db = -80.0
		else:
			_base_players[i].volume_db = linear_to_db(w * 0.72)
			var flow_mix := w * smoothstep(0.12, 0.85, _flow_level) * 0.78
			_flow_players[i].volume_db = linear_to_db(maxf(flow_mix, 0.0001))


func set_biome_immediate(world_idx: int) -> void:
	_target_biome = clampi(world_idx, 0, 5)
	for i in range(BIOME_TRACKS.size()):
		_biome_weights[i] = 1.0 if i == _target_biome else 0.0


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
	_ambience_tween.tween_callback(func(): play_flow_chime(0, -11.5))
	_ambience_tween.tween_interval(1.25)
	_ambience_tween.tween_callback(func(): play_flow_chime(2, -10.5))
	_ambience_tween.tween_interval(1.30)
	_ambience_tween.tween_callback(func(): play_flow_chime(4, -9.8))


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
	if not _sfx_cache.has(sname):
		return
	if GameState.sfx_volume <= 0.01:
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
	p.stream = _sfx_cache[sname]
	p.volume_db = volume_db + linear_to_db(maxf(GameState.sfx_volume, 0.001))
	p.pitch_scale = clampf(pitch, 0.4, 2.8)
	p.play()


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
