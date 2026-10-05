extends NpcInteractable

func _ready() -> void:
	if dialogue == null:
		dialogue = load("res://content/dialogue/bartender/bartender_no_info.dialogue")
	dialogue_observe = load("res://content/dialogue/bartender/bartender_observe.dialogue")
	required_item = ""
	super._ready()

func get_verb_text() -> String:
	if Inventory.selected_item == "patito":
		return tr("Usar %s con %s") % [Inventory.get_display_name("patito"), get_interact_label()]
	if Inventory.selected_item == "credencial":
		return tr("Usar %s con %s") % [Inventory.get_display_name("credencial"), get_interact_label()]
	if Inventory.selected_item == "" and StoryFlags.is_wearing_mask("oso") and StoryFlags.has_huellas_pelota() and not StoryFlags.is_bartender_expuesto():
		return tr("Hablar con Mozo (máscara puesta)")
	return super.get_verb_text()

func _interact() -> void:
	var selected := Inventory.selected_item

	if selected == "patito" and not StoryFlags.has_patito_devuelto():
		dialogue_with_item = load("res://content/dialogue/bartender/bartender_patito.dialogue")
		required_item = "patito"
		super._interact()
		required_item = ""
		return

	if selected == "credencial":
		dialogue_with_item = load("res://content/dialogue/bartender/bartender_credencial.dialogue")
		required_item = "credencial"
		super._interact()
		required_item = ""
		return

	# Wearing oso + fingerprints → expose (Talk, not item-use).
	if selected == "" and StoryFlags.is_wearing_mask("oso") and not StoryFlags.is_bartender_expuesto():
		dialogue = load("res://content/dialogue/bartender/bartender_confess.dialogue")
		super._interact()
		return

	dialogue = load("res://content/dialogue/bartender/bartender_no_info.dialogue")
	super._interact()
