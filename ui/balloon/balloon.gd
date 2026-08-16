extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.


## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## If all other input is blocked as long as dialogue is shown.
@export var will_block_other_input: bool = true

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## A sound player for voice lines (if they exist).
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()
var _speech: MarginContainer
var _speech_width := 440.0
var _speaker: WeakRef = null

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## Indicator to show that player can progress dialogue.
@onready var progress: Polygon2D = %Progress


func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)
	_speech = balloon.get_node_or_null("MarginContainer") as MarginContainer
	_adapt_for_device()
	if DisplayAdapt:
		DisplayAdapt.adapted.connect(_adapt_for_device)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()


func _adapt_for_device() -> void:
	if balloon == null:
		return
	if _speech == null:
		_speech = balloon.get_node_or_null("MarginContainer") as MarginContainer
	var ui := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	var touch := DisplayAdapt.is_touch_device if DisplayAdapt else false
	_speech_width = 520.0 * ui if touch else 440.0
	if _speech and dialogue_label and character_label:
		_speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dialogue_label.custom_minimum_size = Vector2(_speech_width, 0)
		dialogue_label.fit_content = true
		dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dialogue_label.add_theme_constant_override("outline_size", int(8 * ui) if touch else 8)
		character_label.add_theme_constant_override("outline_size", int(8 * ui) if touch else 8)
	if balloon.theme:
		balloon.theme.default_font_size = int(34 * ui) if touch else 32
	var responses: Control = balloon.get_node_or_null("ResponsesMenu")
	if responses:
		var half_w := 400.0 * ui if touch else 340.0
		responses.offset_left = -half_w
		responses.offset_right = half_w
		# More vertical space so choice taps don't miss on phones.
		var sep := int(14 * ui) if touch else 4
		responses.add_theme_constant_override("separation", sep)
		var example := responses.get_node_or_null("ResponseExample") as Button
		if example:
			var min_h := 60.0 * ui if touch else 44.0
			example.custom_minimum_size = Vector2(0, min_h)
			example.add_theme_font_size_override("font_size", int(32 * ui) if touch else 28)
			var pad_y := int(12 * ui) if touch else 6
			var pad_x := int(16 * ui) if touch else 10
			for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
				var base := example.get_theme_stylebox(style_name)
				if base == null:
					continue
				var styled := base.duplicate() as StyleBox
				if styled is StyleBoxFlat:
					var flat := styled as StyleBoxFlat
					flat.content_margin_top = pad_y
					flat.content_margin_bottom = pad_y
					flat.content_margin_left = pad_x
					flat.content_margin_right = pad_x
				example.add_theme_stylebox_override(style_name, styled)


func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")
		if balloon.visible:
			_place_next_to_speaker()


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	if will_block_other_input:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	var speaker := dialogue_line.character
	if speaker == "Detective" and StoryFlags:
		speaker = StoryFlags.get_detective_speaker_name()
	character_label.auto_translate = false
	character_label.text = "[b]%s[/b]" % tr(speaker)
	_speaker = weakref(_find_speaker_node(dialogue_line.character))

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses
	_polish_response_buttons()

	# Show our balloon
	balloon.show()
	will_hide_balloon = false
	_place_next_to_speaker()

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for next line
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


func _polish_response_buttons() -> void:
	if responses_menu == null:
		return
	var touch := DisplayAdapt != null and DisplayAdapt.is_touch_device
	var ui := DisplayAdapt.ui_scale if DisplayAdapt else 1.0
	var min_h := (60.0 if touch else 44.0) * ui
	var font_size := int((32 if touch else 28) * ui)
	for child in responses_menu.get_children():
		if child == responses_menu.response_template:
			continue
		if child is Button:
			var btn := child as Button
			btn.custom_minimum_size = Vector2(0, min_h)
			btn.add_theme_font_size_override("font_size", font_size)
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## Go to the next line
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


func _find_speaker_node(character: String) -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var key := character.strip_edges()
	if key.is_empty() or key.begins_with("Detective"):
		return tree.get_first_node_in_group("player") as Node2D
	for node in tree.get_nodes_in_group("interactable"):
		if not (node is Node2D):
			continue
		if not node.has_method("get_interact_label"):
			continue
		var label := ""
		if "interact_label" in node:
			label = str(node.interact_label)
		if label.is_empty():
			label = str(node.get_interact_label())
		if label == key:
			return node as Node2D
	return tree.get_first_node_in_group("player") as Node2D


func _speaker_extent(node: Node2D) -> Vector2:
	var spr := node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null:
		spr = node.find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
	if spr and spr.sprite_frames:
		var anim := spr.animation
		if anim != "" and spr.sprite_frames.has_animation(anim):
			var tex := spr.sprite_frames.get_frame_texture(anim, spr.frame)
			if tex:
				return tex.get_size() * spr.global_scale.abs()
	return Vector2(80, 160)


func _place_next_to_speaker() -> void:
	if _speech == null or balloon == null:
		return
	var speaker_node: Node2D = null
	if _speaker != null:
		speaker_node = _speaker.get_ref() as Node2D
	if speaker_node == null or not is_instance_valid(speaker_node):
		speaker_node = _find_speaker_node(dialogue_line.character if is_instance_valid(dialogue_line) else "")
		_speaker = weakref(speaker_node) if speaker_node else null
	if speaker_node == null:
		return

	_speech.reset_size()
	var size := _speech.get_combined_minimum_size()
	if size.x < 8.0:
		size.x = _speech_width
	if size.y < 8.0:
		size.y = 80.0

	var view := get_viewport().get_visible_rect().size
	var safe := DisplayAdapt.safe_margin if DisplayAdapt else Vector4.ZERO
	var pad := Vector2(16.0 + safe.x, 16.0 + safe.y)
	var pad_br := Vector2(16.0 + safe.z, 16.0 + safe.w)
	var extent := _speaker_extent(speaker_node)
	var origin := speaker_node.get_global_transform_with_canvas().origin
	var prefer_right := origin.x < view.x * 0.55
	var pos := Vector2.ZERO
	if prefer_right:
		pos = origin + Vector2(extent.x * 0.45, -extent.y * 0.85)
	else:
		pos = origin + Vector2(-extent.x * 0.45 - size.x, -extent.y * 0.85)

	pos.x = clampf(pos.x, pad.x, maxf(pad.x, view.x - size.x - pad_br.x))
	pos.y = clampf(pos.y, pad.y, maxf(pad.y, view.y - size.y - pad_br.y))
	_speech.position = pos
	_speech.size = size


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	if not _mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion
