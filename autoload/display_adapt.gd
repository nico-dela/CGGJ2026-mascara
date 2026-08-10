extends Node
## Scales UI and adapts input for phones/tablets while keeping the 1920x1080 game world.

signal adapted

const BASE_SIZE := Vector2(1920, 1080)

var is_touch_device := false
var ui_scale := 1.0
var safe_margin := Vector4.ZERO  # left, top, right, bottom in design pixels

func _ready() -> void:
	_detect_device()
	_apply()
	get_tree().root.size_changed.connect(_apply)
	call_deferred("_apply")

func _detect_device() -> void:
	# Prefer OS/mobile features over raw touchscreen availability so a
	# touchscreen laptop still gets a desktop cursor.
	is_touch_device = (
		OS.has_feature("mobile")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
		or OS.has_feature("android")
		or OS.has_feature("ios")
	)

func _apply() -> void:
	_detect_device()
	_update_safe_margin()
	_update_ui_scale()
	_update_cursor()
	adapted.emit()

func _update_safe_margin() -> void:
	# Desktop (incl. web en PC) no necesita insets de notch; además en
	# navegadores get_display_safe_area() no mapea bien al canvas del juego.
	if not is_touch_device:
		safe_margin = Vector4.ZERO
		return

	# En web móvil el safe-area del OS suele incluir la UI del browser y
	# desfasar controles respecto del viewport 1920x1080.
	if OS.has_feature("web"):
		safe_margin = Vector4(24, 20, 24, 48)
		return

	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		safe_margin = Vector4(24, 16, 24, 24)
		return

	var safe := DisplayServer.get_display_safe_area()
	var screen := Rect2i(Vector2i.ZERO, DisplayServer.screen_get_size())
	var left := maxf(0.0, float(safe.position.x - screen.position.x))
	var top := maxf(0.0, float(safe.position.y - screen.position.y))
	var right := maxf(0.0, float(screen.end.x - safe.end.x))
	var bottom := maxf(0.0, float(screen.end.y - safe.end.y))

	var scale_x := BASE_SIZE.x / maxf(1.0, float(window_size.x))
	var scale_y := BASE_SIZE.y / maxf(1.0, float(window_size.y))
	safe_margin = Vector4(
		maxf(24.0, left * scale_x),
		maxf(16.0, top * scale_y),
		maxf(24.0, right * scale_x),
		maxf(24.0, bottom * scale_y)
	)
	# Evita márgenes absurdos si el safe-area del OS no coincide col canvas.
	safe_margin.x = minf(safe_margin.x, 120.0)
	safe_margin.y = minf(safe_margin.y, 120.0)
	safe_margin.z = minf(safe_margin.z, 120.0)
	safe_margin.w = minf(safe_margin.w, 160.0)

func _update_ui_scale() -> void:
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size == Vector2.ZERO:
		ui_scale = 1.0
		return
	var short_side := minf(window_size.x, window_size.y)
	if short_side <= 500.0:
		ui_scale = 1.35
	elif short_side <= 800.0:
		ui_scale = 1.2
	elif is_touch_device:
		ui_scale = 1.1
	else:
		ui_scale = 1.0

const CURSOR_DISPLAY_SIZE := 32

func _update_cursor() -> void:
	if is_touch_device:
		Input.set_custom_mouse_cursor(null)
		return

	var source := load("res://assets/art/ui/cursor.png") as Texture2D
	if source == null:
		return

	var img: Image = source.get_image()
	if img == null:
		return

	# Source art is 96x96; show a pixel-scaled cursor on desktop/laptop.
	img.resize(CURSOR_DISPLAY_SIZE, CURSOR_DISPLAY_SIZE, Image.INTERPOLATE_NEAREST)
	var tex := ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(4, 4))

func apply_safe_margins_to(control: Control) -> void:
	if control == null:
		return
	if control is MarginContainer:
		control.add_theme_constant_override("margin_left", int(safe_margin.x))
		control.add_theme_constant_override("margin_top", int(safe_margin.y))
		control.add_theme_constant_override("margin_right", int(safe_margin.z))
		control.add_theme_constant_override("margin_bottom", int(safe_margin.w))
	else:
		control.offset_left = safe_margin.x
		control.offset_top = safe_margin.y
		control.offset_right = -safe_margin.z
		control.offset_bottom = -safe_margin.w

func touch_slot_size() -> Vector2:
	return Vector2(96, 96) * ui_scale if is_touch_device else Vector2(72, 72)

func is_portrait() -> bool:
	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return false
	return window_size.y > window_size.x
