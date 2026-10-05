extends NpcInteractable

func _ready() -> void:
	if dialogue == null:
		dialogue = load("res://content/dialogue/comisario/comisario.dialogue")
	dialogue_observe = load("res://content/dialogue/comisario/comisario_observe.dialogue")
	super._ready()

func get_verb_text() -> String:
	if Inventory.selected_item == "pelota" and not StoryFlags.has_huellas_pelota():
		return tr("Usar %s con %s") % [Inventory.get_display_name("pelota"), get_interact_label()]
	if Inventory.selected_item == "credencial":
		return tr("Usar %s con %s") % [Inventory.get_display_name("credencial"), get_interact_label()]
	return super.get_verb_text()

func _interact() -> void:
	var selected := Inventory.selected_item

	if selected == "pelota" and not StoryFlags.has_huellas_pelota():
		dialogue_with_item = load("res://content/dialogue/comisario/comisario_pelota.dialogue")
		required_item = "pelota"
		super._interact()
		required_item = ""
		return

	if selected == "credencial":
		dialogue_with_item = load("res://content/dialogue/comisario/comisario_credencial.dialogue")
		required_item = "credencial"
		super._interact()
		required_item = ""
		return

	if StoryFlags.caso_resuelto:
		dialogue = load("res://content/dialogue/comisario/comisario_resolved.dialogue")
	elif StoryFlags.has_comisario_briefing() and (
		StoryFlags.has_huellas_pelota() or StoryFlags.clue_count() > 0 or StoryFlags.has_hablado_cantinero()
	):
		dialogue = load("res://content/dialogue/comisario/comisario_clues.dialogue")
	else:
		dialogue = load("res://content/dialogue/comisario/comisario.dialogue")
	super._interact()
