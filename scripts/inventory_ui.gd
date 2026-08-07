extends Control

@onready var panel: PanelContainer = $Panel
@onready var hbox: HBoxContainer = $Panel/Margin/HBoxContainer
@onready var margin: MarginContainer = $Panel/Margin

var slot_scene = preload("res://scenes/inventory_slot.tscn")

func _ready() -> void:
	DisplayAdapt.adapted.connect(_apply_layout)
	_apply_layout()
	refresh()
	Inventory.inventory_changed.connect(refresh)

func _apply_layout() -> void:
	var safe := DisplayAdapt.safe_margin
	var ui := DisplayAdapt.ui_scale
	var slot := DisplayAdapt.touch_slot_size()
	var pad := 10.0 * ui
	var gap := 10.0 * ui
	var right := 16.0 + safe.z
	var bottom := 16.0 + safe.w
	var count := maxi(Inventory.inventory.size(), 1)
	var bar_w := count * slot.x + (count - 1) * gap + pad * 2.0
	var bar_h := slot.y + pad * 2.0

	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -(right + bar_w + 8.0)
	offset_right = 0.0
	offset_top = -(bar_h + bottom + 8.0)
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if panel:
		panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		panel.offset_left = -(right + bar_w)
		panel.offset_right = -right
		panel.offset_top = -(bar_h + bottom)
		panel.offset_bottom = -bottom
		panel.mouse_filter = Control.MOUSE_FILTER_STOP

	if margin:
		margin.add_theme_constant_override("margin_left", int(pad))
		margin.add_theme_constant_override("margin_right", int(pad))
		margin.add_theme_constant_override("margin_top", int(pad))
		margin.add_theme_constant_override("margin_bottom", int(pad))

	if hbox:
		hbox.add_theme_constant_override("separation", int(gap))
		hbox.alignment = BoxContainer.ALIGNMENT_END

func refresh() -> void:
	if hbox == null:
		return
	for child in hbox.get_children():
		child.queue_free()

	var slot_size := DisplayAdapt.touch_slot_size()
	for item_id in Inventory.inventory:
		var slot = slot_scene.instantiate()
		var texture: Texture2D = Inventory.get_texture(item_id)
		slot.setup(item_id, texture)
		slot.custom_minimum_size = slot_size
		slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(slot)

	_apply_layout()
	panel.visible = Inventory.inventory.size() > 0
