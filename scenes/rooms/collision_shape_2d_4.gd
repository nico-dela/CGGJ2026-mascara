extends Node2D

@onready var collision_shape = $CollisionShape2D4

func _ready() -> void:
	StoryFlags.paso_abierto_signal.connect(_on_paso_abierto)
	if StoryFlags.is_paso_abierto():
		_on_paso_abierto()

func _on_paso_abierto() -> void:
	collision_shape.disabled = true
