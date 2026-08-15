extends Area2D
class_name Interactable

@export var dialogue: Resource
@export var dialogue_observe: Resource
@export var dialogue_take: Resource
@export var dialogue_use: Resource
@export var dialogue_with_item: Resource
@export var dialogue_item_reject: Resource
@export var required_item: String = ""
@export var item_to_give: String = ""
@export var persist_id: String = ""
@export var clue_id: String = ""
@export var despawn_on_interact: bool = false
@export var require_paso_cerrado: bool = false
@export var hover_scale_multiplier: float = 1.05
@export var use_hover_feedback: bool = true
@export var interact_sound: AudioStream
@export var verb: String = "Mirar"
@export var interact_label: String = ""
## Legacy popup flag (AdventureUI replaces it). Kept for compatibility.
@export var use_verb_menu: bool = false
@export var can_observe: bool = true
@export var can_take: bool = false
## Only enable when in-place Use has a real effect (not a reject line).
@export var can_use: bool = false
@export var is_npc: bool = false

@onready var sprite: Node2D = get_node_or_null("Sprite2D")

var _base_scale: Vector2 = Vector2.ONE
var _interact_cooldown := false
var _hovered := false
var _default_reject: Resource = null

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")
	if sprite == null:
		sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		_base_scale = sprite.scale
	if persist_id != "" and Inventory.is_collected(persist_id):
		queue_free()
		return
	if require_paso_cerrado:
		StoryFlags.paso_abierto_signal.connect(_on_paso_abierto)
		if StoryFlags.is_paso_abierto():
			_on_paso_abierto()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	Inventory.selection_changed.connect(_on_selection_changed)
	if AdventureUI:
		AdventureUI.verb_changed.connect(_on_selection_changed)

func get_interact_label() -> String:
	if interact_label.is_empty():
		return ""
	return tr(interact_label)

## Called by the player click router (reliable on desktop + touch).
func try_interact() -> bool:
	if not visible or not input_pickable:
		return false
	if require_paso_cerrado and StoryFlags.is_paso_abierto():
		return false
	if VerbMenu and VerbMenu.is_open():
		VerbMenu.hide_menu()

	# Selected inventory item always means Use-with.
	if Inventory.selected_item != "":
		_interact_use_with()
		return true

	# Without an item, the player opens the verb coin instead.
	return false

## Full Throttle-style: apply a verb chosen from the action coin.
func apply_verb(verb_id: String) -> void:
	if not visible or not input_pickable:
		return
	if require_paso_cerrado and StoryFlags.is_paso_abierto():
		return
	match verb_id:
		"talk":
			if is_npc:
				_interact_default()
			else:
				_arm_cooldown()
				_start_reject_dialogue()
		"take":
			if can_take and item_to_give != "":
				_do_take()
			elif use_verb_menu or can_take:
				_do_take()
			else:
				_arm_cooldown()
				_start_reject_dialogue()
		"use":
			_do_use_inplace()
		_:
			if is_npc:
				_interact_default()
			else:
				_do_observe()

func get_verb_text() -> String:
	if Inventory.selected_item != "":
		var item_name := Inventory.get_display_name(Inventory.selected_item)
		if interact_label.is_empty():
			return tr("Usar %s") % item_name
		return tr("Usar %s con %s") % [item_name, get_interact_label()]
	if AdventureUI and AdventureUI.is_gameplay_visible():
		var built := AdventureUI.build_sentence_for(self)
		if built != "":
			return built
	if interact_label.is_empty():
		return tr(verb)
	return "%s %s" % [tr(verb), get_interact_label()]

func get_verb_actions() -> Array:
	# Kept for VerbMenu fallback; AdventureUI does not use this.
	var actions: Array = []
	if can_observe:
		actions.append({"id": "observe", "text": tr("Observar"), "enabled": true})
	if can_take:
		var taken := persist_id != "" and Inventory.is_collected(persist_id)
		actions.append({"id": "take", "text": tr("Agarrar"), "enabled": not taken and item_to_give != ""})
	if can_use:
		actions.append({"id": "use", "text": tr("Usar"), "enabled": true})
	return actions

func run_verb_action(action_id: String) -> void:
	apply_verb(action_id)

func _say_or_reject(_line: String) -> void:
	_arm_cooldown()
	_start_reject_dialogue()

func _interact_default() -> void:
	if _interact_cooldown:
		return
	_arm_cooldown()
	_interact()

## Override in NPCs for branching talk / item logic.
func _interact() -> void:
	if Inventory.selected_item != "":
		if _should_use_item_dialogue():
			_start_dialogue(dialogue_with_item, true, false)
		else:
			_start_reject_dialogue()
		return
	_start_dialogue(_resolve_default_dialogue(), false, false)

func _interact_use_with() -> void:
	if _interact_cooldown:
		return
	_arm_cooldown()
	if _should_use_item_dialogue():
		_start_dialogue(dialogue_with_item, true, false)
	else:
		_start_reject_dialogue()

func _do_observe() -> void:
	if _interact_cooldown:
		return
	_arm_cooldown()
	var res: Resource = dialogue_observe if dialogue_observe != null else dialogue
	_start_dialogue(res, false, false)

func _do_take() -> void:
	if _interact_cooldown:
		return
	# Non-pickable props still use take dialogue as explanation.
	if item_to_give == "":
		_arm_cooldown()
		var res_fail: Resource = dialogue_take if dialogue_take != null else dialogue_use
		if res_fail != null:
			_start_dialogue(res_fail, false, false)
		else:
			_start_reject_dialogue()
		return
	# Need the road bag before storing anything in inventory.
	if not StoryFlags.has_tiene_bolso():
		_arm_cooldown()
		_start_dialogue(load("res://content/dialogue/system/need_bag.dialogue"), false, false)
		return
	if persist_id != "" and Inventory.is_collected(persist_id):
		return
	_arm_cooldown()
	var res: Resource = dialogue_take if dialogue_take != null else dialogue
	_start_dialogue(res, false, true)

func _do_use_inplace() -> void:
	if _interact_cooldown:
		return
	_arm_cooldown()
	if dialogue_use != null:
		_start_dialogue(dialogue_use, false, false)
	else:
		_start_reject_dialogue()

func _arm_cooldown() -> void:
	_interact_cooldown = true
	get_tree().create_timer(0.25).timeout.connect(func(): _interact_cooldown = false)

func _resolve_default_dialogue() -> Resource:
	if dialogue != null:
		return dialogue
	return dialogue_observe

func _start_reject_dialogue() -> void:
	var resource: Resource = dialogue_item_reject
	if resource == null:
		if _default_reject == null:
			_default_reject = load("res://content/dialogue/system/generic_no_use.dialogue")
		resource = _default_reject
	InteractionHint.hide_hint()
	if AdventureUI:
		AdventureUI.refresh_sentence(null)
	DialogueManager.show_dialogue_balloon(resource, "start")

func _start_dialogue(resource: Resource, used_item: bool, do_take: bool) -> void:
	if interact_sound and AudioManager:
		AudioManager.play_sfx(interact_sound)

	if clue_id != "":
		GameManager.mark_clue_seen(clue_id)

	if resource == null:
		push_warning("%s: no dialogue resource assigned" % name)
		return

	if do_take:
		if persist_id != "":
			GameManager.mark_as_collected(persist_id)
		if item_to_give != "":
			GameManager.add_item(item_to_give)

	if used_item:
		Inventory.selected_item = ""

	InteractionHint.hide_hint()
	if AdventureUI:
		AdventureUI.refresh_sentence(null)
	DialogueManager.show_dialogue_balloon(resource, "start")

	if do_take and despawn_on_interact:
		queue_free()

func _should_use_item_dialogue() -> bool:
	if required_item == "" or dialogue_with_item == null:
		return false
	if not Inventory.has_item(required_item):
		return false
	return Inventory.selected_item == required_item

func _on_paso_abierto() -> void:
	visible = false
	monitoring = false
	monitorable = false
	input_pickable = false
	collision_layer = 0
	collision_mask = 0
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).disabled = true
		elif child is CollisionPolygon2D:
			(child as CollisionPolygon2D).disabled = true
	InteractionHint.hide_hint()
	# Remove from picking so clicks fall through to walk / other hotspots.
	queue_free()

func _on_selection_changed() -> void:
	if not _hovered or not visible or not input_pickable:
		return
	if require_paso_cerrado and StoryFlags.is_paso_abierto():
		return
	_show_hover_feedback()

func _on_mouse_entered() -> void:
	if not visible or not input_pickable:
		return
	if require_paso_cerrado and StoryFlags.is_paso_abierto():
		return
	_hovered = true
	_show_hover_feedback()
	if use_hover_feedback and sprite:
		sprite.scale = _base_scale * hover_scale_multiplier
		sprite.modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited() -> void:
	_hovered = false
	InteractionHint.hide_hint_from(self)
	if AdventureUI:
		AdventureUI.refresh_sentence(null)
	if use_hover_feedback and sprite:
		sprite.scale = _base_scale
		sprite.modulate = Color.WHITE

func _show_hover_feedback() -> void:
	if AdventureUI and AdventureUI.is_gameplay_visible():
		AdventureUI.refresh_sentence(self)
		# Still show a light cursor hint mirroring the sentence.
		InteractionHint.show_hint(AdventureUI.build_sentence_for(self), self)
	else:
		InteractionHint.show_hint(get_verb_text(), self)
