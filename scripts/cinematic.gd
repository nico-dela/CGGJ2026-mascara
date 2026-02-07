extends Control

@export var next_scene := "res://scenes/room_1.tscn"

@onready var video := $VideoStreamPlayer
#@onready var anim := $AnimationPlayer

var transitioning := false

func _ready():
	#anim.play("fade_in")
	video.play()
	video.finished.connect(_on_video_finished)
		
func _input(event):
	if transitioning:
		return

	if event is InputEventMouseButton and event.pressed:
		go_to_next_scene()


func _on_video_finished():
	go_to_next_scene()

func go_to_next_scene():
	if transitioning:
		return

	transitioning = true
	video.stop()
	#anim.play("fade_out")
	#await anim.animation_finished
	get_tree().change_scene_to_file(next_scene)
