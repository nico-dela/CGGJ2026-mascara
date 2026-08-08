extends NpcInteractable

@export var npc_mask_item: String = "mascara_poli"

func _ready() -> void:
	if dialogue == null:
		dialogue = load("res://dialogues/comisario.dialogue")
	super._ready()

func get_verb_text() -> String:
	if Inventory.selected_item == "pelota" and not StoryFlags.has_huellas_pelota():
		return "Usar la pelota con el policía"
	if Inventory.selected_item == "oso":
		return "Usar la máscara con el policía"
	if Inventory.selected_item == "mascara_poli" and StoryFlags.comisario_tiene_oso:
		return "Devolverle su máscara"
	return super.get_verb_text()

func _interact() -> void:
	var selected := Inventory.selected_item

	if selected == "pelota" and not StoryFlags.has_huellas_pelota():
		dialogue_with_item = load("res://dialogues/comisario_pelota.dialogue")
		required_item = "pelota"
		super._interact()
		required_item = ""
		return

	if selected == "mascara_poli" and StoryFlags.comisario_tiene_oso:
		_swap_back_from_npc()
		return

	if selected == "oso":
		_swap_oso_onto_npc()
		return

	if selected == "" and StoryFlags.is_wearing_mask("mascara_poli"):
		dialogue = load("res://dialogues/wear_poli.dialogue")
		super._interact()
		return

	if StoryFlags.caso_resuelto:
		dialogue = load("res://dialogues/comisario_resolved.dialogue")
	elif StoryFlags.has_huellas_pelota() or StoryFlags.clue_count() > 0 or StoryFlags.has_hablado_cantinero():
		dialogue = load("res://dialogues/comisario_clues.dialogue")
	else:
		dialogue = load("res://dialogues/comisario.dialogue")
	super._interact()

func _swap_oso_onto_npc() -> void:
	if not Inventory.has_item("oso"):
		return
	if StoryFlags.is_wearing_mask("oso"):
		StoryFlags.unequip_mask()
	GameManager.remove_item("oso")
	Inventory.selected_item = ""
	StoryFlags.comisario_tiene_oso = true
	if npc_mask_item != "" and not Inventory.has_item(npc_mask_item):
		GameManager.add_item(npc_mask_item)
	GameManager.save_game()
	InteractionHint.hide_hint()
	DialogueManager.show_dialogue_balloon(load("res://dialogues/comisario_mask_swap.dialogue"), "start")

func _swap_back_from_npc() -> void:
	StoryFlags.comisario_tiene_oso = false
	GameManager.remove_item("mascara_poli")
	Inventory.selected_item = ""
	GameManager.add_item("oso")
	GameManager.save_game()
	InteractionHint.hide_hint()
	DialogueManager.show_dialogue_balloon(load("res://dialogues/comisario_mask_return.dialogue"), "start")
