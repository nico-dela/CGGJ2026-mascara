extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/patito_found.dialogue")
	item_to_give = "patito"
	persist_id = "patito"
	clue_id = "patito"
	despawn_on_interact = true
	verb = "Recoger"
	interact_label = "el patito"
	hover_scale_multiplier = 1.125
	interact_sound = load("res://audios/AMBIENTES Y SFX/FOLEYS FINALES/juguetePato.ogg")
	super._ready()
