extends Area2D

@onready var sprite := $Sprite2D

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		GameManager.add_item("oso")

		var ui = get_tree().get_first_node_in_group("inventory_ui")
		if ui:
			ui.refresh()

		DialogueManager.show_dialogue_balloon(load("res://dialogues/oso_mask_found.dialogue"), "start")
		queue_free()

func _mouse_enter():
	sprite.scale = Vector2(1.05, 1.05)
	sprite.modulate = Color(1.2, 1.2, 1.2)

func _mouse_exit():
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
