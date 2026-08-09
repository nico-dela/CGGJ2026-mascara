extends CanvasLayer

## HUD estilo Full Throttle: verb coin radial + bolso de evidencia.
## Click en hotspot → moneda de acciones; el mundo queda limpio.

const UI_FONT: Font = preload("res://assets/fonts/SpecialElite-Regular.ttf")
const SLOT_SCENE := preload("res://scenes/ui/inventory_slot.tscn")

enum Verb { OBSERVE, TAKE, USE, TALK }

const COL_METAL := Color(0.18, 0.17, 0.16, 0.94)
const COL_METAL_EDGE := Color(0.55, 0.5, 0.42, 0.95)
const COL_HOT := Color(0.85, 0.55, 0.2)
const COL_INK := Color(0.92, 0.88, 0.78)
const COL_DIM := Color(0.45, 0.42, 0.38)

signal verb_changed
signal coin_closed

var current_verb: Verb = Verb.OBSERVE

var _root: Control
var _chrome: Control
var _coin: Control
var _coin_disc: Panel
var _intent: Label
var _pocket_btn: Button
var _pocket_panel: PanelContainer
var _inv_box: HBoxContainer
var _verb_buttons: Dictionary = {}  # Verb -> Button
var _coin_target: WeakRef = null
var _pocket_open := false
var _coin_open := false

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	Inventory.inventory_changed.connect(refresh_inventory)
	Inventory.selection_changed.connect(_on_selection_changed)
	StoryFlags.mask_equipped_changed.connect(_on_selection_changed)
	StoryFlags.tiene_bolso_signal.connect(_on_tiene_bolso_changed)
	if DisplayAdapt:
		DisplayAdapt.adapted.connect(_adapt)
	if SceneRouter and SceneRouter.has_signal("scene_changed"):
		SceneRouter.scene_changed.connect(func(p):
			hide_verb_coin()
			# change_scene_to_file is deferred; wait a frame then use emitted path.
			await get_tree().process_frame
			_refresh_visibility(p)
		)
	DialogueManager.dialogue_started.connect(func(_r):
		hide_verb_coin()
		_set_gameplay_interactive(false)
	)
	DialogueManager.dialogue_ended.connect(func(_r): _set_gameplay_interactive(true))
	_adapt()
	refresh_inventory()
	_refresh_visibility()
	_sync_bolso_visibility()
	hide_verb_coin()

func _process(_delta: float) -> void:
	# Keep chrome in sync when scenes change outside SceneRouter (or race on load).
	if _chrome == null:
		return
	var should := _is_room_scene()
	if _chrome.visible != should:
		_refresh_visibility()

func _is_room_scene() -> bool:
	var path := ""
	if get_tree().current_scene:
		path = str(get_tree().current_scene.scene_file_path)
	if path.begins_with("res://scenes/room_"):
		return true
	return get_tree().get_first_node_in_group("player") != null

func is_gameplay_visible() -> bool:
	return _chrome != null and _chrome.visible

func is_coin_open() -> bool:
	return _coin_open

func get_verb_id() -> String:
	match current_verb:
		Verb.OBSERVE:
			return "observe"
		Verb.TAKE:
			return "take"
		Verb.USE:
			return "use"
		Verb.TALK:
			return "talk"
	return "observe"

func set_verb(verb: Verb) -> void:
	current_verb = verb
	_update_sentence()
	verb_changed.emit()

func show_verb_coin(target: Node, screen_pos: Vector2) -> void:
	if target == null or not is_instance_valid(target):
		return
	# Ensure chrome is up even if a deferred scene swap raced visibility.
	_refresh_visibility()
	if not is_gameplay_visible():
		# Still show the coin; gameplay detection can lag one frame after load.
		if _chrome:
			_chrome.visible = true
		if _root:
			_root.visible = true
	if VerbMenu and VerbMenu.is_open():
		VerbMenu.hide_menu()
	_coin_target = weakref(target)
	_coin_open = true
	_coin.visible = true
	_coin.z_index = 20
	_intent.visible = true
	_update_coin_enables(target)
	_place_coin(screen_pos)
	_update_sentence_for_target(target)
	InteractionHint.hide_hint()

func hide_verb_coin() -> void:
	var was_open := _coin_open
	_coin_open = false
	_coin_target = null
	if _coin:
		_coin.visible = false
	if _intent:
		_intent.visible = false
		_intent.text = ""
	if was_open:
		coin_closed.emit()

func build_sentence_for(target: Node = null) -> String:
	if Inventory.selected_item != "":
		var item_name := Inventory.get_display_name(Inventory.selected_item)
		if target != null and target.has_method("get_interact_label"):
			var label: String = target.get_interact_label()
			if label != "":
				return "Usar %s con %s" % [item_name, label]
		return "Usar %s con…" % item_name
	if target != null and target.has_method("get_interact_label"):
		var label2: String = target.get_interact_label()
		if label2 != "":
			return label2
	return ""

func refresh_sentence(target: Node = null) -> void:
	if _intent == null:
		return
	if _coin_open:
		_update_sentence_for_target(_get_coin_target())
	elif Inventory.selected_item != "":
		_intent.visible = true
		_intent.text = build_sentence_for(target)
	else:
		_intent.visible = false
		_intent.text = ""

func refresh_inventory() -> void:
	if _inv_box == null:
		return
	# free() immediately so queue_free leftovers don't shift layout for a frame.
	for child in _inv_box.get_children():
		_inv_box.remove_child(child)
		child.free()
	var slot_size := _inventory_slot_size()
	for item_id in Inventory.inventory:
		var slot = SLOT_SCENE.instantiate()
		slot.setup(item_id, Inventory.get_texture(item_id))
		slot.custom_minimum_size = slot_size
		slot.size = slot_size
		slot.ignore_texture_size = true
		slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_inv_box.add_child(slot)
	_on_selection_changed()
	_update_pocket_button()
	_sync_bolso_visibility()

func _inventory_slot_size() -> Vector2:
	var ui := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	# Compact icons — source art is large; don't use full touch_slot_size.
	if DisplayAdapt and DisplayAdapt.is_touch_device:
		return Vector2(52, 52) * ui
	return Vector2(44, 44) * ui

## Called once after the road bag is taken — teaches the HUD briefly.
func play_ui_tutorial() -> void:
	_sync_bolso_visibility()
	_pulse_bolso_button()
	var tutorial: Resource = load("res://content/dialogue/system/ui_tutorial.dialogue")
	if tutorial:
		# Defer so the take balloon can finish closing first.
		get_tree().create_timer(0.05).timeout.connect(func():
			DialogueManager.show_dialogue_balloon(tutorial, "start")
		)

func _on_tiene_bolso_changed() -> void:
	_sync_bolso_visibility()
	_update_pocket_button()

func _sync_bolso_visibility() -> void:
	var has_bag: bool = StoryFlags != null and StoryFlags.has_tiene_bolso()
	if _pocket_btn:
		_pocket_btn.visible = has_bag and is_gameplay_visible()
	if _pocket_panel and not has_bag:
		_pocket_panel.visible = false
		_pocket_open = false

func _pulse_bolso_button() -> void:
	if _pocket_btn == null or not _pocket_btn.visible:
		return
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(_pocket_btn, "modulate", COL_HOT, 0.25)
	tween.tween_property(_pocket_btn, "modulate", Color.WHITE, 0.25)

func _get_coin_target() -> Node:
	if _coin_target == null:
		return null
	return _coin_target.get_ref()

func _on_selection_changed() -> void:
	for child in _inv_box.get_children():
		if child.has_method("update_selection_visual"):
			child.update_selection_visual()
	if Inventory.selected_item != "":
		current_verb = Verb.USE
		hide_verb_coin()
		_intent.visible = true
		_intent.text = build_sentence_for(null)
		if not _pocket_open:
			_set_pocket_open(true)
	else:
		refresh_sentence(null)
	verb_changed.emit()

func _update_sentence() -> void:
	refresh_sentence(null)

func _update_sentence_for_target(target: Node) -> void:
	if _intent == null:
		return
	var label := ""
	if target != null and target.has_method("get_interact_label"):
		label = target.get_interact_label()
	_intent.text = label if label != "" else "¿Qué hacés?"
	_intent.visible = true

func _update_coin_enables(target: Node) -> void:
	var can_observe := true
	var can_take := false
	var can_use := false
	var can_talk := false
	if target != null and is_instance_valid(target):
		if "can_observe" in target:
			can_observe = target.can_observe
		if "can_take" in target:
			can_take = target.can_take
		if "can_use" in target:
			can_use = target.can_use
		if "is_npc" in target:
			can_talk = target.is_npc
		elif target.has_method("get") and target.get("is_npc"):
			can_talk = bool(target.is_npc)
	_set_verb_enabled(Verb.OBSERVE, can_observe)
	_set_verb_enabled(Verb.TAKE, can_take)
	_set_verb_enabled(Verb.USE, can_use)
	_set_verb_enabled(Verb.TALK, can_talk)

func _set_verb_enabled(verb: Verb, enabled: bool) -> void:
	if not _verb_buttons.has(verb):
		return
	var btn: Button = _verb_buttons[verb]
	btn.disabled = not enabled
	btn.modulate = Color.WHITE if enabled else Color(1, 1, 1, 0.35)

func _set_gameplay_interactive(enabled: bool) -> void:
	if _pocket_btn:
		_pocket_btn.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if _pocket_panel:
		_pocket_panel.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if not enabled:
		hide_verb_coin()
	_refresh_visibility()

func _refresh_visibility(scene_path: String = "") -> void:
	var path := scene_path
	if path.is_empty() and get_tree().current_scene:
		path = str(get_tree().current_scene.scene_file_path)
	var in_room := path.begins_with("res://scenes/room_")
	# Fallback: cinematic/deferred loads can leave current_scene stale for a frame.
	if not in_room and get_tree().get_first_node_in_group("player") != null:
		in_room = true
	if _chrome:
		_chrome.visible = in_room
	if _root:
		_root.visible = in_room
	if _pocket_panel and not _pocket_open:
		_pocket_panel.visible = false
	_sync_bolso_visibility()
	for node in get_tree().get_nodes_in_group("inventory_ui"):
		if node is CanvasItem:
			(node as CanvasItem).visible = false

func _adapt() -> void:
	if _pocket_btn == null:
		return
	var ui := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	var safe := DisplayAdapt.safe_margin if DisplayAdapt else Vector4.ZERO
	var pad := 14.0 * ui

	_intent.add_theme_font_size_override("font_size", int(22 * ui))
	_pocket_btn.add_theme_font_size_override("font_size", int(20 * ui))
	_pocket_btn.custom_minimum_size = Vector2(130 * ui, 44 * ui)

	for btn in _verb_buttons.values():
		btn.add_theme_font_size_override("font_size", int(15 * ui))
		btn.custom_minimum_size = Vector2(76 * ui, 76 * ui)

	var coin_size := 240.0 * ui
	_coin.custom_minimum_size = Vector2(coin_size, coin_size)
	_coin.size = Vector2(coin_size, coin_size)
	_layout_coin_buttons(coin_size)

	_pocket_btn.offset_left = -(safe.z + pad + 130 * ui)
	_pocket_btn.offset_right = -(safe.z + pad)
	_pocket_btn.offset_top = -(safe.w + pad + 48 * ui)
	_pocket_btn.offset_bottom = -(safe.w + pad)

	_pocket_panel.offset_left = -(safe.z + pad + 460 * ui)
	_pocket_panel.offset_right = -(safe.z + pad)
	_pocket_panel.offset_top = -(safe.w + pad + 48 * ui + 78 * ui)
	_pocket_panel.offset_bottom = -(safe.w + pad + 56 * ui)

	_intent.offset_left = safe.x + pad
	_intent.offset_right = -(safe.z + pad)
	_intent.offset_top = -(safe.w + pad + 48 * ui + 36 * ui)
	_intent.offset_bottom = -(safe.w + pad + 48 * ui + 4 * ui)

	refresh_inventory()

func _place_coin(screen_pos: Vector2) -> void:
	var vp := get_viewport().get_visible_rect().size
	var half := _coin.size * 0.5
	var pos := screen_pos - half
	pos.x = clampf(pos.x, 8.0, maxf(8.0, vp.x - _coin.size.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, vp.y - _coin.size.y - 120.0))
	_coin.position = pos

func _layout_coin_buttons(coin_size: float) -> void:
	# Full Throttle layout: Look top, Talk left, Use right, Take/Kick bottom.
	var btn_size := coin_size * 0.32
	var center := Vector2(coin_size * 0.5, coin_size * 0.5)
	var radius := coin_size * 0.28
	var placements := {
		Verb.OBSERVE: Vector2(0, -1),
		Verb.TALK: Vector2(-1, 0),
		Verb.USE: Vector2(1, 0),
		Verb.TAKE: Vector2(0, 1),
	}
	for verb in placements.keys():
		var btn: Button = _verb_buttons[verb]
		var dir: Vector2 = placements[verb]
		var c: Vector2 = center + dir * radius
		btn.position = c - Vector2(btn_size, btn_size) * 0.5
		btn.size = Vector2(btn_size, btn_size)
		btn.custom_minimum_size = Vector2(btn_size, btn_size)

func _on_verb_pressed(verb: Verb) -> void:
	var target := _get_coin_target()
	hide_verb_coin()
	if target == null or not is_instance_valid(target):
		return
	current_verb = verb
	verb_changed.emit()
	if target.has_method("apply_verb"):
		target.apply_verb(get_verb_id())
	elif target.has_method("run_verb_action"):
		target.run_verb_action(get_verb_id())

func _on_pocket_pressed() -> void:
	_set_pocket_open(not _pocket_open)

func _set_pocket_open(open: bool) -> void:
	_pocket_open = open
	if _pocket_panel:
		_pocket_panel.visible = open and is_gameplay_visible()
	_update_pocket_button()

func _update_pocket_button() -> void:
	if _pocket_btn == null:
		return
	_pocket_btn.text = "Bolso"
	_pocket_btn.modulate = COL_HOT if _pocket_open or Inventory.selected_item != "" else Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if not _coin_open:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_verb_coin()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		# Outside clicks are handled by player; swallow nothing here.
		pass

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_chrome = Control.new()
	_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_chrome)

	_intent = Label.new()
	_intent.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_intent.add_theme_font_override("font", UI_FONT)
	_intent.add_theme_color_override("font_color", COL_HOT)
	_intent.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_intent.add_theme_constant_override("shadow_offset_x", 2)
	_intent.add_theme_constant_override("shadow_offset_y", 2)
	_intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent.visible = false
	_chrome.add_child(_intent)

	_coin = Control.new()
	_coin.mouse_filter = Control.MOUSE_FILTER_STOP
	_coin.visible = false
	_chrome.add_child(_coin)

	_coin_disc = Panel.new()
	_coin_disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coin_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var disc := StyleBoxFlat.new()
	disc.bg_color = COL_METAL
	disc.border_color = COL_METAL_EDGE
	disc.set_border_width_all(3)
	disc.set_corner_radius_all(999)
	disc.shadow_color = Color(0, 0, 0, 0.55)
	disc.shadow_size = 10
	_coin_disc.add_theme_stylebox_override("panel", disc)
	_coin.add_child(_coin_disc)

	var hub := Panel.new()
	hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub.set_anchors_preset(Control.PRESET_CENTER)
	hub.custom_minimum_size = Vector2(36, 36)
	hub.offset_left = -18
	hub.offset_top = -18
	hub.offset_right = 18
	hub.offset_bottom = 18
	var hub_style := StyleBoxFlat.new()
	hub_style.bg_color = Color(0.08, 0.07, 0.06, 1)
	hub_style.border_color = COL_HOT
	hub_style.set_border_width_all(2)
	hub_style.set_corner_radius_all(999)
	hub.add_theme_stylebox_override("panel", hub_style)
	_coin.add_child(hub)

	_add_verb_button(Verb.OBSERVE, "Mirar", "◉")
	_add_verb_button(Verb.TALK, "Hablar", "◎")
	_add_verb_button(Verb.USE, "Usar", "✦")
	_add_verb_button(Verb.TAKE, "Tomar", "▣")

	_pocket_btn = Button.new()
	_pocket_btn.text = "Bolso"
	_pocket_btn.focus_mode = Control.FOCUS_NONE
	_pocket_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_pocket_btn.add_theme_font_override("font", UI_FONT)
	_pocket_btn.add_theme_color_override("font_color", COL_INK)
	_pocket_btn.add_theme_color_override("font_hover_color", COL_HOT)
	_style_metal_button(_pocket_btn)
	_pocket_btn.pressed.connect(_on_pocket_pressed)
	_chrome.add_child(_pocket_btn)

	_pocket_panel = PanelContainer.new()
	_pocket_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_pocket_panel.visible = false
	var pocket_style := StyleBoxFlat.new()
	pocket_style.bg_color = COL_METAL
	pocket_style.border_color = COL_METAL_EDGE
	pocket_style.set_border_width_all(2)
	pocket_style.set_corner_radius_all(8)
	pocket_style.content_margin_left = 10
	pocket_style.content_margin_right = 10
	pocket_style.content_margin_top = 10
	pocket_style.content_margin_bottom = 10
	pocket_style.shadow_color = Color(0, 0, 0, 0.4)
	pocket_style.shadow_size = 8
	_pocket_panel.add_theme_stylebox_override("panel", pocket_style)
	_chrome.add_child(_pocket_panel)

	_inv_box = HBoxContainer.new()
	_inv_box.add_theme_constant_override("separation", 8)
	_inv_box.alignment = BoxContainer.ALIGNMENT_END
	_pocket_panel.add_child(_inv_box)

func _style_metal_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.2, 0.18, 0.95)
	normal.border_color = COL_METAL_EDGE
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", normal)

func _add_verb_button(verb: Verb, text: String, glyph: String) -> void:
	var btn := Button.new()
	btn.text = "%s\n%s" % [glyph, text]
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", UI_FONT)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", COL_INK)
	btn.add_theme_color_override("font_hover_color", COL_HOT)
	btn.add_theme_color_override("font_disabled_color", COL_DIM)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.1, 0.92)
	style.border_color = COL_METAL_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.pressed.connect(_on_verb_pressed.bind(verb))
	_coin.add_child(btn)
	_verb_buttons[verb] = btn
