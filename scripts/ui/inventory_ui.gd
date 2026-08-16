extends Control

## Legacy per-room inventory bar. AdventureUI owns the live Bolso HUD.

@onready var panel: PanelContainer = $Panel
@onready var hbox: HBoxContainer = $Panel/Margin/HBoxContainer
@onready var margin: MarginContainer = $Panel/Margin

var slot_scene = preload("res://scenes/ui/inventory_slot.tscn")

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func refresh() -> void:
	pass
