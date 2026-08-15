extends Control

@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var language_button: Button = %LanguageButton
@onready var back_button: Button = %BackButton
@onready var title_label: Label = %Title
@onready var volume_label: Label = %VolumeLabel
@onready var language_label: Label = %LanguageLabel
@onready var card: PanelContainer = $Card

var _from_pause := false

func setup_as_pause() -> void:
	_from_pause = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sync_from_settings()
	_refresh_texts()
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	language_button.pressed.connect(_on_language_pressed)
	if GameSettings:
		GameSettings.locale_changed.connect(_on_locale_changed)
		GameSettings.fullscreen_changed.connect(_on_fullscreen_changed)
	_on_volume_changed(volume_slider.value)
	await get_tree().process_frame
	_center_card()
	_adapt_layout()
	if DisplayAdapt:
		DisplayAdapt.adapted.connect(_on_display_adapted)

func _on_display_adapted() -> void:
	_center_card()
	_adapt_layout()

func _center_card() -> void:
	if card == null:
		return
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH

func _adapt_layout() -> void:
	var s := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	if card:
		var half_w := 300.0 * s
		var extra := 36.0 if fullscreen_check and fullscreen_check.visible else 0.0
		var half_h := (250.0 + extra) * s
		card.offset_left = -half_w
		card.offset_right = half_w
		card.offset_top = -half_h
		card.offset_bottom = half_h
	if back_button:
		back_button.custom_minimum_size = Vector2(0, 56 * s)
	if volume_slider:
		volume_slider.custom_minimum_size = Vector2(0, 36 * s)
	if language_button:
		language_button.custom_minimum_size = Vector2(140 * s, 44 * s)

func _sync_from_settings() -> void:
	if GameSettings == null:
		return
	volume_slider.value = GameSettings.volume
	fullscreen_check.set_pressed_no_signal(GameSettings.fullscreen)
	fullscreen_check.visible = _from_pause
	_refresh_language_button()

func _refresh_language_button() -> void:
	if language_button == null or GameSettings == null:
		return
	language_button.auto_translate = false
	language_button.text = GameSettings.language_display_name()

func _refresh_texts() -> void:
	_set_tr_text(title_label, "Configuración")
	_set_tr_text(volume_label, "Volumen")
	_set_tr_text(language_label, "Idioma")
	_set_tr_text(fullscreen_check, "Pantalla completa")
	_set_tr_text(back_button, "Volver")
	_refresh_language_button()

func _set_tr_text(node: Control, key: String) -> void:
	if node == null:
		return
	node.auto_translate = false
	node.set("text", tr(key))

func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()

func _on_fullscreen_changed(enabled: bool) -> void:
	if fullscreen_check:
		fullscreen_check.set_pressed_no_signal(enabled)

func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d%%" % int(round(value))
	if GameSettings:
		GameSettings.set_volume(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if GameSettings:
		GameSettings.set_fullscreen(pressed)

func _on_language_pressed() -> void:
	if GameSettings:
		GameSettings.toggle_language()

func _on_back_button_pressed() -> void:
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _from_pause:
			return
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
