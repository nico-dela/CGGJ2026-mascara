extends NpcInteractable

## Vendedor de ruta — distinto del comisario de la comisaría.
@export var npc_mask_item: String = "mascara_vendedor"

func _ready() -> void:
	verb = "Hablar con"
	interact_label = "Vendedor"
	dialogue = load("res://content/dialogue/road/road_police.dialogue")
	dialogue_observe = load("res://content/dialogue/road/road_police_observe.dialogue")
	visual_oso_flag = "vendedor_tiene_oso"
	super._ready()

func get_verb_text() -> String:
	if Inventory.selected_item == "credencial":
		return tr("Usar %s con %s") % [Inventory.get_display_name("credencial"), get_interact_label()]
	if Inventory.selected_item == "oso":
		return tr("Usar %s con %s") % [Inventory.get_display_name("oso"), get_interact_label()]
	if Inventory.selected_item == "mascara_vendedor" and StoryFlags.vendedor_tiene_oso:
		return tr("Devolverle su máscara")
	return super.get_verb_text()

func _interact() -> void:
	var selected := Inventory.selected_item

	if selected == "credencial":
		dialogue_with_item = load("res://content/dialogue/road/road_police_credencial.dialogue")
		required_item = "credencial"
		super._interact()
		required_item = ""
		return

	if selected == "mascara_vendedor" and StoryFlags.vendedor_tiene_oso:
		_swap_back_from_npc()
		return

	if selected == "oso":
		_swap_oso_onto_npc()
		return

	if selected == "" and StoryFlags.is_wearing_mask("mascara_vendedor"):
		dialogue = load("res://content/dialogue/system/wear_vendedor.dialogue")
		super._interact()
		return

	dialogue = load("res://content/dialogue/road/road_police.dialogue")
	super._interact()

func _swap_oso_onto_npc() -> void:
	if not Inventory.has_item("oso"):
		return
	if StoryFlags.is_wearing_mask("oso"):
		StoryFlags.unequip_mask()
	GameManager.remove_item("oso")
	Inventory.selected_item = ""
	StoryFlags.set_vendedor_tiene_oso(true)
	if npc_mask_item != "" and not Inventory.has_item(npc_mask_item):
		GameManager.add_item(npc_mask_item)
	GameManager.save_game()
	InteractionHint.hide_hint()
	DialogueManager.show_dialogue_balloon(load("res://content/dialogue/road/road_vendedor_mask_swap.dialogue"), "start")

func _swap_back_from_npc() -> void:
	StoryFlags.set_vendedor_tiene_oso(false)
	GameManager.remove_item("mascara_vendedor")
	Inventory.selected_item = ""
	GameManager.add_item("oso")
	GameManager.save_game()
	InteractionHint.hide_hint()
	DialogueManager.show_dialogue_balloon(load("res://content/dialogue/road/road_vendedor_mask_return.dialogue"), "start")
