extends NpcInteractable

const POS_INICIAL := Vector2(1499, 816)
const POS_FINAL := Vector2(5900, 831)

func _ready() -> void:
	verb = "Hablar con"
	interact_label = "el pescador"
	anim_idle = "idle"
	anim_talk = "talk"
	if dialogue == null:
		dialogue = load("res://dialogues/pescador.dialogue")
	super._ready()
	StoryFlags.bartender_expuesto_signal.connect(_aplicar_estado_rio)
	StoryFlags.caso_resuelto_signal.connect(_aplicar_estado_resuelto)
	if StoryFlags.is_bartender_expuesto() or StoryFlags.caso_resuelto:
		_aplicar_estado_rio()
	if StoryFlags.caso_resuelto:
		_aplicar_estado_resuelto()

func _aplicar_estado_rio() -> void:
	position = POS_FINAL
	anim_idle = "fishing"
	anim_talk = "talk"
	if animated_sprite:
		animated_sprite.play("fishing")

func _aplicar_estado_resuelto() -> void:
	_aplicar_estado_rio()

func _play_talk() -> void:
	# En la orilla inicial solo idle; fishing/talk solo en la posición final.
	if not StoryFlags.is_bartender_expuesto() and not StoryFlags.caso_resuelto:
		return
	super._play_talk()

func _interact() -> void:
	var selected := Inventory.selected_item

	# Ending: give oso mask to fisherman at the river after expose.
	if selected == "oso" and StoryFlags.is_bartender_expuesto():
		dialogue_with_item = load("res://dialogues/pescador_ending.dialogue")
		required_item = "oso"
		super._interact()
		required_item = ""
		return

	if StoryFlags.caso_resuelto:
		dialogue = load("res://dialogues/pescador_ending.dialogue")
	elif StoryFlags.is_bartender_expuesto():
		dialogue = load("res://dialogues/pescador_river.dialogue")
	else:
		dialogue = load("res://dialogues/pescador.dialogue")
	super._interact()
