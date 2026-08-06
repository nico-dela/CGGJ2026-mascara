extends Area2D

@export var target_scene: String
@export var target_spawn_id: String = "default"
@export var transition_sound: AudioStream

func _ready() -> void:
	# Doors use body overlap, not clicks — don't steal mouse from interactables.
	input_pickable = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		SceneRouter.request_scene_change(
			target_scene,
			target_spawn_id,
			transition_sound
		)
