extends Interactable

## Always visible. Look anytime; Take only after footprint evidence (huellas_pelota).

func _ready() -> void:
	use_verb_menu = true
	can_observe = true
	# Take stays enabled so early attempts get a reject line (not a disabled verb).
	can_take = true
	can_use = false
	dialogue_observe = load("res://content/dialogue/items/oso_observe.dialogue")
	dialogue_take = load("res://content/dialogue/items/oso_take.dialogue")
	dialogue_use = null
	dialogue = dialogue_observe
	item_to_give = "oso"
	persist_id = "oso"
	clue_id = "oso"
	despawn_on_interact = true
	verb = "Recoger"
	interact_label = "Máscara"
	interact_sound = load("res://assets/audio/sfx/mascara_oso.ogg")
	super._ready()
	# Scene used to hide this until a flag; hybrid design keeps it visible.
	visible = true
	input_pickable = true
	monitoring = true
	monitorable = true

func _do_take() -> void:
	if not StoryFlags.has_huellas_pelota():
		_arm_cooldown()
		_start_dialogue(load("res://content/dialogue/items/oso_take_blocked.dialogue"), false, false)
		return
	dialogue_take = load("res://content/dialogue/items/oso_take.dialogue")
	super._do_take()
