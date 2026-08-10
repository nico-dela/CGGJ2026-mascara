extends RoomSetup

## River / ivy stretch split from the old panoramic exterior.

const AMB_RIO := preload("res://assets/audio/ambience/ambiente_rio.ogg")
const AMB_BOSQUE := preload("res://assets/audio/ambience/ambiente_bosque.ogg")
const STEPS_DIRT := preload("res://assets/audio/sfx/pasos_tierra.ogg")
const ROOM_WIDTH := 2224.0

func _on_room_ready() -> void:
	AudioManager.start_music()
	if StoryFlags.is_paso_abierto():
		AudioManager.set_ambient(AMB_RIO)
	else:
		AudioManager.set_ambient(AMB_BOSQUE)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_camera_limits"):
		player.apply_camera_limits(0, 0, int(ROOM_WIDTH), 1080)
	if player and player.has_method("set_footstep_stream"):
		player.set_footstep_stream(STEPS_DIRT)
	_sync_pescador()
	if StoryFlags and not StoryFlags.paso_abierto_signal.is_connected(_on_paso_abierto):
		StoryFlags.paso_abierto_signal.connect(_on_paso_abierto)

func _sync_pescador() -> void:
	var pescador := get_node_or_null("Pescador")
	if pescador == null:
		return
	var show_river := StoryFlags.is_bartender_expuesto() or StoryFlags.caso_resuelto
	pescador.visible = show_river
	pescador.monitoring = show_river
	pescador.monitorable = show_river
	pescador.input_pickable = show_river
	if show_river and pescador.has_method("_aplicar_estado_rio"):
		pescador.call("_aplicar_estado_rio")

func _on_paso_abierto() -> void:
	AudioManager.set_ambient(AMB_RIO)

func _exit_tree() -> void:
	AudioManager.stop_music()
