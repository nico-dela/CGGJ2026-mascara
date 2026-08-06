extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/pelota_found.dialogue")
	clue_id = "pelota"
	hover_scale_multiplier = 1.125
	interact_sound = load("res://audios/AMBIENTES Y SFX/FOLEYS FINALES/juguetePelota.ogg")
	super._ready()
