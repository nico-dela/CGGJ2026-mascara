extends RoomSetup

## River / ivy stretch split from the old panoramic exterior.

const AMB_RIO := preload("res://assets/audio/ambience/ambiente_rio.ogg")
const AMB_BOSQUE := preload("res://assets/audio/ambience/ambiente_bosque.ogg")
const STEPS_DIRT := preload("res://assets/audio/sfx/pasos_tierra.ogg")
const ROOM_WIDTH := 2224.0
const STONE_IDS := ["Stone_Left", "Stone_Mid", "Stone_Right"]
const ARRIVE_RADIUS := 28.0

@export var depth_y_near := 960.0
@export var depth_y_far := 720.0
@export var depth_scale_near := 1.0
@export var depth_scale_far := 0.5

func depth_scale_for_y(y: float) -> float:
	var lo := minf(depth_scale_near, depth_scale_far)
	var hi := maxf(depth_scale_near, depth_scale_far)
	return clampf(remap(y, depth_y_near, depth_y_far, depth_scale_near, depth_scale_far), lo, hi)

func _on_room_ready() -> void:
	AudioManager.start_music()
	if StoryFlags.is_paso_abierto():
		AudioManager.set_ambient(AMB_RIO)
	else:
		AudioManager.set_ambient(AMB_BOSQUE)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_camera_limits"):
		player.apply_camera_limits(0, 0, int(ROOM_WIDTH), 1080)
	if player and player.has_method("set_footstep_stream"):
		player.set_footstep_stream(STEPS_DIRT)
	if player and _in_water(player.global_position):
		player.global_position = snap_out_of_water(player.global_position)
	_sync_pescador()
	if StoryFlags and not StoryFlags.paso_abierto_signal.is_connected(_on_paso_abierto):
		StoryFlags.paso_abierto_signal.connect(_on_paso_abierto)

func plan_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var stones := _stones()
	if stones.is_empty():
		return PackedVector2Array([to])
	if _in_water(to):
		to = _nearest_bank_stone(to, stones)
	if not _in_water(from) and not is_water_crossing(from, to):
		return PackedVector2Array([to])
	var i0 := _nearest_index(from, stones)
	var i1 := _nearest_index(to, stones)
	if _in_water(to):
		i1 = _nearest_bank_index(to, stones)
		to = stones[i1]
	var path := PackedVector2Array()
	if from.distance_to(stones[i0]) > ARRIVE_RADIUS:
		path.append(stones[i0])
	if i0 < i1:
		for i in range(i0 + 1, i1 + 1):
			path.append(stones[i])
	elif i0 > i1:
		for i in range(i0 - 1, i1 - 1, -1):
			path.append(stones[i])
	if to.distance_to(stones[i1]) > ARRIVE_RADIUS and not is_water_crossing(stones[i1], to):
		path.append(to)
	if path.is_empty():
		path.append(to)
	return path

func is_water_crossing(from: Vector2, to: Vector2) -> bool:
	if from.distance_to(to) < 4.0:
		return false
	if _in_water(from) or _in_water(to):
		return true
	for poly in _water_polygons():
		if _segment_hits_polygon(from, to, poly):
			return true
	return false

func snap_out_of_water(p: Vector2) -> Vector2:
	if not _in_water(p):
		return p
	var stones := _stones()
	if stones.is_empty():
		return p
	return _nearest_bank_stone(p, stones)

func _sync_pescador() -> void:
	var pescador := get_node_or_null("Pescador")
	if pescador == null:
		return
	var show_river := StoryFlags.is_bartender_expuesto() or StoryFlags.caso_resuelto
	pescador.visible = show_river
	pescador.monitoring = show_river
	pescador.monitorable = show_river
	pescador.input_pickable = show_river
	if show_river and pescador.has_method("_aplicar_estado_rio"):
		pescador.call("_aplicar_estado_rio")

func _on_paso_abierto() -> void:
	AudioManager.set_ambient(AMB_RIO)

func _exit_tree() -> void:
	AudioManager.stop_music()

func _stones() -> Array[Vector2]:
	var pts: Array[Vector2] = []
	var spawn := get_node_or_null("SpawnPoints")
	if spawn == null:
		return pts
	for id in STONE_IDS:
		var marker := spawn.get_node_or_null(id) as Node2D
		if marker:
			pts.append(marker.global_position)
	return pts

func _water_polygons() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var block := get_node_or_null("RiverBlock")
	if block == null:
		return result
	for child in block.get_children():
		if child is CollisionPolygon2D and not (child as CollisionPolygon2D).disabled:
			var xform: Transform2D = (child as CollisionPolygon2D).global_transform
			var pts := PackedVector2Array()
			for p in (child as CollisionPolygon2D).polygon:
				pts.append(xform * p)
			if pts.size() >= 3:
				result.append(pts)
	return result

func _in_water(p: Vector2) -> bool:
	for poly in _water_polygons():
		if Geometry2D.is_point_in_polygon(p, poly):
			return true
	return false

func _segment_hits_polygon(a: Vector2, b: Vector2, poly: PackedVector2Array) -> bool:
	var n := poly.size()
	for i in n:
		var hit = Geometry2D.segment_intersects_segment(a, b, poly[i], poly[(i + 1) % n])
		if hit != null:
			return true
	return false

func _nearest_index(p: Vector2, stones: Array[Vector2]) -> int:
	var best := 0
	var best_d := p.distance_squared_to(stones[0])
	for i in range(1, stones.size()):
		var d := p.distance_squared_to(stones[i])
		if d < best_d:
			best = i
			best_d = d
	return best

func _nearest_bank_index(p: Vector2, stones: Array[Vector2]) -> int:
	if stones.size() < 3:
		return _nearest_index(p, stones)
	if p.distance_squared_to(stones[0]) <= p.distance_squared_to(stones[stones.size() - 1]):
		return 0
	return stones.size() - 1

func _nearest_bank_stone(p: Vector2, stones: Array[Vector2]) -> Vector2:
	return stones[_nearest_bank_index(p, stones)]
