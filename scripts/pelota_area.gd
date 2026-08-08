extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/pelota_found.dialogue")
	item_to_give = "pelota"
	persist_id = "pelota"
	clue_id = "pelota"
	despawn_on_interact = true
	verb = "Recoger"
	interact_label = "la pelota"
	hover_scale_multiplier = 1.125
	interact_sound = load("res://audios/AMBIENTES Y SFX/FOLEYS FINALES/juguetePelota.ogg")
	super._ready()
