extends Control

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound
@onready var button_bar: VBoxContainer = $SafeArea/ButtonBar

const ICON_CONFIG := preload("res://images/config button.png")
const ICON_CREDITS := preload("res://images/credits button.png")

func _ready() -> void:
	DisplayAdapt.adapted.connect(_layout_for_device)
	_layout_for_device()
	_ensure_extra_buttons()
	_layout_for_device()

func _layout_for_device() -> void:
	DisplayAdapt.apply_safe_margins_to($SafeArea)
	var min_h := 64.0 * DisplayAdapt.ui_scale if DisplayAdapt.is_touch_device else 52.0
	var min_w := 260.0 * DisplayAdapt.ui_scale if DisplayAdapt.is_touch_device else 240.0
	for child in button_bar.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(min_w, min_h)

func _ensure_extra_buttons() -> void:
	if not button_bar.has_node("ConfiguracionButton"):
		var config_btn := _make_menu_button("ConfiguracionButton", "Configuración", ICON_CONFIG)
		var salir_idx := button_bar.get_node("SalirButton").get_index()
		button_bar.add_child(config_btn)
		button_bar.move_child(config_btn, salir_idx)
		config_btn.pressed.connect(_on_Configuracion_pressed)
		config_btn.mouse_entered.connect(_on_configuracion_button_mouse_entered)

	if not button_bar.has_node("CreditosButton"):
		var credits_btn := _make_menu_button("CreditosButton", "Créditos", ICON_CREDITS)
		var salir_idx := button_bar.get_node("SalirButton").get_index()
		button_bar.add_child(credits_btn)
		button_bar.move_child(credits_btn, salir_idx)
		credits_btn.pressed.connect(_on_Creditos_pressed)
		credits_btn.mouse_entered.connect(func(): hover_sound.play())

func _make_menu_button(node_name: String, text: String, icon: Texture2D = null) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.expand_icon = true
	# Match Jugar/Salir chrome so runtime buttons don't use a darker default StyleBox.
	var template: Button = button_bar.get_node_or_null("IniciarButton") as Button
	if template:
		btn.theme = template.theme
		btn.add_theme_font_size_override("font_size", template.get_theme_font_size("font_size"))
		for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			var style := template.get_theme_stylebox(style_name)
			if style:
				btn.add_theme_stylebox_override(style_name, style)
	if icon:
		btn.icon = icon
	return btn

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

func _on_salir_button_mouse_entered() -> void:
	hover_sound.play()
