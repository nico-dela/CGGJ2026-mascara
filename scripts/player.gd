extends CharacterBody2D

const SPEED = 500.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var footsteps = $Footsteps
@onready var camera: Camera2D = $Camera2D

enum PlayerState { IDLE, WALKING }
var state := PlayerState.IDLE

var target_position = Vector2()
var moving = false
var is_walking := false

var dialogue_active := false

func _ready() -> void:
	input_pickable = false
	get_viewport().physics_object_picking = true

	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	animated_sprite.play("poroto_idle")
	add_to_group("player")

	if SceneRouter.next_spawn_id != "":
		var spawn_points = get_tree().current_scene.get_node_or_null("SpawnPoints")
		if spawn_points and spawn_points.has_node(SceneRouter.next_spawn_id):
			global_position = spawn_points.get_node(SceneRouter.next_spawn_id).global_position
		SceneRouter.next_spawn_id = ""

	apply_camera_limits(0, 0, 1920, 1080)

func apply_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	if camera == null:
		return
	camera.enabled = true
	camera.make_current()
	camera.limit_left = left
	camera.limit_top = top
	camera.limit_right = right
	camera.limit_bottom = bottom
	var view_size := get_viewport().get_visible_rect().size
	var limit_w := float(right - left)
	var limit_h := float(bottom - top)
	camera.position_smoothing_enabled = limit_w > view_size.x + 1.0 or limit_h > view_size.y + 1.0

func set_footstep_stream(stream: AudioStream) -> void:
	if footsteps:
		footsteps.stream = stream

func _on_dialogue_started(_resource) -> void:
	dialogue_active = true
	moving = false
	velocity = Vector2.ZERO
	set_state(PlayerState.IDLE)
	InteractionHint.set_suppressed(true)

func _on_dialogue_ended(_resource) -> void:
	dialogue_active = false
	InteractionHint.set_suppressed(false)

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_active:
		return

	var world_target := Vector2.ZERO
	var pressed := false

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
		world_target = get_global_mouse_position()
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
		world_target = get_canvas_transform().affine_inverse() * event.position
	elif event.is_action_pressed("interact"):
		pressed = true
		world_target = get_global_mouse_position()

	if not pressed:
		return

	# Prefer interacting with NPCs/props under the cursor before walking.
	if _try_interact_at(world_target):
		get_viewport().set_input_as_handled()
		return

	target_position = world_target
	moving = true
	# One-shot footstep per click (design sheet); restart if already playing.
	if footsteps and footsteps.stream:
		footsteps.play()
	get_viewport().set_input_as_handled()

func _try_interact_at(world_pos: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0x7FFFFFFF
	var hits := space.intersect_point(query, 32)
	# Prefer the topmost interactable (highest z_index / canvas layer order).
	hits.sort_custom(func(a, b):
		var na: Node2D = a.collider
		var nb: Node2D = b.collider
		if na.z_index == nb.z_index:
			return na.get_index() > nb.get_index()
		return na.z_index > nb.z_index
	)
	for hit in hits:
		var collider = hit.collider
		if collider != null and collider.has_method("try_interact"):
			if collider.try_interact():
				return true
	return false

func _physics_process(_delta) -> void:
	if moving:
		move_towards_target()

func move_towards_target() -> void:
	var direction = target_position - global_position
	var distance = direction.length()

	if distance < 6:
		moving = false
		velocity = Vector2.ZERO
		set_state(PlayerState.IDLE)
		return

	velocity = direction.normalized() * SPEED
	animated_sprite.flip_h = velocity.x < 0
	set_state(PlayerState.WALKING)

	var collision = move_and_collide(velocity * get_physics_process_delta_time())
	if collision:
		moving = false
		velocity = Vector2.ZERO
		set_state(PlayerState.IDLE)

func update_walk_state(walking: bool) -> void:
	# Footsteps are one-shot on click; do not loop/stop here (avoids multi-click mute).
	is_walking = walking

func set_state(new_state: PlayerState) -> void:
	if state == new_state:
		return
	state = new_state
	match state:
		PlayerState.WALKING:
			animated_sprite.play("poroto_walk")
			update_walk_state(true)
		PlayerState.IDLE:
			animated_sprite.play("poroto_idle")
			update_walk_state(false)
