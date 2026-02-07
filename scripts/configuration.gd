extends Control

@onready var volume_slider = $VBoxContainer/VolumeSlider

func _ready():
	volume_slider.connect("value_changed", Callable(self, "_on_volume_changed"))
	_on_volume_changed(volume_slider.value)

func _on_volume_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(value / 100.0))

func linear2db(value):
	if value > 0:
		return 20 * (log(value) / log(10))
	else:
		return -80

func _on_back_button_pressed():
	queue_free()
