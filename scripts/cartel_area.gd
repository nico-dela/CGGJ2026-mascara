extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/cartel_town.dialogue")
	clue_id = "cartel"
	verb = "Mirar"
	interact_label = "el cartel"
	use_hover_feedback = true
	super._ready()
