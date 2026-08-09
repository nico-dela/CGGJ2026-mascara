extends Control

const CREDITS_MUSIC := preload("res://assets/audio/music/musica_creditos.ogg")

func _ready() -> void:
	if AudioManager:
		AudioManager.fade_out_ambient()
		AudioManager.set_music(CREDITS_MUSIC)
	if has_node("BackButton"):
		$BackButton.pressed.connect(_on_back_pressed)
	_adapt_layout()
	if DisplayAdapt:
		DisplayAdapt.adapted.connect(_adapt_layout)

func _adapt_layout() -> void:
	if has_node("BackButton"):
		var btn: Button = $BackButton
		btn.custom_minimum_size = Vector2(200, 56) * DisplayAdapt.ui_scale

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		return
	# Only close on empty-background clicks, not every click (buttons still work).
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var focus := get_viewport().gui_get_focus_owner()
		if focus == null or not is_ancestor_of(focus):
			_on_back_pressed()

func _on_back_pressed() -> void:
	if AudioManager:
		AudioManager.stop_music()
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	else:
		queue_free()
