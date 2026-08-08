extends NpcInteractable

@export var npc_mask_item: String = "mascara_mozo"

func _ready() -> void:
	if dialogue == null:
		dialogue = load("res://dialogues/bartender_no_info.dialogue")
	required_item = ""
	listen_mask_signals = true
	super._ready()

func get_verb_text() -> String:
	if Inventory.selected_item == "patito":
		return "Usar el patito con el cantinero"
	if Inventory.selected_item == "oso":
		return "Usar la máscara con el cantinero"
	if Inventory.selected_item == "mascara_mozo" and StoryFlags.cantinero_mascara:
		return "Devolverle su máscara"
	if Inventory.selected_item == "" and StoryFlags.is_wearing_mask("oso") and StoryFlags.has_huellas_pelota() and not StoryFlags.is_bartender_expuesto():
		return "Hablar con el cantinero (máscara puesta)"
	return super.get_verb_text()

func _interact() -> void:
	var selected := Inventory.selected_item

	if selected == "patito" and not StoryFlags.has_patito_devuelto():
		dialogue_with_item = load("res://dialogues/bartender_patito.dialogue")
		required_item = "patito"
		super._interact()
		required_item = ""
		return

	# Swap back: return bartender his mask, recover oso.
	if selected == "mascara_mozo" and StoryFlags.cantinero_mascara:
		_swap_back_from_npc()
		return

	# Put oso on bartender (swap).
	if selected == "oso" and not StoryFlags.is_bartender_expuesto():
		_swap_oso_onto_npc()
		return

	# Wearing stretch masks → short flavour lines.
	if selected == "" and StoryFlags.is_wearing_mask("mascara_mozo"):
		dialogue = load("res://dialogues/wear_mozo.dialogue")
		super._interact()
		return

	# Wearing oso + fingerprints → expose.
	if selected == "" and StoryFlags.is_wearing_mask("oso") and not StoryFlags.is_bartender_expuesto():
		dialogue = load("res://dialogues/bartender_confess.dialogue")
		super._interact()
		return

	dialogue = load("res://dialogues/bartender_no_info.dialogue")
	super._interact()

func _swap_oso_onto_npc() -> void:
	if not Inventory.has_item("oso"):
		return
	if StoryFlags.is_wearing_mask("oso"):
		StoryFlags.unequip_mask()
	GameManager.remove_item("oso")
	Inventory.selected_item = ""
	if npc_mask_item != "" and not Inventory.has_item(npc_mask_item):
		GameManager.add_item(npc_mask_item)
	StoryFlags.poner_mascara_cantinero()
	InteractionHint.hide_hint()
	DialogueManager.show_dialogue_balloon(load("res://dialogues/bartender_mask_swap.dialogue"), "start")

func _swap_back_from_npc() -> void:
	StoryFlags.quitar_mascara_cantinero()
	GameManager.remove_item("mascara_mozo")
	Inventory.selected_item = ""
	GameManager.add_item("oso")
	InteractionHint.hide_hint()
	DialogueManager.show_dialogue_balloon(load("res://dialogues/bartender_mask_return.dialogue"), "start")
