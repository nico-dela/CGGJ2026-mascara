extends RoomSetup

const AMB_TABERNA := preload("res://assets/audio/ambience/ambiente_taberna.ogg")
const STEPS_WOOD := preload("res://assets/audio/sfx/pasos_madera.ogg")

func _on_room_ready() -> void:
	AudioManager.stop_music()
	AudioManager.set_ambient(AMB_TABERNA)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_footstep_stream"):
		player.set_footstep_stream(STEPS_WOOD)
