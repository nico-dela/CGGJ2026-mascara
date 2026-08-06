extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/tronco_found.dialogue")
	clue_id = "tronco"
	use_hover_feedback = false
	super._ready()
