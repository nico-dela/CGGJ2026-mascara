extends NpcInteractable

const POS_INICIAL := Vector2(1499, 816)
const APPROACH_DIST := 160.0

var _queued_verb := ""
var _queued_item_use := false

func _ready() -> void:
	verb = "Hablar con"
	interact_label = "Pescador"
	anim_idle = "idle"
	anim_talk = "talk"
	if dialogue == null:
		dialogue = load("res://content/dialogue/pescador/pescador.dialogue")
	dialogue_observe = load("res://content/dialogue/pescador/pescador_observe.dialogue")
	super._ready()
	StoryFlags.bartender_expuesto_signal.connect(_aplicar_estado_rio)
	StoryFlags.caso_resuelto_signal.connect(_aplicar_estado_resuelto)
	if StoryFlags.is_bartender_expuesto() or StoryFlags.caso_resuelto:
		_aplicar_estado_rio()
	if StoryFlags.caso_resuelto:
		_aplicar_estado_resuelto()

func _aplicar_estado_rio() -> void:
	# Scene placement owns the riverside position (room_4). Only update anims here.
	anim_idle = "fishing"
	anim_talk = "talk"
	if animated_sprite:
		animated_sprite.play("fishing")

func _aplicar_estado_resuelto() -> void:
	_aplicar_estado_rio()

func _play_talk() -> void:
	# En la orilla del pueblo solo idle; fishing/talk en el río (room_4).
	if not StoryFlags.is_bartender_expuesto() and not StoryFlags.caso_resuelto:
		return
	super._play_talk()

func apply_verb(verb_id: String) -> void:
	if verb_id == "observe":
		super.apply_verb(verb_id)
		return
	_queued_verb = verb_id
	_queued_item_use = false
	if _try_approach():
		return
	_queued_verb = ""
	super.apply_verb(verb_id)

func try_interact() -> bool:
	if not visible or not input_pickable:
		return false
	if Inventory.selected_item != "":
		_queued_item_use = true
		_queued_verb = ""
		if _try_approach():
			return true
		_queued_item_use = false
	return super.try_interact()

func get_verb_text() -> String:
	if Inventory.selected_item == "credencial":
		return tr("Usar %s con %s") % [Inventory.get_display_name("credencial"), get_interact_label()]
	if Inventory.selected_item == "oso" and StoryFlags.is_bartender_expuesto():
		return tr("Usar %s con %s") % [Inventory.get_display_name("oso"), get_interact_label()]
	return super.get_verb_text()

func _interact() -> void:
	var selected := Inventory.selected_item

	# Ending: give oso mask to fisherman at the river after expose.
	if selected == "oso" and StoryFlags.is_bartender_expuesto():
		dialogue_with_item = load("res://content/dialogue/pescador/pescador_ending.dialogue")
		required_item = "oso"
		super._interact()
		required_item = ""
		return

	if selected == "credencial":
		dialogue_with_item = load("res://content/dialogue/pescador/pescador_credencial.dialogue")
		required_item = "credencial"
		super._interact()
		required_item = ""
		return

	if StoryFlags.caso_resuelto:
		dialogue = load("res://content/dialogue/pescador/pescador_ending.dialogue")
	elif StoryFlags.is_bartender_expuesto():
		dialogue = load("res://content/dialogue/pescador/pescador_river.dialogue")
	else:
		dialogue = load("res://content/dialogue/pescador/pescador.dialogue")
	super._interact()

func _in_river_room() -> bool:
	var scene := get_tree().current_scene
	return scene != null and str(scene.scene_file_path).ends_with("room_4.tscn")

func _stand_pos() -> Vector2:
	var scene := get_tree().current_scene
	if scene:
		var marker := scene.get_node_or_null("SpawnPoints/Stone_Right") as Node2D
		if marker:
			return marker.global_position
	return global_position + Vector2(-100, 40)

func _try_approach() -> bool:
	if not _in_river_room():
		return false
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("request_move"):
		return false
	if player.global_position.distance_to(_stand_pos()) <= APPROACH_DIST:
		return false
	player.request_move(_stand_pos(), _on_approached)
	return true

func _on_approached() -> void:
	if _queued_item_use:
		_queued_item_use = false
		super.try_interact()
		return
	if _queued_verb != "":
		var verb_id := _queued_verb
		_queued_verb = ""
		super.apply_verb(verb_id)
