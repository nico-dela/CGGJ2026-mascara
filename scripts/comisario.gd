extends NpcInteractable

func _ready() -> void:
	if dialogue == null:
		dialogue = load("res://dialogues/comisario.dialogue")
	super._ready()

func _interact() -> void:
	# Pick dialogue branch from story progress
	if StoryFlags.caso_resuelto:
		dialogue = load("res://dialogues/comisario_resolved.dialogue")
	elif StoryFlags.is_paso_abierto() or StoryFlags.has_seen_clue("oso"):
		dialogue = load("res://dialogues/comisario_clues.dialogue")
	else:
		dialogue = load("res://dialogues/comisario.dialogue")
	super._interact()
