extends Control

const CREDITS_MUSIC := preload("res://assets/audio/music/musica_creditos.ogg")

const COL_INK := "#2a1c12"
const COL_ROLE := "#6b3d16"
const COL_TITLE := "#3d2410"

@onready var left_body: RichTextLabel = %LeftBody
@onready var right_body: RichTextLabel = %RightBody
@onready var back_button: Button = $BackButton
@onready var book: HBoxContainer = %Book
@onready var backdrop: ColorRect = $Backdrop

func _ready() -> void:
	if AudioManager:
		AudioManager.fade_out_ambient()
		AudioManager.set_music(CREDITS_MUSIC)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if backdrop:
		backdrop.gui_input.connect(_on_backdrop_gui_input)
	if GameSettings:
		GameSettings.locale_changed.connect(_on_locale_changed)
	_refresh_text()
	_adapt_layout()
	if DisplayAdapt:
		DisplayAdapt.adapted.connect(_adapt_layout)

func _on_locale_changed(_locale: String) -> void:
	_refresh_text()
	_adapt_layout()

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_back_pressed()

func _adapt_layout() -> void:
	var s := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	if back_button:
		back_button.custom_minimum_size = Vector2(220, 56) * s
		back_button.add_theme_font_size_override("font_size", int(28 * s))
	if book:
		var pad := 72.0 * s
		book.offset_left = pad
		book.offset_right = -pad
		book.offset_top = 36.0 * s
		book.offset_bottom = -96.0 * s
	_refresh_text()

func _refresh_text() -> void:
	var s := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	if back_button:
		back_button.auto_translate = false
		back_button.text = tr("Menú principal")
	if left_body:
		left_body.text = _left_page(s)
	if right_body:
		right_body.text = _right_page(s)

func _left_page(s: float) -> String:
	var title_s := int(40 * s)
	var head_s := int(28 * s)
	var role_s := int(20 * s)
	var name_s := int(20 * s)
	var gap := int(10 * s)
	var out := ""
	out += _center(_colored(COL_TITLE, title_s, tr("El Caso del Leñador").to_upper()))
	out += _pad(6)
	out += _center(_colored(COL_ROLE, head_s, tr("Créditos").to_upper()))
	out += _pad(4)
	out += _center(_colored(COL_INK, name_s, "© 2026 — KUMO"))
	out += _pad(gap)
	out += _block(tr("Dirección y producción"), ["KUMO"], role_s, name_s)
	out += _block(tr("Programación"), ["Nicolás de la Cruz", "Julián Medrano Santos"], role_s, name_s)
	out += _colored(COL_ROLE, head_s, tr("Arte").to_upper()) + "\n"
	out += _pad(4)
	out += _block(tr("Pixel art"), [
		"Tobeco (Tobías Gencarelli)",
		"Matías \"Mostruitus\" Berelejis",
		"Camilo Gencarelli",
	], role_s, name_s)
	out += _block(tr("Animación"), ["Tobeco (Tobías Gencarelli)"], role_s, name_s)
	out += _block("UI / UX", [
		"Tobeco (Tobías Gencarelli)",
		"Matías \"Mostruitus\" Berelejis",
		"Camilo Gencarelli",
	], role_s, name_s)
	return out

func _right_page(s: float) -> String:
	var head_s := int(28 * s)
	var role_s := int(20 * s)
	var name_s := int(20 * s)
	var out := ""
	out += _block(tr("Concept art"), ["Tobeco (Tobías Gencarelli)"], role_s, name_s)
	out += _colored(COL_ROLE, head_s, tr("Diseño").to_upper()) + "\n"
	out += _pad(4)
	out += _block(tr("Game design"), ["KUMO"], role_s, name_s)
	out += _colored(COL_ROLE, head_s, tr("Audio").to_upper()) + "\n"
	out += _pad(4)
	out += _block(tr("Diseño de sonido"), ["Gustavo Orellano", "Camilo Gencarelli"], role_s, name_s)
	out += _block(tr("Música"), ["Camilo Gencarelli"], role_s, name_s)
	out += _block(tr("Implementación de audio"), ["Gustavo Orellano", "Nicolás de la Cruz"], role_s, name_s)
	out += _pad(int(16 * s))
	out += _colored(COL_INK, name_s, tr("Córdoba Global Game Jam 2026"))
	out += "\n"
	out += _colored(COL_INK, int(18 * s), tr("Producción y game design: todo el equipo."))
	return out

func _block(role: String, names: Array, role_s: int, name_s: int) -> String:
	var lines := _colored(COL_ROLE, role_s, role.to_upper()) + "\n"
	for person: String in names:
		lines += _colored(COL_INK, name_s, "  " + person) + "\n"
	lines += _pad(8)
	return lines

func _colored(color: String, font_px: int, text: String) -> String:
	return "[color=%s][font_size=%d]%s[/font_size][/color]" % [color, font_px, text]

func _center(inner: String) -> String:
	return "[center]%s[/center]\n" % inner

func _pad(px: int) -> String:
	return "[font_size=%d] [/font_size]\n" % maxi(4, px)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _exit_tree() -> void:
	if AudioManager:
		AudioManager.restore_game_music()

func _on_back_pressed() -> void:
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		queue_free()
