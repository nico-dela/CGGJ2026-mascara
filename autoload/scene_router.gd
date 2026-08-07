extends Node

signal scene_changed(scene_path: String)

const FADE_DURATION := 0.35

var next_spawn_id: String = ""

var _transition_audio: AudioStreamPlayer
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _busy := false

func _ready() -> void:
	_transition_audio = AudioStreamPlayer.new()
	add_child(_transition_audio)
	_setup_fade()

func _setup_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fade_layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(root)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color(0, 0, 0, 0)
	root.add_child(_fade_rect)

func request_scene_change(scene_path: String, spawn_id: String = "", sound: AudioStream = null) -> void:
	if _busy:
		return
	if InteractionHint:
		InteractionHint.clear()
	next_spawn_id = spawn_id
	if sound:
		_transition_audio.stream = sound
		_transition_audio.play()
	_change_with_fade(scene_path)

func change_scene(scene_path: String) -> void:
	request_scene_change(scene_path, "", null)

func _change_with_fade(scene_path: String) -> void:
	_busy = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade(0.0, 1.0)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	scene_changed.emit(scene_path)
	await _fade(1.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

func _fade(from_alpha: float, to_alpha: float) -> void:
	_fade_rect.color = Color(0, 0, 0, from_alpha)
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", to_alpha, FADE_DURATION)
	await tween.finished
