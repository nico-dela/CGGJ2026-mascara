extends Node

## Persisted volume, fullscreen and language. Loads English CSV at boot.

signal locale_changed(locale: String)
signal fullscreen_changed(enabled: bool)
signal volume_changed(value: float)

const SETTINGS_PATH := "user://settings.cfg"
const CSV_PATHS := [
	"res://locale/ui.csv",
	"res://locale/dialogue.csv",
]
const LOCALES := ["es", "en"]
## Keep imported CSV translations in the export pack (web remaps them).
const _UI_TRANSLATION: Resource = preload("res://locale/ui.csv")
const _DIALOGUE_TRANSLATION: Resource = preload("res://locale/dialogue.csv")

var volume: float = 50.0
var fullscreen: bool = false
var language: String = "es"

func _ready() -> void:
	_load_translations()
	_load_settings()
	apply_all()

func apply_all() -> void:
	_apply_volume()
	_apply_fullscreen()
	_apply_locale()

func is_english() -> bool:
	return language.begins_with("en")

func language_display_name() -> String:
	return "English" if is_english() else "Español"

func set_language(locale: String) -> void:
	if locale not in LOCALES:
		locale = "es"
	language = locale
	_apply_locale()
	_save_settings()
	locale_changed.emit(language)

func toggle_language() -> void:
	set_language("es" if is_english() else "en")

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	_save_settings()
	fullscreen_changed.emit(fullscreen)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 100.0)
	_apply_volume()
	_save_settings()
	volume_changed.emit(volume)

func _apply_volume() -> void:
	var linear := volume / 100.0
	var db := -80.0 if linear <= 0.0 else 20.0 * (log(linear) / log(10.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _apply_fullscreen() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_locale() -> void:
	TranslationServer.set_locale(language)
	var tree := get_tree()
	if tree and tree.root:
		tree.root.propagate_notification(CanvasItem.NOTIFICATION_TRANSLATION_CHANGED)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	volume = clampf(float(cfg.get_value("audio", "master", 50.0)), 0.0, 100.0)
	fullscreen = bool(cfg.get_value("video", "fullscreen", false))
	var saved := str(cfg.get_value("locale", "language", "es"))
	language = saved if saved in LOCALES else "es"

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master", volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("locale", "language", language)
	cfg.save(SETTINGS_PATH)

func _load_translations() -> void:
	# On web export the CSV is remapped to a Translation resource; FileAccess cannot read it.
	var added := false
	for res in [_UI_TRANSLATION, _DIALOGUE_TRANSLATION]:
		if res is Translation:
			TranslationServer.add_translation(res)
			added = true
	if added:
		return
	for path in CSV_PATHS:
		var trans := _load_translation_resource(path)
		if trans:
			TranslationServer.add_translation(trans)
			continue
		var parsed := Translation.new()
		parsed.locale = "en"
		_load_csv_into(parsed, path)
		if parsed.get_message_count() > 0:
			TranslationServer.add_translation(parsed)

func _load_translation_resource(path: String) -> Translation:
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is Translation:
			return res
	var generated := "%s.en.translation" % path.get_basename()
	if ResourceLoader.exists(generated):
		var res := load(generated)
		if res is Translation:
			return res
	return null

func _load_csv_into(translation: Translation, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("GameSettings: missing translation file %s" % path)
		return
	var header := file.get_csv_line()
	var key_i := 0
	var en_i := 1
	for i in header.size():
		match header[i]:
			"keys":
				key_i = i
			"en":
				en_i = i
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() <= maxi(key_i, en_i):
			continue
		var key := row[key_i]
		var en := row[en_i]
		if key.is_empty() or key == "keys" or en.is_empty():
			continue
		translation.add_message(key, en)
		translation.add_message(key, en, "dialogue")
