extends Interactable

## Appears after huellas (need the lumberjack identity to confront / clear the path).

func _ready() -> void:
	use_verb_menu = true
	can_observe = true
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
	visible = false
	input_pickable = false
	super._ready()
	_apply_reveal()
	if not _is_revealed():
		StoryFlags.huellas_changed.connect(_on_huellas)

func _is_revealed() -> bool:
	return StoryFlags.has_huellas_pelota()

func _apply_reveal() -> void:
	if Inventory.is_collected("oso"):
		return
	var revealed := _is_revealed()
	visible = revealed
	input_pickable = revealed
	monitoring = revealed
	monitorable = revealed

func _on_huellas() -> void:
	_apply_reveal()
