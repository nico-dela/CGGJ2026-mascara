extends Area2D

func _input_event(_viewport, event, _shape_idx):
	# Si el paso ya está abierto, no hago nada
	if GameManager.is_paso_abierto():
		return
	
	if event is InputEventMouseButton and event.pressed:
		# Aquí puedes poner el diálogo de "la hiedra bloquea el paso"
		DialogueManager.show_dialogue_balloon(load("res://dialogues/hiedra.dialogue"), "start")
		# No haces queue_free() porque el objeto sigue en la escena
