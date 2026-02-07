extends Area2D

#@export var mascara_prueba: ItemResource
#@export var mascaras_decomisadas: Array[ItemResource]

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		#GameManager.add_item("patito")
#
		#var ui = get_tree().get_first_node_in_group("inventory_ui")
		#if ui:
			#ui.refresh()

		DialogueManager.show_dialogue_balloon(load("res://dialogues/comisario.dialogue"), "start")
		#queue_free()
