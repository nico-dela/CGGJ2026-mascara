extends Node

signal inventoryChange

var selected_item := ""
var inventory := []
var collected_items := []  # NUEVO

func add_item(item_id: String):
	if not item_id in inventory:
		inventory.append(item_id)
		inventoryChange.emit()

# NUEVAS FUNCIONES
func mark_as_collected(item_id: String):
	if not item_id in collected_items:
		collected_items.append(item_id)

func is_collected(item_id: String) -> bool:
	return item_id in collected_items

func remove_item(item_id: String):
	if item_id in inventory:
		inventory.erase(item_id)
		inventoryChange.emit()
