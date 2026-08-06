extends TextureButton

var item_id := ""

func setup(id: String, texture: Texture2D) -> void:
	item_id = id
	if texture:
		texture_normal = texture
	else:
		# Fallback so unknown items never crash the UI
		var placeholder := PlaceholderTexture2D.new()
		placeholder.size = Vector2(64, 64)
		texture_normal = placeholder
	modulate = Color.YELLOW if Inventory.selected_item == item_id else Color.WHITE

func _pressed() -> void:
	if Inventory.selected_item == item_id:
		Inventory.selected_item = ""
		modulate = Color.WHITE
	else:
		Inventory.selected_item = item_id
		modulate = Color(1, 1, 0)
