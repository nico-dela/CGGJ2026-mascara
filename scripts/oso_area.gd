extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/oso_mask_found.dialogue")
	item_to_give = "oso"
	persist_id = "oso"
	clue_id = "oso"
	despawn_on_interact = true
	verb = "Recoger"
	interact_label = "la máscara"
	interact_sound = load("res://audios/AMBIENTES Y SFX/FOLEYS FINALES/mascaraOso.ogg")
	super._ready()
