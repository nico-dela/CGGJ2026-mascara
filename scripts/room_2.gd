extends RoomSetup

const AMB_COMISARIA := preload("res://audios/AMBIENTES Y SFX/AMBIENTES/ambienteComisaría.ogg")
const STEPS_WOOD := preload("res://audios/AMBIENTES Y SFX/FOLEYS FINALES/pasosMadera.ogg")

func _on_room_ready() -> void:
	AudioManager.stop_music()
	AudioManager.set_ambient(AMB_COMISARIA)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_footstep_stream"):
		player.set_footstep_stream(STEPS_WOOD)
