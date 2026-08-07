extends CanvasLayer

## Opens the configuration overlay as a pause menu during gameplay.
## Includes an on-screen button so the game can be played mouse-only.

const CONFIG_SCENE := preload("res://scenes/configuration.tscn")
const CONFIG_ICON := preload("res://images/config button.png")
const UI_FONT: Font = preload("res://fonts/SpecialElite-Regular.ttf")
const GAMEPLAY_SCENES := [
	"res://scenes/room_1.tscn",
	"res://scenes/room_2.tscn",
	"res://scenes/room_3.tscn",
]

var _dialogue_active := false
var _config: Control = null
var _ui_root: Control
var _button: Button

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	if SceneRouter and SceneRouter.has_signal("scene_changed"):
		SceneRouter.scene_changed.connect(func(_path): _refresh_button())
	_refresh_button()

func _process(_delta: float) -> void:
	if _button == null:
		return
	var should_show := _is_gameplay_scene() and not _dialogue_active
	if _button.visible != should_show:
		_refresh_button()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if not _is_gameplay_scene():
		return
	if _dialogue_active and not is_paused():
		return

	if is_paused():
		close_pause()
	else:
		open_pause()
	get_viewport().set_input_as_handled()

func is_paused() -> bool:
	return _config != null and is_instance_valid(_config)

func open_pause() -> void:
	if is_paused() or _dialogue_active:
		return
	if not _is_gameplay_scene():
		return
	InteractionHint.set_suppressed(true)
	get_tree().paused = true
	_config = CONFIG_SCENE.instantiate()
	_config.process_mode = Node.PROCESS_MODE_ALWAYS
	if _config.has_method("setup_as_pause"):
		_config.setup_as_pause()
	_config.tree_exited.connect(_on_config_exited)
	_ui_root.add_child(_config)
	_config.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_config.z_index = 10
	_refresh_button()

func close_pause() -> void:
	if is_paused():
		var node := _config
		_config = null
		if is_instance_valid(node):
			node.queue_free()
	get_tree().paused = false
	InteractionHint.set_suppressed(false)
	_refresh_button()

func _on_config_exited() -> void:
	_config = null
	get_tree().paused = false
	InteractionHint.set_suppressed(false)
	_refresh_button()

func _on_dialogue_started(_resource) -> void:
	_dialogue_active = true
	_refresh_button()

func _on_dialogue_ended(_resource) -> void:
	_dialogue_active = false
	_refresh_button()

func _on_settings_pressed() -> void:
	if is_paused():
		close_pause()
	else:
		open_pause()

func _build_ui() -> void:
	_ui_root = Control.new()
	_ui_root.name = "UIRoot"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_root)

	_button = Button.new()
	_button.name = "SettingsButton"
	_button.text = "Config"
	_button.icon = CONFIG_ICON
	_button.expand_icon = true
	_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_button.focus_mode = Control.FOCUS_NONE
	_button.process_mode = Node.PROCESS_MODE_ALWAYS
	_button.add_theme_font_override("font", UI_FONT)
	_button.add_theme_constant_override("icon_max_width", 36)
	_button.pressed.connect(_on_settings_pressed)
	_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(_button)
	_layout_button()
	if DisplayAdapt:
		DisplayAdapt.adapted.connect(_layout_button)

func _layout_button() -> void:
	if _button == null:
		return
	var ui := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	var safe := DisplayAdapt.safe_margin if DisplayAdapt else Vector4.ZERO
	var w := 168.0 * ui
	var h := 56.0 * ui
	var margin := 20.0 * ui
	_button.add_theme_font_override("font", UI_FONT)
	_button.add_theme_font_size_override("font_size", int(22 * ui))
	_button.custom_minimum_size = Vector2(w, h)
	_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_button.grow_vertical = Control.GROW_DIRECTION_END
	_button.offset_left = -(w + margin + safe.z)
	_button.offset_right = -(margin + safe.z)
	_button.offset_top = margin + safe.y
	_button.offset_bottom = margin + safe.y + h

func _refresh_button() -> void:
	if _button == null:
		return
	var should_show := _is_gameplay_scene() and not _dialogue_active
	_button.visible = should_show
	_layout_button()

func _is_gameplay_scene() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var path := String(scene.scene_file_path)
	if path in GAMEPLAY_SCENES:
		return true
	return get_tree().get_first_node_in_group("player") != null
