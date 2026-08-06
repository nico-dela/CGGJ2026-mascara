extends NpcInteractable

func _ready() -> void:
	if dialogue == null:
		dialogue = load("res://dialogues/bartender_no_info.dialogue")
	if dialogue_with_item == null:
		dialogue_with_item = load("res://dialogues/bartender_confess.dialogue")
	if required_item == "":
		required_item = "oso"
	listen_mask_signals = true
	super._ready()
