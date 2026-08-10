extends Control

const UI_FONT: Font = preload("res://assets/fonts/SpecialElite-Regular.ttf")

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound
@onready var button_bar: VBoxContainer = $ButtonBar

var _landscape_tip: Control

func _ready() -> void:
	_ensure_landscape_tip()
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

	_update_landscape_tip()

func _ensure_landscape_tip() -> void:
	if _landscape_tip != null:
		return

	var tip := Control.new()
	tip.name = "LandscapeTip"
	tip.set_anchors_preset(Control.PRESET_FULL_RECT)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.visible = false
	add_child(tip)
	# Keep above background, below modal config if opened later.
	move_child(tip, button_bar.get_index())

	var dim := Panel.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim_style := StyleBoxFlat.new()
	dim_style.bg_color = Color(0.04, 0.03, 0.06, 0.55)
	dim.add_theme_stylebox_override("panel", dim_style)
	tip.add_child(dim)

	var card := PanelContainer.new()
	card.name = "Card"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -320.0
	card.offset_top = -70.0
	card.offset_right = 320.0
	card.offset_bottom = 70.0
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.09, 0.14, 0.96)
	card_style.border_width_left = 3
	card_style.border_width_top = 3
	card_style.border_width_right = 3
	card_style.border_width_bottom = 3
	card_style.border_color = Color(0.85, 0.78, 0.45, 1)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.content_margin_left = 28
	card_style.content_margin_top = 24
	card_style.content_margin_right = 28
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	tip.add_child(card)

	var label := Label.new()
	label.name = "TipLabel"
	label.text = "Para una mejor experiencia, girá la pantalla en horizontal."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(label)

	_landscape_tip = tip

func _update_landscape_tip() -> void:
	if _landscape_tip == null:
		return
	var show_tip := DisplayAdapt != null and DisplayAdapt.is_touch_device and DisplayAdapt.is_portrait()
	_landscape_tip.visible = show_tip

func _on_Iniciar_pressed() -> void:
	click_sound.play()
	await get_tree().create_timer(0.15).timeout
	GameManager.start_new_game()

func _on_Configuracion_pressed() -> void:
	click_sound.play()
	await get_tree().create_timer(0.15).timeout
	var config_scene = preload("res://scenes/ui/configuration.tscn").instantiate()
	add_child(config_scene)

func _on_Creditos_pressed() -> void:
	click_sound.play()
	await get_tree().create_timer(0.15).timeout
	var credits_scene = preload("res://scenes/ui/credits.tscn").instantiate()
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
