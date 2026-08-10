extends Interactable

## Only after the bartender mentions the lost duck (problem before solution).

func _ready() -> void:
	use_verb_menu = true
	can_observe = true
	can_take = true
	can_use = false
	dialogue_observe = load("res://content/dialogue/items/patito_observe.dialogue")
	dialogue_take = load("res://content/dialogue/items/patito_take.dialogue")
	dialogue_use = null
	item_to_give = "patito"
	persist_id = "patito"
	clue_id = "patito"
	despawn_on_interact = true
	verb = "Examinar"
	interact_label = "Patito"
	hover_scale_multiplier = 1.125
	interact_sound = load("res://assets/audio/sfx/juguete_pato.ogg")
	visible = false
	input_pickable = false
	super._ready()
	_apply_reveal()
	if not StoryFlags.has_hablado_cantinero():
		StoryFlags.hablado_cantinero_signal.connect(_on_revealed)

func _apply_reveal() -> void:
	if Inventory.is_collected("patito"):
		return
	var revealed := StoryFlags.has_hablado_cantinero()
	visible = revealed
	input_pickable = revealed
	monitoring = revealed
	monitorable = revealed

func _on_revealed() -> void:
	_apply_reveal()
