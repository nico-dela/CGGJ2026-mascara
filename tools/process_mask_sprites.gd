extends SceneTree
## One-shot: crop MASCARAS.png and generate NPC walk sheets from idle.

const ROOT := "res://assets/art"
const FRAME_W := 32
const FRAME_H := 64
const IDLE_FRAMES := 4
const WALK_FRAMES := 6

func _init() -> void:
	_crop_masks()
	_make_walk("characters/mozo_idle.png", "characters/mozo_walk.png")
	_make_walk("characters/poli_idle.png", "characters/poli_walk.png")
	_make_walk("characters/Vendedor_Idle.png", "characters/vendedor_walk.png")
	print("process_mask_sprites: done")
	quit()

func _crop_masks() -> void:
	var sheet := _load_image("%s/items/MASCARAS.png" % ROOT)
	if sheet == null:
		push_error("Could not load MASCARAS.png")
		return
	print("MASCARAS.png %sx%s %s" % [sheet.get_width(), sheet.get_height(), sheet.get_format()])
	var names := [
		"mascara_poli.png",
		"mascara_lenador.png",
		"mascara_vendedor.png",
		"mascara_sabio.png",
		"mascara_mozo.png",
	]
	for i in names.size():
		var crop := Image.create(FRAME_W, 32, false, Image.FORMAT_RGBA8)
		crop.fill(Color(0, 0, 0, 0))
		crop.blit_rect(sheet, Rect2i(i * FRAME_W, 0, FRAME_W, 32), Vector2i.ZERO)
		var path := "%s/items/%s" % [ROOT, names[i]]
		var err := crop.save_png(path)
		print("  crop %s -> %s err=%s" % [names[i], path, err])

func _make_walk(idle_rel: String, walk_rel: String) -> void:
	var idle := _load_image("%s/%s" % [ROOT, idle_rel])
	if idle == null:
		push_error("Could not load %s" % idle_rel)
		return
	print("%s %sx%s" % [idle_rel, idle.get_width(), idle.get_height()])
	var scales := [
		Vector2(1.00, 1.00),
		Vector2(1.06, 0.94),
		Vector2(1.14, 0.84),
		Vector2(1.06, 0.94),
		Vector2(1.00, 1.00),
		Vector2(0.94, 1.08),
	]
	var idle_idx := [0, 1, 2, 3, 2, 1]
	var out := Image.create(FRAME_W * WALK_FRAMES, FRAME_H, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for i in WALK_FRAMES:
		var src := Image.create(FRAME_W, FRAME_H, false, Image.FORMAT_RGBA8)
		src.fill(Color(0, 0, 0, 0))
		src.blit_rect(idle, Rect2i(idle_idx[i] * FRAME_W, 0, FRAME_W, FRAME_H), Vector2i.ZERO)
		var frame := _squash_frame(src, scales[i].x, scales[i].y)
		out.blit_rect(frame, Rect2i(0, 0, FRAME_W, FRAME_H), Vector2i(i * FRAME_W, 0))
	var path := "%s/%s" % [ROOT, walk_rel]
	var err := out.save_png(path)
	print("  walk %s err=%s" % [path, err])

func _squash_frame(src: Image, scale_x: float, scale_y: float) -> Image:
	var nw := maxi(1, int(round(float(FRAME_W) * scale_x)))
	var nh := maxi(1, int(round(float(FRAME_H) * scale_y)))
	var scaled := Image.create(FRAME_W, FRAME_H, false, Image.FORMAT_RGBA8)
	scaled.copy_from(src)
	scaled.resize(nw, nh, Image.INTERPOLATE_NEAREST)
	var out := Image.create(FRAME_W, FRAME_H, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var x := int((FRAME_W - nw) / 2.0)
	var y := FRAME_H - nh
	out.blit_rect(scaled, Rect2i(0, 0, nw, nh), Vector2i(x, y))
	return out

func _load_image(path: String) -> Image:
	if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
		# Absolute fallback via user filesystem for editor-imported assets.
		pass
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_error("Image.load failed %s err=%s" % [path, err])
		return null
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img
