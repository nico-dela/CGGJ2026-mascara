extends Interactable

func _ready() -> void:
	use_verb_menu = true
	can_observe = true
	can_take = true
	can_use = false
	dialogue_observe = load("res://content/dialogue/items/hiedra_observe.dialogue")
	dialogue_take = load("res://content/dialogue/items/hiedra_take.dialogue")
	dialogue_use = null
	dialogue_with_item = load("res://content/dialogue/items/hiedra_cut.dialogue")
	required_item = "hacha"
	item_to_give = ""
	require_paso_cerrado = true
	use_hover_feedback = false
	verb = "Examinar"
	interact_label = "Hiedra"
	interact_sound = load("res://assets/audio/sfx/rama.ogg")
	super._ready()

func get_verb_text() -> String:
	if Inventory.selected_item == "hacha":
		return tr("Usar %s con %s") % [Inventory.get_display_name("hacha"), get_interact_label()]
	return super.get_verb_text()

func get_verb_actions() -> Array:
	var actions: Array = []
	actions.append({"id": "observe", "text": tr("Observar"), "enabled": true})
	actions.append({"id": "take", "text": tr("Agarrar"), "enabled": true})
	return actions

func run_verb_action(action_id: String) -> void:
	if action_id == "take":
		_arm_cooldown()
		_start_dialogue(dialogue_take, false, false)
		return
	super.run_verb_action(action_id)
