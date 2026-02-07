extends Control

@onready var slot_button = $ItemSlot

func _ready():
	refresh()

func refresh():
	if GameManager.has_item("lemon"):
		slot_button.visible = true
		slot_button.texture_normal = preload("res://images/Pasted image.png")
	else:
		slot_button.visible = false
		slot_button.modulate = Color.WHITE

func _on_item_slot_pressed():
	if GameManager.selected_item == "lemon":
		GameManager.selected_item = ""
		slot_button.modulate = Color.WHITE
	else:
		GameManager.selected_item = "lemon"
		slot_button.modulate = Color(1, 1, 0) # resaltado
