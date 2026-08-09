extends Interactable

## World bag on the road. Taking it enables the Bolso HUD (not an inventory slot).

var _pending_tutorial := false

func _ready() -> void:
	if StoryFlags.has_tiene_bolso():
		queue_free()
		return
	use_verb_menu = true
	can_observe = true
	can_take = true
	can_use = false
	dialogue_observe = load("res://content/dialogue/road/road_bag_observe.dialogue")
	dialogue_take = load("res://content/dialogue/road/road_bag_take.dialogue")
	dialogue = dialogue_observe
	item_to_give = ""
	persist_id = ""
	despawn_on_interact = false
	verb = "Mirar"
	interact_label = "el bolso"
	use_hover_feedback = true
	hover_scale_multiplier = 1.08
	super._ready()
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended_bag)

func _do_take() -> void:
	if _interact_cooldown:
		return
	if StoryFlags.has_tiene_bolso():
		return
	if not StoryFlags.has_hablado_guardia():
		_arm_cooldown()
		_start_dialogue(load("res://content/dialogue/road/road_bag_blocked.dialogue"), false, false)
		return
	_arm_cooldown()
	_pending_tutorial = true
	_start_dialogue(dialogue_take, false, false)

func _on_dialogue_ended_bag(_resource) -> void:
	if not _pending_tutorial:
		return
	if not StoryFlags.has_tiene_bolso():
		_pending_tutorial = false
		return
	_pending_tutorial = false
	if AdventureUI and AdventureUI.has_method("play_ui_tutorial"):
		AdventureUI.play_ui_tutorial()
	queue_free()
