extends Control

@onready var hbox = $Panel/HBoxContainer

var slot_scene = preload("res://scenes/inventory_slot.tscn")

var item_textures = {
	"oso": preload("res://images/coleccionables/BearHead.png"),
}

func _ready():
	refresh() # refrescar al inicio
	GameManager.inventoryChange.connect(refresh)

func refresh():
	# limpiar slots anteriores
	for child in hbox.get_children():
		child.queue_free()

	# crear un slot por cada item del inventario
	for item_id in GameManager.inventory:
		var slot = slot_scene.instantiate()
		slot.setup(item_id, item_textures[item_id])
		hbox.add_child(slot)
