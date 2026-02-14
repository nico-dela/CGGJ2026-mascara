extends Node

# ======================
# INVENTARIO
# ======================
var inventory := []
var selected_item := ""
var collected_items := []

signal inventoryChange

# ======================
# ESTADO DE JUEGO
# ======================
var cantinero_mascara := false

signal cantinero_mascara_puesta
signal cantinero_mascara_quitada

# ======================
# CONTROL DE PASOS / PUERTAS
# ======================
var paso_abierto := false
signal paso_abierto_signal

# ======================
# TRANSICIÓN
# ======================
var transition_audio: AudioStreamPlayer
var next_spawn_id: String = ""

func _ready():
	transition_audio = AudioStreamPlayer.new()
	add_child(transition_audio)

# ======================
# MÁSCARA DEL CANTINERO
# ======================
func poner_mascara_cantinero():
	cantinero_mascara = true
	cantinero_mascara_puesta.emit()

func quitar_mascara_cantinero():
	cantinero_mascara = false
	cantinero_mascara_quitada.emit()

# ======================
# INVENTARIO (ACTUAL)
# ======================
func add_item(item_id: String):
	if item_id not in inventory:
		inventory.append(item_id)
		inventoryChange.emit()

func remove_item(item_id: String):
	inventory.erase(item_id)
	inventoryChange.emit()

func has_item(item_id: String) -> bool:
	return item_id in inventory

# ======================
# OBJETOS RECOGIDOS (PERMANENTES)
# ======================
func mark_as_collected(item_id: String):
	if item_id not in collected_items:
		collected_items.append(item_id)

func is_collected(item_id: String) -> bool:
	return item_id in collected_items

# ======================
# PASOS / PUERTAS
# ======================
func abrir_paso():
	paso_abierto = true
	paso_abierto_signal.emit()
	print("¡Paso abierto!")

func cerrar_paso():
	paso_abierto = false

func is_paso_abierto() -> bool:
	return paso_abierto

# ======================
# CAMBIO DE ESCENA
# ======================
func request_scene_change(scene_path: String, spawn_id: String = "", sound: AudioStream = null):
	next_spawn_id = spawn_id

	if sound:
		transition_audio.stream = sound
		transition_audio.play()

	call_deferred("_do_change_scene", scene_path)

func _do_change_scene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)
