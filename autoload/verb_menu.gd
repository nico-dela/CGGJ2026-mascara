extends CanvasLayer

## Small verb popup for world props (Observar / Agarrar / Usar).

const UI_FONT: Font = preload("res://assets/fonts/SpecialElite-Regular.ttf")

signal closed

var _panel: PanelContainer
var _vbox: VBoxContainer
var _title: Label
var _target: WeakRef = null
var _open := false

func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_menu()
	if DisplayAdapt:
		DisplayAdapt.adapted.connect(_adapt)
	_adapt()

func is_open() -> bool:
	return _open

func show_for(target: Node, screen_pos: Vector2) -> void:
	if target == null or not target.has_method("get_verb_actions"):
		return
	var actions: Array = target.get_verb_actions()
	if actions.is_empty():
		return
	_target = weakref(target)
	_open = true
	InteractionHint.set_suppressed(true)
	_clear_buttons()
	var label_name := ""
	if target.has_method("get_interact_label"):
		label_name = target.get_interact_label()
	_title.text = label_name if label_name != "" else "Objeto"
	for action in actions:
		var id := str(action.get("id", ""))
		var text := str(action.get("text", id))
		var enabled := bool(action.get("enabled", true))
		var btn := Button.new()
		btn.text = text
		btn.disabled = not enabled
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_action_pressed.bind(id))
		_style_button(btn, enabled)
		_vbox.add_child(btn)
	_panel.visible = true
	_panel.reset_size()
	await get_tree().process_frame
	_place_panel(screen_pos)

func hide_menu() -> void:
	_open = false
	_target = null
	if _panel:
		_panel.visible = false
	_clear_buttons()
	InteractionHint.set_suppressed(false)
	closed.emit()

func _on_action_pressed(action_id: String) -> void:
	var target: Node = null
	if _target != null:
		target = _target.get_ref()
	hide_menu()
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("run_verb_action"):
		target.run_verb_action(action_id)

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_menu()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		# Click outside closes; button clicks are handled by the Control.
		if not _panel.get_global_rect().has_point(event.position):
			hide_menu()
			get_viewport().set_input_as_handled()

func _place_panel(screen_pos: Vector2) -> void:
	var margin := 12.0
	var size := _panel.size
	if size.x < 8.0:
		size = _panel.get_combined_minimum_size()
	var view := get_viewport().get_visible_rect().size
	var pos := screen_pos + Vector2(12, 12)
	if pos.x + size.x > view.x - margin:
		pos.x = screen_pos.x - size.x - 12.0
	if pos.y + size.y > view.y - margin:
		pos.y = screen_pos.y - size.y - 12.0
	pos.x = clampf(pos.x, margin, maxf(margin, view.x - size.x - margin))
	pos.y = clampf(pos.y, margin, maxf(margin, view.y - size.y - margin))
	_panel.global_position = pos

func _clear_buttons() -> void:
	if _vbox == null:
		return
	for child in _vbox.get_children():
		if child != _title:
			child.queue_free()

func _adapt() -> void:
	if _title == null:
		return
	var ui := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	_title.add_theme_font_size_override("font_size", int(22 * ui))
	for child in _vbox.get_children():
		if child is Button:
			child.add_theme_font_size_override("font_size", int(24 * ui))
			child.custom_minimum_size = Vector2(220 * ui, 44 * ui)

func _style_button(btn: Button, enabled: bool) -> void:
	var ui := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	btn.add_theme_font_override("font", UI_FONT)
	btn.add_theme_font_size_override("font_size", int(24 * ui))
	btn.custom_minimum_size = Vector2(220 * ui, 44 * ui)
	btn.add_theme_color_override("font_color", Color(1, 0.92, 0.55) if enabled else Color(0.55, 0.55, 0.55))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.75))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.8, 0.4))

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.08, 0.94)
	style.border_color = Color(1, 0.92, 0.55, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_panel)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(_vbox)

	_title = Label.new()
	_title.add_theme_font_override("font", UI_FONT)
	_title.add_theme_color_override("font_color", Color(0.75, 0.7, 0.55))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(_title)
