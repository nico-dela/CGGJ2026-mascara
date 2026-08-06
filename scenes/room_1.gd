extends RoomSetup

const AMB_PUEBLO := preload("res://audios/AMBIENTES Y SFX/AMBIENTES/ambientePueblo.ogg")
const AMB_BOSQUE := preload("res://audios/AMBIENTES Y SFX/AMBIENTES/ambienteBosque.ogg")
const AMB_RIO := preload("res://audios/AMBIENTES Y SFX/AMBIENTES/ambienteRio.ogg")
const STEPS_DIRT := preload("res://audios/AMBIENTES Y SFX/FOLEYS FINALES/pasosTierra.ogg")

# World-x thresholds across the panoramic exterior (~6123 wide).
const BOSQUE_X := 1800.0
const RIO_X := 4200.0

var _player: Node2D
var _last_zone := ""

func _on_room_ready() -> void:
	AudioManager.start_music()
	AudioManager.set_ambient(AMB_PUEBLO)
	_last_zone = "pueblo"
	_player = get_tree().get_first_node_in_group("player")
	if _player and _player.has_method("apply_camera_limits"):
		_player.apply_camera_limits(0, 0, 6123, 1080)
	if _player and _player.has_method("set_footstep_stream"):
		_player.set_footstep_stream(STEPS_DIRT)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	var zone := _zone_for_x(_player.global_position.x)
	if zone == _last_zone:
		return
	_last_zone = zone
	match zone:
		"pueblo":
			AudioManager.set_ambient(AMB_PUEBLO)
		"bosque":
			AudioManager.set_ambient(AMB_BOSQUE)
		"rio":
			AudioManager.set_ambient(AMB_RIO)

func _zone_for_x(x: float) -> String:
	if x < BOSQUE_X:
		return "pueblo"
	if x < RIO_X:
		return "bosque"
	return "rio"

func _exit_tree() -> void:
	AudioManager.stop_music()
