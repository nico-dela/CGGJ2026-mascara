extends Control

@export var next_scene := "res://scenes/room_1.tscn"

@onready var video := $VideoStreamPlayer
@onready var anim := $AnimationPlayer

var transitioning := false

func _ready() -> void:
	# Evita que música/ambiente compitan con el decode del Theora en web/móvil.
	AudioManager.stop_music()
	AudioManager.fade_out_ambient()

	video.expand = true
	video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# En web el buffer chico + decode de video provoca audio entrecortado.
	if OS.has_feature("web"):
		Engine.max_fps = 30
		# Un frame libre antes de play ayuda al AudioServer/WebAudio.
		await get_tree().process_frame

	video.play()
	if not video.finished.is_connected(_on_video_finished):
		video.finished.connect(_on_video_finished)

func _unhandled_input(event: InputEvent) -> void:
	if transitioning:
		return
	if event.is_action_pressed("interact") or (
		event is InputEventMouseButton and event.pressed
	) or (event is InputEventScreenTouch and event.pressed):
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
