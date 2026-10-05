extends Interactable
class_name NpcInteractable

## Optional animated sprite for NPCs with talk / idle animations.
@export var anim_idle: String = "idle"
@export var anim_talk: String = "talk"
## Unused legacy export (NPC mask-swap stretch removed).
@export var listen_mask_signals: bool = false
@export var visual_oso_flag: String = ""
@export var anim_masked: String = "lenador_idle"

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var _talk_connected := false

func _ready() -> void:
	use_hover_feedback = true
	hover_scale_multiplier = 1.05
	is_npc = true
	use_verb_menu = false
	can_observe = true
	can_take = false
	can_use = false
	super._ready()
	if animated_sprite:
		animated_sprite.play(anim_idle)

func _interact() -> void:
	_play_talk()
	super._interact()

func try_interact() -> bool:
	if not visible or not input_pickable:
		return false
	if Inventory.selected_item != "":
		_interact_default()
		return true
	# Without an item, the player opens the verb coin instead.
	return false

func apply_verb(verb_id: String) -> void:
	if not visible or not input_pickable:
		return
	match verb_id:
		"take":
			_arm_cooldown()
			_start_reject_dialogue()
		"use":
			_arm_cooldown()
			_start_reject_dialogue()
		"observe":
			_arm_cooldown()
			_do_npc_observe()
		_:
			_interact_default()

func _do_npc_observe() -> void:
	var res: Resource = dialogue_observe if dialogue_observe != null else null
	if res != null:
		_start_dialogue(res, false, false)
	else:
		_start_dialogue(dialogue if dialogue != null else null, false, false)

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
	if animated_sprite:
		animated_sprite.play(anim_idle)
