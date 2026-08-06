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
	var scale := DisplayAdapt.ui_scale
	var touch := DisplayAdapt.is_touch_device
	var min_h := (72.0 if touch else 56.0) * scale
	var min_w := (360.0 if touch else 300.0) * scale
	var separation := int((14.0 if touch else 12.0) * scale)
	var icon_w := int((44.0 if touch else 36.0) * scale)
	var bottom_pad := 40.0 + DisplayAdapt.safe_margin.w
	var right_pad := 40.0 + DisplayAdapt.safe_margin.z
	if touch:
		bottom_pad = maxf(bottom_pad, 56.0)
		right_pad = maxf(right_pad, 48.0)

	button_bar.add_theme_constant_override("separation", separation)

	var visible_buttons := 0
	for child in button_bar.get_children():
		if child is Button:
			var btn := child as Button
			btn.custom_minimum_size = Vector2(min_w, min_h)
			btn.add_theme_font_size_override("font_size", int((28.0 if touch else 26.0) * scale))
			btn.add_theme_constant_override("icon_max_width", icon_w)
			btn.expand_icon = false
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			if btn.visible:
				visible_buttons += 1

	var bar_height := visible_buttons * min_h + maxi(0, visible_buttons - 1) * separation
	button_bar.offset_right = -right_pad
	button_bar.offset_left = -(right_pad + min_w)
	button_bar.offset_bottom = -bottom_pad
	button_bar.offset_top = -(bottom_pad + bar_height)

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
