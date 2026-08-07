extends Area2D

@export var target_scene: String
@export var target_spawn_id: String = "default"
@export var transition_sound: AudioStream
@export var verb: String = "Entrar a"
@export var interact_label: String = ""

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func try_interact() -> bool:
	if not visible or not input_pickable:
		return false
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
