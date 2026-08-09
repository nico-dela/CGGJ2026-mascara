extends Interactable

func _ready() -> void:
	use_verb_menu = true
	can_observe = true
	can_take = false
	can_use = false
	dialogue_observe = load("res://content/dialogue/items/cartel_town.dialogue")
	dialogue_use = null
	dialogue = dialogue_observe
	clue_id = "cartel"
	verb = "Mirar"
	interact_label = "el cartel"
	use_hover_feedback = true
	super._ready()
