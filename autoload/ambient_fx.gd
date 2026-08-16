extends CanvasLayer

## Soft global atmosphere: breathing vignette + per-room motion helpers.

const SWAY_SHADER := preload("res://assets/shaders/foliage_sway.gdshader")
const VIGNETTE_SHADER := preload("res://assets/shaders/vignette_breathe.gdshader")
const FLICKER_SHADER := preload("res://assets/shaders/interior_flicker.gdshader")
const HAZE_SHADER := preload("res://assets/shaders/haze_drift.gdshader")

var _vignette: ColorRect
var _room_fx_root: Node2D
var _pixel_tex: Texture2D

func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_vignette()
	if SceneRouter and SceneRouter.has_signal("scene_changed"):
		SceneRouter.scene_changed.connect(_on_scene_changed)
	call_deferred("_refresh_for_current_scene")

func _build_vignette() -> void:
	var root := Control.new()
	root.name = "VignetteRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_vignette = ColorRect.new()
	_vignette.name = "Vignette"
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Fail-safe: if the shader fails to compile, stay invisible (not solid white).
	_vignette.color = Color(0, 0, 0, 0)
	_vignette.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = VIGNETTE_SHADER
	_vignette.material = mat
	root.add_child(_vignette)

func _on_scene_changed(_path: String) -> void:
	await get_tree().process_frame
	_refresh_for_current_scene()

func _refresh_for_current_scene() -> void:
	_clear_room_fx()
	var scene := get_tree().current_scene
	if scene == null:
		_set_vignette_visible(false)
		return
	var path := str(scene.scene_file_path)
	var in_room := path.begins_with("res://scenes/rooms/")
	_set_vignette_visible(in_room)
	if not in_room:
		return
	_room_fx_root = Node2D.new()
	_room_fx_root.name = "AmbientRoomFx"
	scene.add_child(_room_fx_root)
	_apply_foliage_sway(scene)
	match path.get_file():
		"room_road.tscn":
			_add_dust(_room_fx_root, Rect2(200, 200, 1520, 700), 18)
			_add_haze(_room_fx_root, Rect2(0, 80, 1920, 520), 0.06)
		"room_1.tscn":
			_add_dust(_room_fx_root, Rect2(400, 180, 4000, 750), 24)
			_add_haze(_room_fx_root, Rect2(0, 40, 4397, 480), 0.05)
		"room_4.tscn":
			_add_dust(_room_fx_root, Rect2(80, 180, 2000, 750), 18)
			_add_haze(_room_fx_root, Rect2(0, 40, 2224, 480), 0.06)
		"room_2.tscn", "room_3.tscn":
			_apply_interior_flicker(scene)
		_:
			pass

func _set_vignette_visible(show_it: bool) -> void:
	if _vignette:
		_vignette.visible = show_it

func _clear_room_fx() -> void:
	if _room_fx_root != null and is_instance_valid(_room_fx_root):
		_room_fx_root.queue_free()
	_room_fx_root = null

func _apply_foliage_sway(scene: Node) -> void:
	var targets: Array[Node] = []
	var tree_l := scene.get_node_or_null("TreeLeft")
	var tree_r := scene.get_node_or_null("TreeRight")
	if tree_l:
		targets.append(tree_l)
	if tree_r:
		targets.append(tree_r)
	var hiedra := scene.get_node_or_null("HiedraArea/Sprite2D")
	if hiedra:
		targets.append(hiedra)
	var phase := 0.0
	for node in targets:
		if node is CanvasItem:
			var mat := ShaderMaterial.new()
			mat.shader = SWAY_SHADER
			mat.set_shader_parameter("sway_strength", 5.5 if str(node.name).begins_with("Tree") else 4.0)
			mat.set_shader_parameter("sway_speed", 0.95 + phase * 0.15)
			mat.set_shader_parameter("sway_phase", phase)
			mat.set_shader_parameter("secondary_strength", 1.8)
			(node as CanvasItem).material = mat
			phase += 1.7

func _apply_interior_flicker(scene: Node) -> void:
	var bg := scene.get_node_or_null("BackgroundSprite") as CanvasItem
	if bg == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = FLICKER_SHADER
	if str(scene.scene_file_path).ends_with("room_3.tscn"):
		mat.set_shader_parameter("warm_tint", Color(1.0, 0.94, 0.86, 1.0))
		mat.set_shader_parameter("pulse_amount", 0.04)
		mat.set_shader_parameter("flicker_amount", 0.025)
	else:
		mat.set_shader_parameter("warm_tint", Color(0.96, 0.97, 1.0, 1.0))
		mat.set_shader_parameter("pulse_amount", 0.025)
		mat.set_shader_parameter("flicker_amount", 0.012)
	bg.material = mat

func _add_dust(parent: Node2D, area: Rect2, amount: int) -> void:
	var particles := CPUParticles2D.new()
	particles.name = "DustMotes"
	particles.z_index = 8
	particles.amount = amount
	particles.lifetime = 9.0
	particles.preprocess = 4.0
	particles.texture = _white_pixel()
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = area.size * 0.5
	particles.position = area.position + area.size * 0.5
	particles.direction = Vector2(0.15, -1.0)
	particles.spread = 55.0
	particles.gravity = Vector2(0, -4)
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 14.0
	particles.angular_velocity_min = -12.0
	particles.angular_velocity_max = 12.0
	particles.scale_amount_min = 1.2
	particles.scale_amount_max = 2.6
	particles.color = Color(1.0, 0.95, 0.8, 0.28)
	parent.add_child(particles)

func _add_haze(parent: Node2D, area: Rect2, alpha: float) -> void:
	var haze := Sprite2D.new()
	haze.name = "HazeDrift"
	haze.centered = false
	haze.position = area.position
	haze.z_index = 6
	# Transparent pixel: if the shader fails, haze stays invisible instead of a white wall.
	haze.texture = _clear_pixel()
	haze.scale = area.size
	var mat := ShaderMaterial.new()
	mat.shader = HAZE_SHADER
	mat.set_shader_parameter("haze_alpha", alpha)
	haze.material = mat
	parent.add_child(haze)

func _white_pixel() -> Texture2D:
	if _pixel_tex != null:
		return _pixel_tex
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_pixel_tex = ImageTexture.create_from_image(img)
	return _pixel_tex

func _clear_pixel() -> Texture2D:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	return ImageTexture.create_from_image(img)
