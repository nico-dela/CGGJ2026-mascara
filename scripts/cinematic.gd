extends Control

@export var next_scene := "res://scenes/room_1.tscn"

const INTRO_AUDIO := preload("res://audios/AMBIENTES Y SFX/AMBIENTES/cinematicaIntro.ogg")

@onready var video := $VideoStreamPlayer
@onready var anim := $AnimationPlayer
@onready var intro_audio: AudioStreamPlayer = $IntroAudio

var transitioning := false

func _ready() -> void:
	# Evita que música/ambiente compitan con el decode del Theora en web/móvil.
	AudioManager.stop_music()
	AudioManager.fade_out_ambient()

	video.expand = true
	video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# El audio del OGV en VideoStreamPlayer se corta en web (WASM + decode Theora).
	# Muteamos el video y reproducimos el Vorbis por AudioStreamPlayer.
	video.volume_db = -80.0
	intro_audio.stream = INTRO_AUDIO
	intro_audio.volume_db = 0.0

	if OS.has_feature("web"):
		Engine.max_fps = 30
		# Dar un frame al AudioServer/WebAudio antes de arrancar.
		await get_tree().process_frame
		await get_tree().process_frame

	intro_audio.play()
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
	# El video reencodeado puede terminar un poco antes que el audio extraído.
	if intro_audio and intro_audio.playing:
		await intro_audio.finished
	go_to_next_scene()

func go_to_next_scene() -> void:
	if transitioning:
		return
	transitioning = true
	if intro_audio and intro_audio.playing:
		intro_audio.stop()
	video.stop()
	if anim and anim.has_animation("fade_out"):
		anim.play("fade_out")
		await anim.animation_finished
	get_tree().change_scene_to_file(next_scene)
	if SceneRouter and SceneRouter.has_signal("scene_changed"):
		SceneRouter.scene_changed.emit(next_scene)
