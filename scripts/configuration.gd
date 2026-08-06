extends Control

const SETTINGS_PATH := "user://settings.cfg"

@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var back_button: Button = %BackButton
@onready var card: PanelContainer = $Card

func _ready() -> void:
	_load_settings()
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_on_volume_changed(volume_slider.value)
	_adapt_layout()
	if DisplayAdapt:
		DisplayAdapt.adapted.connect(_adapt_layout)

func _adapt_layout() -> void:
	var s := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	if card:
		var half_w := 280.0 * s
		var half_h := 210.0 * s
		card.offset_left = -half_w
		card.offset_right = half_w
		card.offset_top = -half_h
		card.offset_bottom = half_h
	if back_button:
		back_button.custom_minimum_size = Vector2(0, 56 * s)
	if volume_slider:
		volume_slider.custom_minimum_size = Vector2(0, 36 * s)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var volume := 50.0
	if cfg.load(SETTINGS_PATH) == OK:
		volume = float(cfg.get_value("audio", "master", 50.0))
		var fs := bool(cfg.get_value("video", "fullscreen", false))
		fullscreen_check.button_pressed = fs
		_apply_fullscreen(fs)
	volume_slider.value = clampf(volume, 0.0, 100.0)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master", volume_slider.value)
	cfg.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	cfg.save(SETTINGS_PATH)

func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d%%" % int(round(value))
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		_linear_to_db(value / 100.0)
	)
	_save_settings()

func _on_fullscreen_toggled(pressed: bool) -> void:
	_apply_fullscreen(pressed)
	_save_settings()

func _apply_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _linear_to_db(value: float) -> float:
	if value > 0.0:
		return 20.0 * (log(value) / log(10.0))
	return -80.0

func _on_back_button_pressed() -> void:
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
