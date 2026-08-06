extends Node
## Thin facade over Inventory, StoryFlags and SceneRouter.
## Dialogue mutations keep calling GameManager.* for compatibility.

signal inventoryChange
signal cantinero_mascara_puesta
signal cantinero_mascara_quitada
signal paso_abierto_signal
signal caso_resuelto_signal

const SAVE_PATH := "user://save.json"

var _pending_credits := false

var inventory: Array:
	get:
		return Inventory.inventory
	set(value):
		Inventory.from_dict({"inventory": value, "selected_item": Inventory.selected_item, "collected_items": Inventory.collected_items})

var selected_item: String:
	get:
		return Inventory.selected_item
	set(value):
		Inventory.selected_item = value

var collected_items: Array:
	get:
		return Inventory.collected_items
	set(value):
		Inventory.from_dict({"inventory": Inventory.inventory, "selected_item": Inventory.selected_item, "collected_items": value})

var cantinero_mascara: bool:
	get:
		return StoryFlags.cantinero_mascara
	set(value):
		StoryFlags.cantinero_mascara = value

var paso_abierto: bool:
	get:
		return StoryFlags.paso_abierto
	set(value):
		StoryFlags.paso_abierto = value

var caso_resuelto: bool:
	get:
		return StoryFlags.caso_resuelto
	set(value):
		StoryFlags.caso_resuelto = value

var next_spawn_id: String:
	get:
		return SceneRouter.next_spawn_id
	set(value):
		SceneRouter.next_spawn_id = value

func _ready() -> void:
	Inventory.inventoryChange.connect(func(): inventoryChange.emit())
	StoryFlags.cantinero_mascara_puesta.connect(func(): cantinero_mascara_puesta.emit())
	StoryFlags.cantinero_mascara_quitada.connect(func(): cantinero_mascara_quitada.emit())
	StoryFlags.paso_abierto_signal.connect(func(): paso_abierto_signal.emit())
	StoryFlags.caso_resuelto_signal.connect(func(): caso_resuelto_signal.emit())
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func add_item(item_id: String) -> void:
	Inventory.add_item(item_id)
	save_game()

func remove_item(item_id: String) -> void:
	Inventory.remove_item(item_id)
	save_game()

func has_item(item_id: String) -> bool:
	return Inventory.has_item(item_id)

func mark_as_collected(item_id: String) -> void:
	Inventory.mark_as_collected(item_id)
	save_game()

func is_collected(item_id: String) -> bool:
	return Inventory.is_collected(item_id)

func poner_mascara_cantinero() -> void:
	StoryFlags.poner_mascara_cantinero()

func quitar_mascara_cantinero() -> void:
	StoryFlags.quitar_mascara_cantinero()

func abrir_paso() -> void:
	StoryFlags.abrir_paso()
	save_game()

func cerrar_paso() -> void:
	StoryFlags.cerrar_paso()

func is_paso_abierto() -> bool:
	return StoryFlags.is_paso_abierto()

func mark_clue_seen(clue_id: String) -> void:
	StoryFlags.mark_clue_seen(clue_id)
	save_game()

func has_seen_clue(clue_id: String) -> bool:
	return StoryFlags.has_seen_clue(clue_id)

func clue_count() -> int:
	return StoryFlags.clue_count()

func resolver_caso() -> void:
	StoryFlags.resolver_caso()
	_pending_credits = true
	save_game()
	# Backup if dialogue_ended doesn't fire (e.g. balloon edge cases).
	get_tree().create_timer(1.0).timeout.connect(_go_to_credits_when_ready)

func request_scene_change(scene_path: String, spawn_id: String = "", sound: AudioStream = null) -> void:
	SceneRouter.request_scene_change(scene_path, spawn_id, sound)

func start_new_game() -> void:
	_pending_credits = false
	Inventory.clear()
	StoryFlags.reset()
	clear_save()
	SceneRouter.change_scene("res://scenes/cinematic.tscn")

func save_game() -> void:
	var data := {
		"inventory": Inventory.to_dict(),
		"flags": StoryFlags.to_dict(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	Inventory.from_dict(data.get("inventory", {}))
	StoryFlags.from_dict(data.get("flags", {}))
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.open("user://").remove("save.json")

func _on_dialogue_ended(_resource) -> void:
	_go_to_credits_when_ready()

func _go_to_credits_when_ready() -> void:
	if not _pending_credits:
		return
	_pending_credits = false
	await get_tree().process_frame
	clear_save()
	SceneRouter.change_scene("res://scenes/credits.tscn")
