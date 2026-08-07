extends CanvasLayer

## Desktop verb hint that follows the mouse (Monkey Island style).

const UI_FONT: Font = preload("res://fonts/SpecialElite-Regular.ttf")

var _label: Label
var _visible_text := ""
var _suppressed := false
var _source: WeakRef = null

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = _ensure_label()
	_apply_font()
	hide_hint()
	if DisplayAdapt:
		DisplayAdapt.adapted.connect(_adapt)
	_adapt()
	get_tree().node_removed.connect(_on_node_removed)

func _process(_delta: float) -> void:
	if _label == null:
		return
	if _suppressed or (DisplayAdapt and DisplayAdapt.is_touch_device):
		return
	if _label.visible:
		if not _is_source_still_hovered():
			hide_hint()
			return
		var mouse := get_viewport().get_mouse_position()
		_label.global_position = mouse + Vector2(18, 14)

func show_hint(text: String, source: Node = null) -> void:
	if text.is_empty():
		hide_hint()
		return
	if DisplayAdapt and DisplayAdapt.is_touch_device:
		return
	_source = weakref(source) if source else null
	if _suppressed:
		_visible_text = text
		return
	_visible_text = text
	_apply_font()
	_label.text = text
	_label.visible = true
	_label.global_position = get_viewport().get_mouse_position() + Vector2(18, 14)

func hide_hint() -> void:
	_visible_text = ""
	_source = null
	if _label:
		_label.visible = false

func hide_hint_from(source: Node) -> void:
	if _source != null:
		var src = _source.get_ref()
		if src != null and src != source:
			return
	hide_hint()

func clear() -> void:
	hide_hint()

func set_suppressed(value: bool) -> void:
	_suppressed = value
	if _suppressed:
		if _label:
			_label.visible = false
	else:
		# Never restore a stale verb after dialogue/pause/scene change.
		hide_hint()

func _on_node_removed(node: Node) -> void:
	if _source == null:
		return
	var src = _source.get_ref()
	if src == null or src == node:
		hide_hint()

func _is_source_still_hovered() -> bool:
	if _source == null:
		return false
	var src = _source.get_ref()
	if src == null or not is_instance_valid(src):
		return false
	if src is CanvasItem and not (src as CanvasItem).is_visible_in_tree():
		return false
	if src is CollisionObject2D and not (src as CollisionObject2D).input_pickable:
		return false

	var space := _world_space()
	if space == null:
		return false
	var query := PhysicsPointQueryParameters2D.new()
	query.position = _mouse_world_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0x7FFFFFFF
	var hits := space.intersect_point(query, 32)
	for hit in hits:
		if hit.collider == src:
			return true
	return false

func _world_space() -> PhysicsDirectSpaceState2D:
	var world_2d := get_viewport().find_world_2d()
	if world_2d == null:
		return null
	return world_2d.direct_space_state

func _mouse_world_position() -> Vector2:
	var canvas_xform := get_viewport().get_canvas_transform()
	return canvas_xform.affine_inverse() * get_viewport().get_mouse_position()

func _adapt() -> void:
	_apply_font()

func _apply_font() -> void:
	if _label == null:
		return
	var ui := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	_label.add_theme_font_override("font", UI_FONT)
	_label.add_theme_font_size_override("font_size", int(26 * ui))

func _ensure_label() -> Label:
	var existing := get_node_or_null("HintLabel") as Label
	if existing:
		return existing
	var label := Label.new()
	label.name = "HintLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_color_override("font_color", Color(1, 0.92, 0.55))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 26)
	label.visible = false
	add_child(label)
	return label
