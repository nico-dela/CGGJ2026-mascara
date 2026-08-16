extends Node

signal inventory_changed
## Kept for GameManager facade / legacy listeners
signal inventoryChange
signal selection_changed

var inventory: Array[String] = []
var collected_items: Array[String] = []

var _selected_item: String = ""
var selected_item: String:
	get:
		return _selected_item
	set(value):
		if _selected_item == value:
			return
		_selected_item = value
		selection_changed.emit()

var _items: Dictionary = {}  # id -> ItemResource

func _ready() -> void:
	_load_item_library()

func _load_item_library() -> void:
	var dir := DirAccess.open("res://content/items")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var clean := file_name.replace(".remap", "")
			if clean.ends_with(".tres"):
				var item: ItemResource = load("res://content/items/" + clean) as ItemResource
				if item and item.itemId != "":
					_items[item.itemId] = item
		file_name = dir.get_next()
	dir.list_dir_end()

func get_item(item_id: String) -> ItemResource:
	return _items.get(item_id) as ItemResource

func get_texture(item_id: String) -> Texture2D:
	var item := get_item(item_id)
	if item and item.imagem:
		return item.imagem
	return null

func get_display_name(item_id: String) -> String:
	var item := get_item(item_id)
	if item and item.display_name != "":
		return tr(item.display_name)
	return item_id

func add_item(item_id: String) -> void:
	if item_id not in inventory:
		inventory.append(item_id)
		_emit_change()

func remove_item(item_id: String) -> void:
	if item_id in inventory:
		inventory.erase(item_id)
		if _selected_item == item_id:
			selected_item = ""
		_emit_change()

func has_item(item_id: String) -> bool:
	return item_id in inventory

func mark_as_collected(item_id: String) -> void:
	if item_id not in collected_items:
		collected_items.append(item_id)

func is_collected(item_id: String) -> bool:
	return item_id in collected_items

func clear() -> void:
	inventory.clear()
	selected_item = ""
	collected_items.clear()
	_emit_change()

func to_dict() -> Dictionary:
	return {
		"inventory": inventory.duplicate(),
		"selected_item": _selected_item,
		"collected_items": collected_items.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	inventory.clear()
	for id in data.get("inventory", []):
		inventory.append(str(id))
	collected_items.clear()
	for id in data.get("collected_items", []):
		collected_items.append(str(id))
	selected_item = str(data.get("selected_item", ""))
	_emit_change()

func _emit_change() -> void:
	inventory_changed.emit()
	inventoryChange.emit()
