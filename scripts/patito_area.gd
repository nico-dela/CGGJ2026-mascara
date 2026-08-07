extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/patito_found.dialogue")
	clue_id = "patito"
	hover_scale_multiplier = 1.125
	verb = "Mirar"
	interact_label = "el patito"
	interact_sound = load("res://audios/AMBIENTES Y SFX/FOLEYS FINALES/juguetePato.ogg")
	super._ready()
