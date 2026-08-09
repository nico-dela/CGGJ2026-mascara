extends Node2D
class_name RoomSetup

## Shared room bootstrap: world colliders must not eat mouse clicks.

func _ready() -> void:
	_disable_world_mouse_picking(self)
	_on_room_ready()

func _on_room_ready() -> void:
	pass

func _disable_world_mouse_picking(node: Node) -> void:
	for child in node.get_children():
		if child is StaticBody2D or child is AnimatableBody2D or child is CharacterBody2D:
			# Keep the player group pickable flag as player.gd configures it.
			if not child.is_in_group("player"):
				child.input_pickable = false
		_disable_world_mouse_picking(child)
