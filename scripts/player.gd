extends CharacterBody2D

const SPEED = 500.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var footsteps = $Footsteps
#@onready var leitmotiv = $Leitmotiv

enum PlayerState { IDLE, WALKING }
var state := PlayerState.IDLE

var target_position = Vector2()
var moving = false
var is_walking := false

var dialogue_active := false

func _ready():
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	animated_sprite.play("poroto_idle")
	add_to_group("player")
	set_process_input(true)
	
	if GameManager.next_spawn_id != "":
		var spawn_points = get_tree().current_scene.get_node("SpawnPoints")
		if spawn_points.has_node(GameManager.next_spawn_id):
			global_position = spawn_points.get_node(GameManager.next_spawn_id).global_position
		GameManager.next_spawn_id = ""

func _on_dialogue_started(_resource):
	dialogue_active = true
	moving = false
	velocity = Vector2.ZERO
	set_state(PlayerState.IDLE)
	
func _on_dialogue_ended(_resource):
	dialogue_active = false

func _input(event):
	if dialogue_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_position = get_global_mouse_position()
		moving = true

func _physics_process(_delta):
	if moving:
		move_towards_target()

func move_towards_target():
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
	
func update_walk_state(walking: bool):
	if walking and not is_walking:
		footsteps.play()
	elif not walking and is_walking:
		footsteps.stop()

	is_walking = walking
	
func set_state(new_state: PlayerState):
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
