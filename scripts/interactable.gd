extends Area2D
class_name Interactable

@export var dialogue: Resource
@export var dialogue_with_item: Resource
@export var required_item: String = ""
@export var item_to_give: String = ""
@export var persist_id: String = ""
@export var clue_id: String = ""
@export var despawn_on_interact: bool = false
@export var require_paso_cerrado: bool = false
@export var hover_scale_multiplier: float = 1.05
@export var use_hover_feedback: bool = true
@export var interact_sound: AudioStream

@onready var sprite: Node2D = get_node_or_null("Sprite2D")

var _base_scale: Vector2 = Vector2.ONE
var _interact_cooldown := false

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")
	if sprite:
		_base_scale = sprite.scale
	if persist_id != "" and Inventory.is_collected(persist_id):
		queue_free()
		return
	if require_paso_cerrado:
		StoryFlags.paso_abierto_signal.connect(_on_paso_abierto)
		if StoryFlags.is_paso_abierto():
			_on_paso_abierto()
	if use_hover_feedback and sprite:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

## Called by the player click router (reliable on desktop + touch).
func try_interact() -> bool:
	if not visible or not input_pickable:
		return false
	if require_paso_cerrado and StoryFlags.is_paso_abierto():
		return false
	_interact()
	return true

func _interact() -> void:
	if _interact_cooldown:
		return
	_interact_cooldown = true
	get_tree().create_timer(0.25).timeout.connect(func(): _interact_cooldown = false)

	if interact_sound and AudioManager:
		AudioManager.play_sfx(interact_sound)

	if clue_id != "":
		GameManager.mark_clue_seen(clue_id)

	var use_special := _should_use_item_dialogue()
	var resource: Resource = dialogue_with_item if use_special else dialogue
	if resource == null:
		push_warning("%s: no dialogue resource assigned" % name)
		return

	if persist_id != "":
		GameManager.mark_as_collected(persist_id)
	if item_to_give != "":
		GameManager.add_item(item_to_give)
		var ui = get_tree().get_first_node_in_group("inventory_ui")
		if ui and ui.has_method("refresh"):
			ui.refresh()

	if use_special and required_item != "":
		Inventory.selected_item = ""

	DialogueManager.show_dialogue_balloon(resource, "start")

	if despawn_on_interact:
		queue_free()

func _should_use_item_dialogue() -> bool:
	if required_item == "" or dialogue_with_item == null:
		return false
	if not Inventory.has_item(required_item):
		return false
	return Inventory.selected_item == required_item or Inventory.selected_item == ""

func _on_paso_abierto() -> void:
	visible = false
	monitoring = false
	monitorable = false
	input_pickable = false

func _on_mouse_entered() -> void:
	if use_hover_feedback and sprite:
		sprite.scale = _base_scale * hover_scale_multiplier
		sprite.modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited() -> void:
	if use_hover_feedback and sprite:
		sprite.scale = _base_scale
		sprite.modulate = Color.WHITE
