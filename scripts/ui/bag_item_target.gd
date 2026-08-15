extends Node

## Proxy so the verb coin can Mirar/Usar items inside the Bolso.

var item_id := ""
var can_observe := true
var can_take := false
var can_use := true
var is_npc := false

func setup(id: String) -> void:
	item_id = id
	name = "BagItem_%s" % id

func get_interact_label() -> String:
	if item_id == "":
		return ""
	return Inventory.get_display_name(item_id)

func get_verb_text() -> String:
	var label := get_interact_label()
	if label == "":
		return ""
	return tr("Mirar %s") % label

func apply_verb(verb_id: String) -> void:
	match verb_id:
		"observe":
			_examine()
		"use":
			_use_from_bag()
		_:
			pass

func _examine() -> void:
	var path := "res://content/dialogue/items/inv_%s.dialogue" % item_id
	if not ResourceLoader.exists(path):
		path = "res://content/dialogue/system/generic_no_use.dialogue"
	var dialogue: Resource = load(path)
	if dialogue:
		DialogueManager.show_dialogue_balloon(dialogue, "start")

func _use_from_bag() -> void:
	var item := Inventory.get_item(item_id)
	if item != null and item.tipo == ItemResource.ItemTypes.MASCARA:
		if Inventory.selected_item == item_id:
			GameManager.toggle_equip_mask(item_id)
			Inventory.selected_item = ""
		else:
			Inventory.selected_item = item_id
			if AdventureUI:
				AdventureUI.set_verb(AdventureUI.Verb.USE)
		return
	if Inventory.selected_item == item_id:
		Inventory.selected_item = ""
	else:
		Inventory.selected_item = item_id
		if AdventureUI:
			AdventureUI.set_verb(AdventureUI.Verb.USE)
