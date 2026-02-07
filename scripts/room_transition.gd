extends Area2D

@export var target_scene: String
@export var target_spawn_id: String = "default"
@export var transition_sound: AudioStream

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		GameManager.request_scene_change(
			target_scene,
			target_spawn_id,
			transition_sound
		)
