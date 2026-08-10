extends NpcInteractable

const POS_INICIAL := Vector2(1499, 816)

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

func get_verb_text() -> String:
	if Inventory.selected_item == "credencial":
		return "Usar Credencial con Pescador"
	if Inventory.selected_item == "oso" and StoryFlags.is_bartender_expuesto():
		return "Usar Máscara con Pescador"
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
