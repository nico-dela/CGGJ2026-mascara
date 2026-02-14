extends Area2D

@onready var sprite := $Sprite2D

func _ready():
	# Pregunto si YA LO RECOGÍ ALGUNA VEZ (aunque ya no lo tenga en inventario)
	if GameManager.is_collected("oso"):
		queue_free()  # No aparezco

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# 1. MARCO como recogido permanentemente
		GameManager.mark_as_collected("oso")
		
		# 2. AÑADO al inventario actual
		GameManager.add_item("oso")
		
		# 3. REFRESCO la UI
		var ui = get_tree().get_first_node_in_group("inventory_ui")
		if ui:
			ui.refresh()
		
		# 4. MUESTRO el diálogo
		DialogueManager.show_dialogue_balloon(load("res://dialogues/oso_mask_found.dialogue"), "start")
		
		# 5. ME BORRO de la escena actual
		queue_free()

func _mouse_enter():
	sprite.scale = Vector2(1.05, 1.05)
	sprite.modulate = Color(1.2, 1.2, 1.2)

func _mouse_exit():
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
