extends Interactable

## Evidence pickup — only after the comisario asks for something that proves the case.

func _ready() -> void:
	use_verb_menu = true
	can_observe = true
	can_take = true
	can_use = false
	dialogue_observe = load("res://content/dialogue/items/pelota_observe.dialogue")
	dialogue_take = load("res://content/dialogue/items/pelota_take.dialogue")
	dialogue_use = null
	item_to_give = "pelota"
	persist_id = "pelota"
	clue_id = "pelota"
	despawn_on_interact = true
	verb = "Examinar"
	interact_label = "Pelota"
	hover_scale_multiplier = 1.125
	interact_sound = load("res://assets/audio/sfx/juguete_pelota.ogg")
	visible = false
	input_pickable = false
	super._ready()
	_apply_reveal()
	if not StoryFlags.has_comisario_briefing():
		StoryFlags.comisario_briefing_signal.connect(_on_briefing)

func _apply_reveal() -> void:
	if Inventory.is_collected("pelota"):
		return
	var revealed := StoryFlags.has_comisario_briefing()
	visible = revealed
	input_pickable = revealed
	monitoring = revealed
	monitorable = revealed

func _on_briefing() -> void:
	_apply_reveal()
