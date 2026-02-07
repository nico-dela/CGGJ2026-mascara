extends Area2D

@export var dialogue_no_info: Resource
@export var dialogue_confess: Resource

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	animated_sprite.play("idle")
	GameManager.cantinero_mascara_puesta.connect(_on_mask_on)
	GameManager.cantinero_mascara_quitada.connect(_on_mask_off)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if GameManager.has_item("oso"):
			DialogueManager.show_dialogue_balloon(dialogue_confess, "start")
			GameManager.remove_item("oso")
		else:
			DialogueManager.show_dialogue_balloon(dialogue_no_info, "start")

func _on_mask_on():
	animated_sprite.play("lenador_idle")

func _on_mask_off():
	animated_sprite.play("idle")
