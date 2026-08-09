extends Node2D
class_name RoomRoad

## Opening road: guard encounter, bag flavour, enter town.
## Root is offset on Y so it does not overlap room_1 in the Godot 2D editor
## when both scenes are open as tabs.

const STEPS_DIRT := preload("res://assets/audio/sfx/pasos_tierra.ogg")
const AMB_PUEBLO := preload("res://assets/audio/ambience/ambiente_pueblo.ogg")
const ROOM_SIZE := Vector2i(1920, 1080)

func _ready() -> void:
	_disable_world_mouse_picking(self)
	AudioManager.start_music()
	AudioManager.set_ambient(AMB_PUEBLO)
	var player = get_tree().get_first_node_in_group("player")
	var origin := global_position
	if player and player.has_method("apply_camera_limits"):
		player.apply_camera_limits(
			int(origin.x),
			int(origin.y),
			int(origin.x) + ROOM_SIZE.x,
			int(origin.y) + ROOM_SIZE.y
		)
	if player and player.has_method("set_footstep_stream"):
		player.set_footstep_stream(STEPS_DIRT)

func _disable_world_mouse_picking(node: Node) -> void:
	for child in node.get_children():
		if child is StaticBody2D or child is AnimatableBody2D or child is CharacterBody2D:
			if not child.is_in_group("player"):
				child.input_pickable = false
		_disable_world_mouse_picking(child)

func _exit_tree() -> void:
	AudioManager.stop_music()
