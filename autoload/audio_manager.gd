extends Node

@onready var music: AudioStreamPlayer = $Music

func start_music():
	if not music.playing:
		music.play()

func stop_music():
	if music.playing:
		music.stop()
