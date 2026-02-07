extends Control

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

func _on_Iniciar_pressed():
	click_sound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scenes/scene_manager.tscn")

#func _on_Configuracion_pressed():
	#click_sound.play()
	#await get_tree().create_timer(0.15).timeout
	#var config_scene = preload("res://scenes/configuration.tscn").instantiate()
	#add_child(config_scene)
#
#func _on_Creditos_pressed():
	#var credits_scene = preload("res://scenes/credits.tscn").instantiate()
	#add_child(credits_scene)

func _on_Salir_pressed():
	click_sound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _on_iniciar_button_mouse_entered() -> void:
		hover_sound.play()

func _on_configuracion_button_mouse_entered() -> void:
	hover_sound.play()

func _on_salir_button_mouse_entered() -> void:
	hover_sound.play()
