extends RoomSetup

const AMB_PUEBLO := preload("res://assets/audio/ambience/ambiente_pueblo.ogg")
const AMB_BOSQUE := preload("res://assets/audio/ambience/ambiente_bosque.ogg")
const STEPS_DIRT := preload("res://assets/audio/sfx/pasos_tierra.ogg")

# World-x thresholds across the shortened exterior (~4397 wide).
const BOSQUE_X := 1800.0
const ROOM_WIDTH := 4397.0

var _player: Node2D
var _last_zone := ""

func _on_room_ready() -> void:
	AudioManager.start_music()
	AudioManager.set_ambient(AMB_PUEBLO)
	_last_zone = "pueblo"
	_player = get_tree().get_first_node_in_group("player")
	if _player and _player.has_method("apply_camera_limits"):
		_player.apply_camera_limits(0, 0, int(ROOM_WIDTH), 1080)
	if _player and _player.has_method("set_footstep_stream"):
		_player.set_footstep_stream(STEPS_DIRT)
	_sync_pescador()

func _sync_pescador() -> void:
	var pescador := get_node_or_null("Pescador")
	if pescador == null:
		return
	# After the expose, the fisherman waits by the river in room_4.
	if StoryFlags.is_bartender_expuesto() or StoryFlags.caso_resuelto:
		pescador.visible = false
		pescador.monitoring = false
		pescador.monitorable = false
		pescador.input_pickable = false

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

func _zone_for_x(x: float) -> String:
	if x < BOSQUE_X:
		return "pueblo"
	return "bosque"

func _exit_tree() -> void:
	AudioManager.stop_music()
