extends Node3D
class_name TetherOrb
## World 5 & 6 Grapple Spirit Orb - locks on smoothly when aimed at and slingshots the player skyward!

var _ring1: Node3D
var _ring2: Node3D
var _pulse: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	add_to_group("tether_orb")
	var path := "res://assets/models/common/tether_orb.glb"
	if ResourceLoader.exists(path):
		var inst: Node3D = load(path).instantiate()
		add_child(inst)
		_ring1 = inst.find_child("OrbRing1", true, false) as Node3D
		_ring2 = inst.find_child("OrbRing2", true, false) as Node3D

	var light := OmniLight3D.new()
	light.light_color = Color(0.48, 0.90, 1.0)
	light.light_energy = 2.0
	light.omni_range = 8.0
	add_child(light)


func pulse_activate() -> void:
	_pulse = 1.0


func _process(delta: float) -> void:
	_t += delta
	if _ring1:
		_ring1.rotation.y += delta * (1.8 + _pulse * 8.0)
	if _ring2:
		_ring2.rotation.x += delta * (1.4 + _pulse * 6.0)
		_ring2.rotation.z -= delta * 1.1
	if _pulse > 0.001:
		_pulse = maxf(0.0, _pulse - delta * 2.8)
	var s := 1.0 + _pulse * 0.45 + sin(_t * 3.0) * 0.05
	scale = Vector3(s, s, s)
