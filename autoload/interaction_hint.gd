extends CanvasLayer

## Desktop verb hint that follows the mouse (Monkey Island style).

const UI_FONT: Font = preload("res://assets/fonts/SpecialElite-Regular.ttf")
const SELF_HINT_RADIUS := 110.0

var _label: Label
var _visible_text := ""
var _suppressed := false
var _source: WeakRef = null
## True while an inventory item is selected and the hint follows the cursor freely.
var _selection_follow := false

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
	Inventory.selection_changed.connect(_on_selection_changed)

func _process(_delta: float) -> void:
	if _label == null:
		return
	if _suppressed or (DisplayAdapt and DisplayAdapt.is_touch_device):
		return

	if _source != null:
		if not _is_source_still_hovered():
			_source = null
			_refresh_from_cursor()
			return
		_place_label(get_viewport().get_mouse_position())
		return

	if _selection_follow and Inventory.selected_item != "":
		_refresh_from_cursor()
		if _label.visible:
			_place_label(get_viewport().get_mouse_position())

func show_hint(text: String, source: Node = null) -> void:
	if text.is_empty():
		hide_hint()
		return
	if DisplayAdapt and DisplayAdapt.is_touch_device:
		return
	_source = weakref(source) if source else null
	_selection_follow = source == null and Inventory.selected_item != ""
	if _suppressed:
		_visible_text = text
		return
	_visible_text = text
	_apply_font()
	_label.text = text
	_label.visible = true
	_label.reset_size()
	_place_label(get_viewport().get_mouse_position())

## Touch-friendly hint anchored near a tap / verb coin (ignores desktop mouse-follow gate).
func show_hint_at(text: String, screen_pos: Vector2) -> void:
	if text.is_empty():
		hide_hint()
		return
	_source = null
	_selection_follow = false
	if _suppressed:
		_visible_text = text
		return
	_visible_text = text
	_apply_font()
	_label.text = text
	_label.visible = true
	_label.reset_size()
	_place_label(screen_pos)

func _place_label(mouse: Vector2) -> void:
	if _label == null:
		return
	var margin := 8.0
	var cursor_pad := Vector2(18, 14)
	var size := _label.get_minimum_size()
	if size.x < 1.0 or size.y < 1.0:
		size = _label.size
	var view := get_viewport().get_visible_rect().size
	var pos := mouse + cursor_pad
	if pos.x + size.x > view.x - margin:
		pos.x = mouse.x - size.x - 12.0
	if pos.y + size.y > view.y - margin:
		pos.y = mouse.y - size.y - 12.0
	pos.x = clampf(pos.x, margin, maxf(margin, view.x - size.x - margin))
	pos.y = clampf(pos.y, margin, maxf(margin, view.y - size.y - margin))
	_label.global_position = pos

func hide_hint() -> void:
	_visible_text = ""
	_source = null
	_selection_follow = false
	if _label:
		_label.visible = false

func hide_hint_from(source: Node) -> void:
	if _source != null:
		var src = _source.get_ref()
		if src != null and src != source:
			return
	# Leaving an interactable: fall back to selection cursor text if any.
	_source = null
	if Inventory.selected_item != "" and not _suppressed:
		_show_selection_prompt()
	else:
		hide_hint()

func clear() -> void:
	hide_hint()

func set_suppressed(value: bool) -> void:
	_suppressed = value
	if _suppressed:
		if _label:
			_label.visible = false
	else:
		hide_hint()
		_on_selection_changed()

func _on_selection_changed() -> void:
	if _suppressed or (DisplayAdapt and DisplayAdapt.is_touch_device):
		return
	if Inventory.selected_item == "":
		if _source == null:
			hide_hint()
		return
	_refresh_from_cursor()

func _refresh_from_cursor() -> void:
	if _suppressed or Inventory.selected_item == "":
		if Inventory.selected_item == "" and _source == null:
			hide_hint()
		return

	var world_pos := _mouse_world_position()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player.global_position.distance_to(world_pos) <= SELF_HINT_RADIUS:
		show_hint(_self_use_verb(), player)
		return

	var hit := _top_interactable_at(world_pos)
	if hit != null and hit.has_method("get_verb_text"):
		show_hint(hit.get_verb_text(), hit)
		return

	_show_selection_prompt()

func _show_selection_prompt() -> void:
	var item_name := Inventory.get_display_name(Inventory.selected_item)
	show_hint("Usar %s con..." % item_name, null)
	_selection_follow = true

func _self_use_verb() -> String:
	var item_id := Inventory.selected_item
	var item_name := Inventory.get_display_name(item_id)
	var item := Inventory.get_item(item_id)
	if item != null and item.tipo == ItemResource.ItemTypes.MASCARA:
		if StoryFlags.is_wearing_mask(item_id):
			return "Quitarme %s" % item_name
		return "Usar %s conmigo" % item_name
	return "Usar %s conmigo" % item_name

func _on_node_removed(node: Node) -> void:
	if _source == null:
		return
	var src = _source.get_ref()
	if src == null or src == node:
		_source = null
		if Inventory.selected_item != "":
			_show_selection_prompt()
		else:
			hide_hint()

func _is_source_still_hovered() -> bool:
	if _source == null:
		return false
	var src = _source.get_ref()
	if src == null or not is_instance_valid(src):
		return false

	# Detective self-use: stay active while cursor is near the player.
	if src.is_in_group("player"):
		var player := src as Node2D
		return player != null and player.global_position.distance_to(_mouse_world_position()) <= SELF_HINT_RADIUS

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

func _top_interactable_at(world_pos: Vector2) -> Node:
	var space := _world_space()
	if space == null:
		return null
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0x7FFFFFFF
	var hits := space.intersect_point(query, 32)
	hits.sort_custom(func(a, b):
		var na: Node2D = a.collider
		var nb: Node2D = b.collider
		if na.z_index == nb.z_index:
			return na.get_index() > nb.get_index()
		return na.z_index > nb.z_index
	)
	for hit in hits:
		var collider = hit.collider
		if collider != null and collider.has_method("try_interact") and collider.has_method("get_verb_text"):
			if collider is CanvasItem and not (collider as CanvasItem).visible:
				continue
			if collider is CollisionObject2D and not (collider as CollisionObject2D).input_pickable:
				continue
			return collider
	return null

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
