extends NpcInteractable

func _ready() -> void:
	verb = "Hablar con"
	interact_label = "el pescador"
	anim_idle = "idle"
	anim_talk = "talk"
	if dialogue == null:
		dialogue = load("res://dialogues/pescador.dialogue")
	super._ready()

func _interact() -> void:
	if StoryFlags.caso_resuelto:
		dialogue = load("res://dialogues/pescador_ending.dialogue")
	else:
		dialogue = load("res://dialogues/pescador.dialogue")
	super._interact()
