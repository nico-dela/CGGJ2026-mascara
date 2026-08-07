extends Interactable
class_name NpcInteractable

## Optional animated sprite for NPCs that swap visuals (e.g. bartender mask).
@export var listen_mask_signals: bool = false
@export var anim_idle: String = "idle"
@export var anim_masked: String = "lenador_idle"
@export var anim_talk: String = "talk"

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var _talk_connected := false

func _ready() -> void:
	if verb == "Mirar":
		verb = "Hablar con"
	use_hover_feedback = true
	hover_scale_multiplier = 1.05
	super._ready()
	if animated_sprite:
		animated_sprite.play(anim_idle)
	if listen_mask_signals:
		StoryFlags.cantinero_mascara_puesta.connect(_on_mask_on)
		StoryFlags.cantinero_mascara_quitada.connect(_on_mask_off)
		if StoryFlags.cantinero_mascara:
			_on_mask_on()

func _interact() -> void:
	_play_talk()
	super._interact()

func _play_talk() -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_talk):
		animated_sprite.play(anim_talk)
		if not _talk_connected:
			_talk_connected = true
			DialogueManager.dialogue_ended.connect(_on_dialogue_ended_talk, CONNECT_ONE_SHOT)

func _on_dialogue_ended_talk(_resource) -> void:
	_talk_connected = false
	if animated_sprite == null:
		return
	if StoryFlags.cantinero_mascara and listen_mask_signals:
		animated_sprite.play(anim_masked)
	else:
		animated_sprite.play(anim_idle)

func _on_mask_on() -> void:
	if animated_sprite:
		animated_sprite.play(anim_masked)

func _on_mask_off() -> void:
	if animated_sprite:
		animated_sprite.play(anim_idle)
