extends Control

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound
@onready var button_bar: VBoxContainer = $ButtonBar

func _ready() -> void:
	DisplayAdapt.adapted.connect(_layout_for_device)
	# Salir no tiene efecto útil en el export web.
	if OS.has_feature("web"):
		var salir := button_bar.get_node_or_null("SalirButton") as Button
		if salir:
			salir.visible = false
	_layout_for_device()

func _layout_for_device() -> void:
	# Misma posición y tamaño en design-space (1920x1080) en desktop y móvil.
	# El stretch del viewport ya adapta el canvas; no mover con safe-area/ui_scale.
	const MIN_H := 56.0
	const MIN_W := 300.0
	const SEPARATION := 12
	const ICON_W := 40
	const BOTTOM_PAD := 48.0
	const RIGHT_PAD := 48.0

	button_bar.add_theme_constant_override("separation", SEPARATION)

	var visible_buttons := 0
	for child in button_bar.get_children():
		if child is Button:
			var btn := child as Button
			btn.custom_minimum_size = Vector2(MIN_W, MIN_H)
			btn.add_theme_font_size_override("font_size", 26)
			btn.add_theme_constant_override("icon_max_width", ICON_W)
			btn.expand_icon = true
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			if btn.visible:
				visible_buttons += 1

	var bar_height := visible_buttons * MIN_H + maxi(0, visible_buttons - 1) * SEPARATION
	button_bar.offset_right = -RIGHT_PAD
	button_bar.offset_left = -(RIGHT_PAD + MIN_W)
	button_bar.offset_bottom = -BOTTOM_PAD
	button_bar.offset_top = -(BOTTOM_PAD + bar_height)

func _on_Iniciar_pressed() -> void:
	click_sound.play()
	await get_tree().create_timer(0.15).timeout
	GameManager.start_new_game()

func _on_Configuracion_pressed() -> void:
	click_sound.play()
	await get_tree().create_timer(0.15).timeout
	var config_scene = preload("res://scenes/configuration.tscn").instantiate()
	add_child(config_scene)

func _on_Creditos_pressed() -> void:
	click_sound.play()
	await get_tree().create_timer(0.15).timeout
	var credits_scene = preload("res://scenes/credits.tscn").instantiate()
	add_child(credits_scene)

func _on_Salir_pressed() -> void:
	click_sound.play()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _on_iniciar_button_mouse_entered() -> void:
	hover_sound.play()

func _on_configuracion_button_mouse_entered() -> void:
	hover_sound.play()

func _on_creditos_button_mouse_entered() -> void:
	hover_sound.play()

func _on_salir_button_mouse_entered() -> void:
	hover_sound.play()
