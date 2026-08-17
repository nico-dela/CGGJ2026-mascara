extends CharacterBody2D

const SPEED = 500.0
const HOP_SPEED := 700.0
const HOP_HEIGHT_MIN := 70.0
const HOP_HEIGHT_MAX := 120.0
const SELF_USE_RADIUS := 110.0
const MASK_ANIMS := {
	"oso": ["lenador_idle", "lenador_walk"],
	"mascara_mozo": ["mozo_idle", "mozo_walk"],
	"mascara_poli": ["poli_idle", "poli_walk"],
	"mascara_vendedor": ["vendedor_idle", "vendedor_walk"],
}

@onready var animated_sprite = $AnimatedSprite2D
@onready var footsteps = $Footsteps
@onready var camera: Camera2D = $Camera2D

enum PlayerState { IDLE, WALKING }
var state := PlayerState.IDLE

var target_position = Vector2()
var moving = false
var is_walking := false
var _move_path: Array[Vector2] = []
var _hopping := false
var _hop_tween: Tween
var _hop_ground_y := 0.0
var _collision_mask_default := 1
var _on_arrive: Callable
var _base_sprite_scale := Vector2.ONE
var _depth_factor := 1.0

var dialogue_active := false

func _ready() -> void:
	input_pickable = false
	get_viewport().physics_object_picking = true

	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	StoryFlags.mask_equipped_changed.connect(_on_mask_equipped_changed)

	_collision_mask_default = collision_mask
	if animated_sprite:
		_base_sprite_scale = animated_sprite.scale
	_play_idle()
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
	_stop_movement(true)
	if VerbMenu and VerbMenu.is_open():
		VerbMenu.hide_menu()
	InteractionHint.set_suppressed(true)

func _on_dialogue_ended(_resource) -> void:
	dialogue_active = false
	InteractionHint.set_suppressed(false)

func _on_mask_equipped_changed() -> void:
	set_state(state)  # refresh anim for current state
	# Force anim update even if state unchanged
	if state == PlayerState.WALKING:
		_play_walk()
	else:
		_play_idle()

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_active:
		return
	if VerbMenu and VerbMenu.is_open():
		return

	var world_target := Vector2.ZERO
	var screen_pos := Vector2.ZERO
	var pressed := false

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
		world_target = get_global_mouse_position()
		screen_pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
		screen_pos = event.position
		world_target = get_canvas_transform().affine_inverse() * event.position
	elif event.is_action_pressed("interact"):
		pressed = true
		world_target = get_global_mouse_position()
		screen_pos = get_viewport().get_mouse_position()

	if not pressed:
		return

	# Verb coin open: click another hotspot to retarget, else dismiss.
	if AdventureUI and AdventureUI.is_coin_open():
		var retarget := _find_verb_coin_target(world_target)
		if retarget != null:
			AdventureUI.show_verb_coin(retarget, screen_pos if screen_pos != Vector2.ZERO else get_viewport().get_mouse_position())
		else:
			AdventureUI.hide_verb_coin()
		get_viewport().set_input_as_handled()
		return

	if _try_interact_at(world_target, screen_pos):
		get_viewport().set_input_as_handled()
		return

	request_move(world_target)
	get_viewport().set_input_as_handled()

func _try_interact_at(world_pos: Vector2, screen_pos: Vector2 = Vector2.ZERO) -> bool:
	# Use selected item on self (masks equip; others reject).
	if _try_use_item_on_self(world_pos):
		return true

	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0x7FFFFFFF
	var hits := space.intersect_point(query, 32)
	hits.sort_custom(func(a, b):
		var na: Node2D = a.collider
		var nb: Node2D = b.collider
		if na.z_index == nb.z_index:
			return na.get_index() > nb.get_index()
		return na.z_index > nb.z_index
	)
	for hit in hits:
		var collider = hit.collider
		if collider == null:
			continue
		if not _is_active_hotspot(collider):
			continue
		# Item selected → immediate use-with / transition.
		if Inventory.selected_item != "" and collider.has_method("try_interact"):
			if collider.try_interact():
				return true
			continue
		# Full Throttle: open verb coin on hotspots that support apply_verb.
		if collider.has_method("apply_verb") and AdventureUI:
			var pos := screen_pos
			if pos == Vector2.ZERO:
				pos = get_viewport().get_mouse_position()
			AdventureUI.show_verb_coin(collider, pos)
			_stop_movement(true)
			return true
		if collider.has_method("try_interact"):
			if DisplayAdapt and DisplayAdapt.is_touch_device and collider.has_method("get_verb_text"):
				var verb_text: String = collider.get_verb_text()
				if verb_text != "" and AdventureUI:
					var pos := screen_pos
					if pos == Vector2.ZERO:
						pos = get_viewport().get_mouse_position()
					AdventureUI.show_touch_hint(verb_text, pos)
			if collider.try_interact():
				return true
	return false

func _is_active_hotspot(collider: Object) -> bool:
	if collider is CanvasItem and not (collider as CanvasItem).visible:
		return false
	if collider is CollisionObject2D and not (collider as CollisionObject2D).input_pickable:
		return false
	return true

func _try_use_item_on_self(world_pos: Vector2) -> bool:
	if Inventory.selected_item == "":
		return false
	if global_position.distance_to(world_pos) > SELF_USE_RADIUS:
		return false
	var item := Inventory.get_item(Inventory.selected_item)
	if item != null and item.tipo == ItemResource.ItemTypes.MASCARA:
		GameManager.toggle_equip_mask(Inventory.selected_item)
		InteractionHint.hide_hint()
		return true
	# Non-mask items on the detective: polite reject.
	Inventory.selected_item = ""
	InteractionHint.hide_hint()
	var reject: Resource = load("res://content/dialogue/system/generic_no_use.dialogue")
	if reject:
		DialogueManager.show_dialogue_balloon(reject, "start")
	return true

func _find_verb_coin_target(world_pos: Vector2) -> Node:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0x7FFFFFFF
	var hits := space.intersect_point(query, 32)
	hits.sort_custom(func(a, b):
		var na: Node2D = a.collider
		var nb: Node2D = b.collider
		if na.z_index == nb.z_index:
			return na.get_index() > nb.get_index()
		return na.z_index > nb.z_index
	)
	for hit in hits:
		var collider = hit.collider
		if collider != null and collider.has_method("apply_verb") and _is_active_hotspot(collider):
			return collider
	return null

func request_move(world_target: Vector2, on_arrive: Callable = Callable()) -> void:
	_cancel_hop()
	_move_path.clear()
	_on_arrive = on_arrive
	var room := get_tree().current_scene
	if room and room.has_method("plan_path"):
		var planned: PackedVector2Array = room.plan_path(global_position, world_target)
		for p in planned:
			_move_path.append(p)
		_advance_move_path()
	else:
		target_position = world_target
		moving = true
		set_state(PlayerState.WALKING)
	if footsteps and footsteps.stream:
		footsteps.play()

func _advance_move_path() -> void:
	if _move_path.is_empty():
		_finish_path()
		return
	var nxt := _move_path[0]
	if global_position.distance_to(nxt) < 24:
		_move_path.pop_front()
		_advance_move_path()
		return
	var room := get_tree().current_scene
	if room and room.has_method("is_water_crossing") and room.is_water_crossing(global_position, nxt):
		_start_hop(nxt)
	else:
		_restore_collision_mask()
		target_position = nxt
		moving = true
		set_state(PlayerState.WALKING)

func _start_hop(dest: Vector2) -> void:
	_hopping = true
	moving = false
	velocity = Vector2.ZERO
	collision_mask = 0
	_hop_ground_y = global_position.y
	if animated_sprite:
		animated_sprite.flip_h = dest.x < global_position.x
	set_state(PlayerState.WALKING)
	var start := global_position
	var dist := start.distance_to(dest)
	var duration := clampf(dist / HOP_SPEED, 0.28, 0.65)
	var height := clampf(dist * 0.22, HOP_HEIGHT_MIN, HOP_HEIGHT_MAX)
	if _hop_tween:
		_hop_tween.kill()
	_hop_tween = create_tween()
	_hop_tween.tween_method(_hop_step.bind(start, dest, height), 0.0, 1.0, duration)
	_hop_tween.finished.connect(_on_hop_finished, CONNECT_ONE_SHOT)

func _hop_step(t: float, start: Vector2, dest: Vector2, height: float) -> void:
	var p := start.lerp(dest, t)
	_hop_ground_y = p.y
	p.y -= sin(t * PI) * height
	global_position = p

func _on_hop_finished() -> void:
	if not _hopping:
		return
	_hopping = false
	if not _move_path.is_empty():
		global_position = _move_path[0]
		_move_path.pop_front()
	_advance_move_path()

func _cancel_hop() -> void:
	var was_hopping := _hopping
	_hopping = false
	if _hop_tween:
		_hop_tween.kill()
		_hop_tween = null
	_restore_collision_mask()
	if was_hopping:
		var room := get_tree().current_scene
		if room and room.has_method("snap_out_of_water"):
			global_position = room.snap_out_of_water(global_position)

func _restore_collision_mask() -> void:
	collision_mask = _collision_mask_default

func _finish_path() -> void:
	var room := get_tree().current_scene
	if room and room.has_method("snap_out_of_water"):
		global_position = room.snap_out_of_water(global_position)
	var cb := _on_arrive
	_on_arrive = Callable()
	_stop_movement(false)
	if cb.is_valid():
		cb.call()

func _stop_movement(cancel_hop: bool) -> void:
	moving = false
	velocity = Vector2.ZERO
	_move_path.clear()
	if cancel_hop:
		_on_arrive = Callable()
		_cancel_hop()
	else:
		_restore_collision_mask()
	set_state(PlayerState.IDLE)

func _physics_process(_delta) -> void:
	if _hopping:
		return
	if moving:
		move_towards_target()

func _process(_delta) -> void:
	_apply_depth_scale()

func _apply_depth_scale() -> void:
	if animated_sprite == null:
		return
	var room := get_tree().current_scene
	if room == null or not room.has_method("depth_scale_for_y"):
		return
	var y := _hop_ground_y if _hopping else global_position.y
	_depth_factor = room.depth_scale_for_y(y)
	animated_sprite.scale = _base_sprite_scale * _depth_factor
	animated_sprite.position.y = _sprite_half_height() * _base_sprite_scale.y * (1.0 - _depth_factor)

func _sprite_half_height() -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return 0.0
	var frames: SpriteFrames = animated_sprite.sprite_frames
	var anim: StringName = animated_sprite.animation
	if not frames.has_animation(anim):
		return 0.0
	var tex := frames.get_frame_texture(anim, animated_sprite.frame)
	if tex == null:
		return 0.0
	return tex.get_height() * 0.5

func move_towards_target() -> void:
	var direction = target_position - global_position
	var distance = direction.length()

	if distance < 6:
		moving = false
		velocity = Vector2.ZERO
		if not _move_path.is_empty() and global_position.distance_to(_move_path[0]) < 16:
			_move_path.pop_front()
			_advance_move_path()
		else:
			_finish_path()
		return

	velocity = direction.normalized() * SPEED * _depth_factor
	animated_sprite.flip_h = velocity.x < 0
	set_state(PlayerState.WALKING)

	var collision = move_and_collide(velocity * get_physics_process_delta_time())
	if collision:
		moving = false
		velocity = Vector2.ZERO
		_on_arrive = Callable()
		_move_path.clear()
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
			_play_walk()
			update_walk_state(true)
		PlayerState.IDLE:
			_play_idle()
			update_walk_state(false)

func _play_idle() -> void:
	if animated_sprite == null:
		return
	animated_sprite.play(_mask_anim("idle"))

func _play_walk() -> void:
	if animated_sprite == null:
		return
	animated_sprite.play(_mask_anim("walk"))

func _mask_anim(kind: String) -> String:
	var pair: Array = MASK_ANIMS.get(StoryFlags.mascara_equipada, ["poroto_idle", "poroto_walk"])
	var idle_name: String = pair[0]
	var walk_name: String = pair[1]
	var frames: SpriteFrames = animated_sprite.sprite_frames
	if kind == "walk":
		if frames.has_animation(walk_name):
			return walk_name
		if frames.has_animation(idle_name):
			return idle_name
		return "poroto_walk"
	if frames.has_animation(idle_name):
		return idle_name
	return "poroto_idle"
