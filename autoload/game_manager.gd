extends Node
## Thin facade over Inventory, StoryFlags and SceneRouter.
## Dialogue mutations keep calling GameManager.* for compatibility.

signal inventoryChange
signal cantinero_mascara_puesta
signal cantinero_mascara_quitada
signal paso_abierto_signal
signal caso_resuelto_signal
signal mask_equipped_changed

const SAVE_PATH := "user://save.json"

var _pending_credits := false
var _pending_town := false

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
	StoryFlags.mask_equipped_changed.connect(func(): mask_equipped_changed.emit())
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func add_item(item_id: String) -> void:
	Inventory.add_item(item_id)
	save_game()

func remove_item(item_id: String) -> void:
	if StoryFlags.mascara_equipada == item_id:
		StoryFlags.unequip_mask()
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

func equip_mask(mask_id: String) -> void:
	StoryFlags.equip_mask(mask_id)
	Inventory.selected_item = ""
	save_game()

func unequip_mask() -> void:
	StoryFlags.unequip_mask()
	save_game()

func toggle_equip_mask(mask_id: String) -> void:
	StoryFlags.toggle_equip_mask(mask_id)
	Inventory.selected_item = ""
	save_game()

func is_wearing_mask(mask_id: String = "") -> bool:
	return StoryFlags.is_wearing_mask(mask_id)

func mark_huellas_pelota() -> void:
	StoryFlags.mark_huellas_pelota()
	if has_item("pelota"):
		remove_item("pelota")
	save_game()

func has_huellas_pelota() -> bool:
	return StoryFlags.has_huellas_pelota()

func mark_patito_devuelto() -> void:
	StoryFlags.mark_patito_devuelto()
	if has_item("patito"):
		remove_item("patito")
	save_game()

func has_patito_devuelto() -> bool:
	return StoryFlags.has_patito_devuelto()

func exponer_bartender() -> void:
	StoryFlags.exponer_bartender()
	save_game()

func is_bartender_expuesto() -> bool:
	return StoryFlags.is_bartender_expuesto()

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

func mark_hablado_cantinero() -> void:
	StoryFlags.mark_hablado_cantinero()
	save_game()

func has_hablado_cantinero() -> bool:
	return StoryFlags.has_hablado_cantinero()

func mark_hablado_guardia() -> void:
	StoryFlags.mark_hablado_guardia()
	save_game()

func has_hablado_guardia() -> bool:
	return StoryFlags.has_hablado_guardia()

func mark_tiene_bolso() -> void:
	StoryFlags.mark_tiene_bolso()
	save_game()

func has_tiene_bolso() -> bool:
	return StoryFlags.has_tiene_bolso()

func mark_comisario_briefing() -> void:
	StoryFlags.mark_comisario_briefing()
	save_game()

func has_comisario_briefing() -> bool:
	return StoryFlags.has_comisario_briefing()

func resolver_caso() -> void:
	StoryFlags.resolver_caso()
	save_game()

## Call from the closing pescador dialogue so credits start after it ends.
func finalizar_juego() -> void:
	_pending_credits = true
	# Backup if dialogue_ended doesn't fire (e.g. balloon edge cases).
	get_tree().create_timer(1.0).timeout.connect(_go_to_credits_when_ready)

func request_scene_change(scene_path: String, spawn_id: String = "", sound: AudioStream = null) -> void:
	SceneRouter.request_scene_change(scene_path, spawn_id, sound)

func go_to_town() -> void:
	_pending_town = true

func start_new_game() -> void:
	_pending_credits = false
	_pending_town = false
	Inventory.clear()
	StoryFlags.reset()
	clear_save()
	SceneRouter.change_scene("res://scenes/systems/cinematic.tscn")

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
	# Saves from before the credential item: bag already taken → grant ID.
	if StoryFlags.has_tiene_bolso() and not Inventory.has_item("credencial"):
		Inventory.add_item("credencial")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.open("user://").remove("save.json")

func _on_dialogue_ended(_resource) -> void:
	if _pending_town:
		_pending_town = false
		request_scene_change("res://scenes/rooms/room_1.tscn", "Spawn_From_Road")
		return
	_go_to_credits_when_ready()

func _go_to_credits_when_ready() -> void:
	if not _pending_credits:
		return
	_pending_credits = false
	await get_tree().process_frame
	clear_save()
	SceneRouter.change_scene("res://scenes/ui/credits.tscn")
