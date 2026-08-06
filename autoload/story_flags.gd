extends Node

signal cantinero_mascara_puesta
signal cantinero_mascara_quitada
signal paso_abierto_signal
signal caso_resuelto_signal
signal clues_changed

var cantinero_mascara := false
var paso_abierto := false
var caso_resuelto := false
## Clue ids the player has inspected (patito, pelota, tronco, oso, etc.)
var clues_seen: Array[String] = []

func poner_mascara_cantinero() -> void:
	cantinero_mascara = true
	if AudioManager:
		var sfx: AudioStream = load("res://audios/AMBIENTES Y SFX/FOLEYS FINALES/mascaraTaberna.ogg")
		AudioManager.play_sfx(sfx)
	cantinero_mascara_puesta.emit()

func quitar_mascara_cantinero() -> void:
	cantinero_mascara = false
	cantinero_mascara_quitada.emit()

func abrir_paso() -> void:
	paso_abierto = true
	paso_abierto_signal.emit()

func cerrar_paso() -> void:
	paso_abierto = false

func is_paso_abierto() -> bool:
	return paso_abierto

func mark_clue_seen(clue_id: String) -> void:
	if clue_id == "" or clue_id in clues_seen:
		return
	clues_seen.append(clue_id)
	clues_changed.emit()

func has_seen_clue(clue_id: String) -> bool:
	return clue_id in clues_seen

func clue_count() -> int:
	return clues_seen.size()

func resolver_caso() -> void:
	caso_resuelto = true
	caso_resuelto_signal.emit()

func reset() -> void:
	cantinero_mascara = false
	paso_abierto = false
	caso_resuelto = false
	clues_seen.clear()
	clues_changed.emit()

func to_dict() -> Dictionary:
	return {
		"cantinero_mascara": cantinero_mascara,
		"paso_abierto": paso_abierto,
		"caso_resuelto": caso_resuelto,
		"clues_seen": clues_seen.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	cantinero_mascara = bool(data.get("cantinero_mascara", false))
	paso_abierto = bool(data.get("paso_abierto", false))
	caso_resuelto = bool(data.get("caso_resuelto", false))
	clues_seen.clear()
	for id in data.get("clues_seen", []):
		clues_seen.append(str(id))
	clues_changed.emit()
	if paso_abierto:
		paso_abierto_signal.emit()
