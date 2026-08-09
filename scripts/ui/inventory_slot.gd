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
	var item := Inventory.get_item(item_id)
	# Second click on a selected mask equips/unequips on the detective.
	if item and item.tipo == ItemResource.ItemTypes.MASCARA and Inventory.selected_item == item_id:
		GameManager.toggle_equip_mask(item_id)
		update_selection_visual()
		return
	if Inventory.selected_item == item_id:
		Inventory.selected_item = ""
	else:
		Inventory.selected_item = item_id
		if AdventureUI:
			AdventureUI.set_verb(AdventureUI.Verb.USE)
