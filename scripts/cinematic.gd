extends Control

@export var next_scene := "res://scenes/room_1.tscn"

@onready var video := $VideoStreamPlayer
@onready var anim := $AnimationPlayer

var transitioning := false

func _ready() -> void:
	video.play()
	video.finished.connect(_on_video_finished)

func _unhandled_input(event: InputEvent) -> void:
	if transitioning:
		return
	if event.is_action_pressed("interact") or (
		event is InputEventMouseButton and event.pressed
	):
		go_to_next_scene()

func _on_video_finished() -> void:
	go_to_next_scene()

func go_to_next_scene() -> void:
	if transitioning:
		return
	transitioning = true
	video.stop()
	if anim and anim.has_animation("fade_out"):
		anim.play("fade_out")
		await anim.animation_finished
	get_tree().change_scene_to_file(next_scene)
