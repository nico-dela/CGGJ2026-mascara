extends TextureButton

var item_id := ""

func setup(id: String, texture: Texture2D) -> void:
	item_id = id
	if texture:
		texture_normal = texture
	else:
		var placeholder := PlaceholderTexture2D.new()
		placeholder.size = Vector2(64, 64)
		texture_normal = placeholder
	update_selection_visual()

func update_selection_visual() -> void:
	if StoryFlags.mascara_equipada == item_id:
		modulate = Color(0.55, 1.0, 0.55)
	elif Inventory.selected_item == item_id:
		modulate = Color.YELLOW
	else:
		modulate = Color.WHITE

func _pressed() -> void:
	if item_id == "" or AdventureUI == null:
		return
	var center := get_global_rect().get_center()
	AdventureUI.show_bag_item_coin(item_id, center)
