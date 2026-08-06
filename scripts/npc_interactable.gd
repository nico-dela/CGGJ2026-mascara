extends Interactable
class_name NpcInteractable

## Optional animated sprite for NPCs that swap visuals (e.g. bartender mask).
@export var listen_mask_signals: bool = false
@export var anim_idle: String = "idle"
@export var anim_masked: String = "lenador_idle"

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	use_hover_feedback = false
	super._ready()
	if animated_sprite:
		animated_sprite.play(anim_idle)
	if listen_mask_signals:
		StoryFlags.cantinero_mascara_puesta.connect(_on_mask_on)
		StoryFlags.cantinero_mascara_quitada.connect(_on_mask_off)
		if StoryFlags.cantinero_mascara:
			_on_mask_on()

func _on_mask_on() -> void:
	if animated_sprite:
		animated_sprite.play(anim_masked)

func _on_mask_off() -> void:
	if animated_sprite:
		animated_sprite.play(anim_idle)
