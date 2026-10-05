extends Interactable

## Always visible. Full collectable Take UX only while wearing the bear mask.

func _ready() -> void:
	use_verb_menu = true
	can_observe = true
	can_take = false
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
	interact_label = "Hacha"
	super._ready()
	# Scene used to hide this until briefing; hybrid design keeps it visible.
	visible = true
	input_pickable = true
	monitoring = true
	monitorable = true
	_refresh_take_state()
	StoryFlags.mask_equipped_changed.connect(_refresh_take_state)
	StoryFlags.paso_abierto_signal.connect(_refresh_take_state)
	Inventory.inventory_changed.connect(_refresh_take_state)

func _refresh_take_state() -> void:
	if StoryFlags.is_paso_abierto() or Inventory.is_collected("hacha"):
		can_take = false
		interact_label = "Tronco"
		return
	# Take verb available; success only while wearing oso (_do_take).
	can_take = true
	interact_label = "Hacha"

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
		interact_label = "Tronco"
	else:
		interact_label = "Hacha"
	return super.get_verb_text()
