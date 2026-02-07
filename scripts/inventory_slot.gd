extends TextureButton

var item_id := ""

func setup(id: String, texture: Texture2D):
	item_id = id
	texture_normal = texture

func _pressed():
	if GameManager.selected_item == item_id:
		GameManager.selected_item = ""
		modulate = Color.WHITE
	else:
		GameManager.selected_item = item_id
		modulate = Color(1, 1, 0)
