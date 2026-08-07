extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/tronco_found.dialogue")
	clue_id = "tronco"
	use_hover_feedback = false
	verb = "Mirar"
	interact_label = "el tronco"
	super._ready()
