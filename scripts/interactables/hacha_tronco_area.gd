extends Interactable

## Workplace clue after briefing. As lumberjack (oso), the axe can be taken to cut ivy.

func _ready() -> void:
	use_verb_menu = true
	can_observe = true
	can_take = true
	can_use = false
	dialogue_observe = load("res://content/dialogue/items/tronco_observe.dialogue")
	dialogue_take = load("res://content/dialogue/items/tronco_take.dialogue")
	dialogue_use = null
	item_to_give = "hacha"
	persist_id = "hacha"
	clue_id = "tronco"
	despawn_on_interact = false
	use_hover_feedback = false
	verb = "Examinar"
	interact_label = "el hacha"
	visible = false
	input_pickable = false
	super._ready()
	_apply_reveal()
	_refresh_take_state()
	if not StoryFlags.has_comisario_briefing():
		StoryFlags.comisario_briefing_signal.connect(_on_briefing)
	StoryFlags.mask_equipped_changed.connect(_refresh_take_state)
	StoryFlags.paso_abierto_signal.connect(_refresh_take_state)
	Inventory.inventory_changed.connect(_refresh_take_state)

func _apply_reveal() -> void:
	var revealed := StoryFlags.has_comisario_briefing()
	visible = revealed
	input_pickable = revealed
	monitoring = revealed
	monitorable = revealed
	_refresh_take_state()

func _on_briefing() -> void:
	_apply_reveal()

func _refresh_take_state() -> void:
	if StoryFlags.is_paso_abierto() or Inventory.is_collected("hacha"):
		can_take = false
		interact_label = "el tronco"
		return
	# Only the leñador (oso worn) can pull the axe free.
	can_take = StoryFlags.is_wearing_mask("oso")

func _do_take() -> void:
	if StoryFlags.is_paso_abierto() or Inventory.is_collected("hacha"):
		_arm_cooldown()
		_start_dialogue(load("res://content/dialogue/items/tronco_take_already.dialogue"), false, false)
		return
	if not StoryFlags.is_wearing_mask("oso"):
		_arm_cooldown()
		_start_dialogue(load("res://content/dialogue/items/tronco_take.dialogue"), false, false)
		return
	dialogue_take = load("res://content/dialogue/items/tronco_take_success.dialogue")
	item_to_give = "hacha"
	super._do_take()
	_refresh_take_state()

func get_verb_text() -> String:
	if StoryFlags.is_paso_abierto() or Inventory.is_collected("hacha"):
		interact_label = "el tronco"
	else:
		interact_label = "el hacha"
	return super.get_verb_text()
