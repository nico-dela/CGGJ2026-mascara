extends Area2D

@export var target_scene: String
@export var target_spawn_id: String = "default"
@export var transition_sound: AudioStream
@export var verb: String = "Entrar a"
@export var interact_label: String = ""
## If true, player must talk to the road guard before this transition works.
@export var require_hablado_guardia: bool = false
@export var blocked_dialogue: Resource

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if blocked_dialogue == null and require_hablado_guardia:
		blocked_dialogue = load("res://content/dialogue/road/road_town_blocked.dialogue")

func try_interact() -> bool:
	if not visible or not input_pickable:
		return false
	if require_hablado_guardia and not StoryFlags.has_hablado_guardia():
		InteractionHint.hide_hint()
		var resource: Resource = blocked_dialogue
		if resource == null:
			resource = load("res://content/dialogue/road/road_town_blocked.dialogue")
		DialogueManager.show_dialogue_balloon(resource, "start")
		return true
	if target_scene.is_empty():
		push_warning("%s: no target_scene assigned" % name)
		return false
	InteractionHint.hide_hint()
	SceneRouter.request_scene_change(
		target_scene,
		target_spawn_id,
		transition_sound
	)
	return true

func get_verb_text() -> String:
	if interact_label.is_empty():
		return verb
	return "%s %s" % [verb, interact_label]

func _on_mouse_entered() -> void:
	InteractionHint.show_hint(get_verb_text(), self)

func _on_mouse_exited() -> void:
	InteractionHint.hide_hint_from(self)
