extends Node

const FADE_SEC := 0.65

@onready var music: AudioStreamPlayer = $Music
@onready var ambient_a: AudioStreamPlayer = $AmbientA
@onready var ambient_b: AudioStreamPlayer = $AmbientB
@onready var sfx: AudioStreamPlayer = $SFX

var _game_music: AudioStream
var _active_ambient: AudioStreamPlayer
var _idle_ambient: AudioStreamPlayer
var _current_ambient_path: String = ""
var _fade_tween: Tween

func _ready() -> void:
	_game_music = music.stream
	_active_ambient = ambient_a
	_idle_ambient = ambient_b
	_ensure_loop(music.stream)
	if GameSettings:
		GameSettings.apply_all()
	else:
		_apply_saved_master_volume()

func _apply_saved_master_volume() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		return
	var volume := float(cfg.get_value("audio", "master", 50.0))
	var linear := clampf(volume / 100.0, 0.0, 1.0)
	var db := -80.0 if linear <= 0.0 else 20.0 * (log(linear) / log(10.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func start_music() -> void:
	if _game_music == null:
		return
	_ensure_loop(_game_music)
	if music.stream == _game_music and music.playing:
		return
	music.stream = _game_music
	music.volume_db = 0.0
	music.play()

func stop_music() -> void:
	if music.playing:
		music.stop()

func restore_game_music() -> void:
	music.stop()
	if _game_music:
		music.stream = _game_music
		_ensure_loop(_game_music)

func set_music(stream: AudioStream) -> void:
	if music.stream == stream and music.playing:
		return
	music.stream = stream
	_ensure_loop(stream)
	if stream:
		music.volume_db = 0.0
		music.play()
	else:
		music.stop()

func set_ambient(stream: AudioStream) -> void:
	if stream == null:
		fade_out_ambient()
		return
	var path := stream.resource_path
	if path != "" and path == _current_ambient_path:
		return
	_current_ambient_path = path
	_ensure_loop(stream)
	_crossfade_to(stream)

func fade_out_ambient() -> void:
	_current_ambient_path = ""
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	if _active_ambient.playing:
		_fade_tween.tween_property(_active_ambient, "volume_db", -40.0, FADE_SEC)
	if _idle_ambient.playing:
		_fade_tween.tween_property(_idle_ambient, "volume_db", -40.0, FADE_SEC)
	_fade_tween.chain().tween_callback(func():
		_active_ambient.stop()
		_idle_ambient.stop()
	)

func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	sfx.stream = stream
	sfx.play()

func _crossfade_to(stream: AudioStream) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_idle_ambient.stream = stream
	_idle_ambient.volume_db = -40.0
	_idle_ambient.play()

	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(_idle_ambient, "volume_db", 0.0, FADE_SEC)
	if _active_ambient.playing:
		_fade_tween.tween_property(_active_ambient, "volume_db", -40.0, FADE_SEC)
	_fade_tween.chain().tween_callback(func():
		_active_ambient.stop()
		var tmp := _active_ambient
		_active_ambient = _idle_ambient
		_idle_ambient = tmp
	)

func _ensure_loop(stream: AudioStream) -> void:
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
