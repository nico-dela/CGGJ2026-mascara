extends Control

@onready var panel: Panel = $Panel
@onready var hbox = $Panel/HBoxContainer

var slot_scene = preload("res://scenes/inventory_slot.tscn")

func _ready() -> void:
	DisplayAdapt.adapted.connect(_apply_layout)
	_apply_layout()
	refresh()
	Inventory.inventory_changed.connect(refresh)

func _apply_layout() -> void:
	var margin := DisplayAdapt.safe_margin
	var ui := DisplayAdapt.ui_scale
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 16.0 + margin.x
	offset_top = 16.0 + margin.y
	var width := (280.0 if DisplayAdapt.is_touch_device else 220.0) * ui
	var height := (120.0 if DisplayAdapt.is_touch_device else 100.0) * ui
	offset_right = offset_left + width
	offset_bottom = offset_top + height
	self.scale = Vector2.ONE
	if panel:
		panel.offset_top = -80.0 * ui
		panel.offset_bottom = 20.0

func refresh() -> void:
	for child in hbox.get_children():
		child.queue_free()

	var slot_size := DisplayAdapt.touch_slot_size()
	for item_id in Inventory.inventory:
		var slot = slot_scene.instantiate()
		var texture: Texture2D = Inventory.get_texture(item_id)
		slot.setup(item_id, texture)
		slot.custom_minimum_size = slot_size
		hbox.add_child(slot)
