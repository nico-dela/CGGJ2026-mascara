extends Node

signal cantinero_mascara_puesta
signal cantinero_mascara_quitada
signal paso_abierto_signal
signal caso_resuelto_signal
signal clues_changed
signal mask_equipped_changed
signal bartender_expuesto_signal
signal huellas_changed
signal patito_devuelto_signal
signal hablado_guardia_signal
signal tiene_bolso_signal
signal comisario_briefing_signal
signal hablado_cantinero_signal

var cantinero_mascara := false
var paso_abierto := false
var caso_resuelto := false
var hablado_cantinero := false
var huellas_pelota := false
var patito_devuelto := false
var bartender_expuesto := false
var hablado_guardia := false
## World bag collected — enables Bolso HUD / taking items (not an inventory slot).
var tiene_bolso := false
## Comisario asked for help / case briefing done.
var comisario_briefing := false
## Mask id currently worn by the detective (e.g. "oso"), or "".
var mascara_equipada := ""
## True while the police is holding the oso mask from a swap.
var comisario_tiene_oso := false
## Clue ids the player has inspected (patito, pelota, tronco, oso, etc.)
var clues_seen: Array[String] = []

func poner_mascara_cantinero() -> void:
	cantinero_mascara = true
	if AudioManager:
		var sfx: AudioStream = load("res://assets/audio/sfx/mascara_taberna.ogg")
		AudioManager.play_sfx(sfx)
	cantinero_mascara_puesta.emit()

func quitar_mascara_cantinero() -> void:
	cantinero_mascara = false
	cantinero_mascara_quitada.emit()

func equip_mask(mask_id: String) -> void:
	if mask_id == "" or not Inventory.has_item(mask_id):
		return
	mascara_equipada = mask_id
	if AudioManager and mask_id == "oso":
		var sfx: AudioStream = load("res://assets/audio/sfx/mascara_oso.ogg")
		AudioManager.play_sfx(sfx)
	mask_equipped_changed.emit()

func unequip_mask() -> void:
	if mascara_equipada == "":
		return
	mascara_equipada = ""
	mask_equipped_changed.emit()

func toggle_equip_mask(mask_id: String) -> void:
	if mascara_equipada == mask_id:
		unequip_mask()
	else:
		equip_mask(mask_id)

func is_wearing_mask(mask_id: String = "") -> bool:
	if mask_id == "":
		return mascara_equipada != ""
	return mascara_equipada == mask_id

## Balloon speaker for detective lines; shows worn mask role when equipped.
func get_detective_speaker_name() -> String:
	match mascara_equipada:
		"oso":
			return "Detective (Leñador)"
		"mascara_mozo":
			return "Detective (Mozo)"
		"mascara_poli":
			return "Detective (Policía)"
		_:
			return "Detective"

func mark_huellas_pelota() -> void:
	if huellas_pelota:
		return
	huellas_pelota = true
	huellas_changed.emit()

func has_huellas_pelota() -> bool:
	return huellas_pelota

func mark_patito_devuelto() -> void:
	if patito_devuelto:
		return
	patito_devuelto = true
	patito_devuelto_signal.emit()

func has_patito_devuelto() -> bool:
	return patito_devuelto

func exponer_bartender() -> void:
	if bartender_expuesto:
		return
	bartender_expuesto = true
	hablado_cantinero = true
	# Path to the river opens when the lumberjack cuts the ivy (hacha), not here.
	bartender_expuesto_signal.emit()

func is_bartender_expuesto() -> bool:
	return bartender_expuesto

func abrir_paso() -> void:
	if paso_abierto:
		return
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

func mark_hablado_cantinero() -> void:
	if hablado_cantinero:
		return
	hablado_cantinero = true
	hablado_cantinero_signal.emit()

func has_hablado_cantinero() -> bool:
	return hablado_cantinero

func mark_hablado_guardia() -> void:
	if hablado_guardia:
		return
	hablado_guardia = true
	hablado_guardia_signal.emit()

func has_hablado_guardia() -> bool:
	return hablado_guardia

func mark_tiene_bolso() -> void:
	if tiene_bolso:
		return
	tiene_bolso = true
	tiene_bolso_signal.emit()

func has_tiene_bolso() -> bool:
	return tiene_bolso

func mark_comisario_briefing() -> void:
	if comisario_briefing:
		return
	comisario_briefing = true
	comisario_briefing_signal.emit()

func has_comisario_briefing() -> bool:
	return comisario_briefing

func resolver_caso() -> void:
	caso_resuelto = true
	hablado_cantinero = true
	bartender_expuesto = true
	caso_resuelto_signal.emit()

func reset() -> void:
	cantinero_mascara = false
	paso_abierto = false
	caso_resuelto = false
	hablado_cantinero = false
	huellas_pelota = false
	patito_devuelto = false
	bartender_expuesto = false
	hablado_guardia = false
	tiene_bolso = false
	comisario_briefing = false
	mascara_equipada = ""
	comisario_tiene_oso = false
	clues_seen.clear()
	clues_changed.emit()
	mask_equipped_changed.emit()
	tiene_bolso_signal.emit()

func to_dict() -> Dictionary:
	return {
		"cantinero_mascara": cantinero_mascara,
		"paso_abierto": paso_abierto,
		"caso_resuelto": caso_resuelto,
		"hablado_cantinero": hablado_cantinero,
		"huellas_pelota": huellas_pelota,
		"patito_devuelto": patito_devuelto,
		"bartender_expuesto": bartender_expuesto,
		"hablado_guardia": hablado_guardia,
		"tiene_bolso": tiene_bolso,
		"comisario_briefing": comisario_briefing,
		"mascara_equipada": mascara_equipada,
		"comisario_tiene_oso": comisario_tiene_oso,
		"clues_seen": clues_seen.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	cantinero_mascara = bool(data.get("cantinero_mascara", false))
	paso_abierto = bool(data.get("paso_abierto", false))
	caso_resuelto = bool(data.get("caso_resuelto", false))
	hablado_cantinero = bool(data.get("hablado_cantinero", false))
	huellas_pelota = bool(data.get("huellas_pelota", false))
	patito_devuelto = bool(data.get("patito_devuelto", false))
	bartender_expuesto = bool(data.get("bartender_expuesto", false))
	hablado_guardia = bool(data.get("hablado_guardia", false))
	tiene_bolso = bool(data.get("tiene_bolso", false))
	comisario_briefing = bool(data.get("comisario_briefing", false))
	mascara_equipada = str(data.get("mascara_equipada", ""))
	comisario_tiene_oso = bool(data.get("comisario_tiene_oso", false))
	clues_seen.clear()
	for id in data.get("clues_seen", []):
		clues_seen.append(str(id))
	clues_changed.emit()
	mask_equipped_changed.emit()
	if paso_abierto:
		paso_abierto_signal.emit()
	if bartender_expuesto:
		bartender_expuesto_signal.emit()
	if caso_resuelto:
		caso_resuelto_signal.emit()
	if hablado_guardia:
		hablado_guardia_signal.emit()
	if tiene_bolso:
		tiene_bolso_signal.emit()
	if comisario_briefing:
		comisario_briefing_signal.emit()
	if hablado_cantinero:
		hablado_cantinero_signal.emit()
