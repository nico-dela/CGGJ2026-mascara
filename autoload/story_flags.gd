extends Node

signal paso_abierto_signal
signal caso_resuelto_signal
signal clues_changed
signal mask_equipped_changed
signal bartender_expuesto_signal
signal huellas_changed
signal patito_devuelto_signal
signal hablado_hawker_signal
signal tiene_bolso_signal
signal comisario_briefing_signal
signal hablado_cantinero_signal

var paso_abierto := false
var caso_resuelto := false
var hablado_cantinero := false
var huellas_pelota := false
var patito_devuelto := false
var bartender_expuesto := false
## Talked to the road hawker (unlocks town + bag take).
var hablado_hawker := false
## World bag collected — enables Bolso HUD / taking items (not an inventory slot).
var tiene_bolso := false
## Comisario asked for help / case briefing done.
var comisario_briefing := false
## Mask id currently worn by the detective (plot: only "oso"), or "".
var mascara_equipada := ""
## Clue ids the player has inspected (patito, pelota, tronco, oso, etc.)
var clues_seen: Array[String] = []

## Only the bear mask is wearable for plot.
const PLOT_MASK_ID := "oso"

func equip_mask(mask_id: String) -> void:
	if mask_id != PLOT_MASK_ID or not Inventory.has_item(mask_id):
		return
	mascara_equipada = mask_id
	if AudioManager:
		var sfx: AudioStream = load("res://assets/audio/sfx/mascara_oso.ogg")
		AudioManager.play_sfx(sfx)
	mask_equipped_changed.emit()

func unequip_mask() -> void:
	if mascara_equipada == "":
		return
	mascara_equipada = ""
	mask_equipped_changed.emit()

func toggle_equip_mask(mask_id: String) -> void:
	if mask_id != PLOT_MASK_ID:
		return
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
	if mascara_equipada == PLOT_MASK_ID:
		return "Detective (Leñador)"
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

func mark_hablado_hawker() -> void:
	if hablado_hawker:
		return
	hablado_hawker = true
	hablado_hawker_signal.emit()

func has_hablado_hawker() -> bool:
	return hablado_hawker

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
	paso_abierto = false
	caso_resuelto = false
	hablado_cantinero = false
	huellas_pelota = false
	patito_devuelto = false
	bartender_expuesto = false
	hablado_hawker = false
	tiene_bolso = false
	comisario_briefing = false
	mascara_equipada = ""
	clues_seen.clear()
	clues_changed.emit()
	mask_equipped_changed.emit()
	tiene_bolso_signal.emit()

func to_dict() -> Dictionary:
	return {
		"paso_abierto": paso_abierto,
		"caso_resuelto": caso_resuelto,
		"hablado_cantinero": hablado_cantinero,
		"huellas_pelota": huellas_pelota,
		"patito_devuelto": patito_devuelto,
		"bartender_expuesto": bartender_expuesto,
		"hablado_hawker": hablado_hawker,
		"tiene_bolso": tiene_bolso,
		"comisario_briefing": comisario_briefing,
		"mascara_equipada": mascara_equipada,
		"clues_seen": clues_seen.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	paso_abierto = bool(data.get("paso_abierto", false))
	caso_resuelto = bool(data.get("caso_resuelto", false))
	hablado_cantinero = bool(data.get("hablado_cantinero", false))
	huellas_pelota = bool(data.get("huellas_pelota", false))
	patito_devuelto = bool(data.get("patito_devuelto", false))
	bartender_expuesto = bool(data.get("bartender_expuesto", false))
	# Migrate older saves that used hablado_guardia.
	hablado_hawker = bool(data.get("hablado_hawker", data.get("hablado_guardia", false)))
	tiene_bolso = bool(data.get("tiene_bolso", false))
	comisario_briefing = bool(data.get("comisario_briefing", false))
	mascara_equipada = str(data.get("mascara_equipada", ""))
	# Stretch NPC masks are no longer wearable.
	if mascara_equipada != "" and mascara_equipada != PLOT_MASK_ID:
		mascara_equipada = ""
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
	if hablado_hawker:
		hablado_hawker_signal.emit()
	if tiene_bolso:
		tiene_bolso_signal.emit()
	if comisario_briefing:
		comisario_briefing_signal.emit()
	if hablado_cantinero:
		hablado_cantinero_signal.emit()
