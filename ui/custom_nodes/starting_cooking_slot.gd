class_name StartingCookingSlot
extends InventorySlot


signal starting_ingredient_enabled
signal starting_ingredient_disabled
signal starting_ingredient_changed(amount: int)  # New signal for amount changes

var cooking_in_progress := false


func _get_drag_data(_at_position: Vector2):
	if cooking_in_progress:
		return null

	if item_key != null:
		_is_being_dragged = true
		var drag_preview := TextureRect.new()
		drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		drag_preview.texture = icon_texture_rect.texture
		drag_preview.size = Vector2(80, 80)
		drag_preview.modulate.a = 0.7
		set_drag_preview(drag_preview)
		EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)
		return self
	
	return null


func _can_drop_data(_at_position: Vector2, slot : Variant) -> bool:
	if item_key != null:
		return false

	# slot can be an InventorySlot node, a dictionary { item_key, amount } or a raw item_key
	var key = null
	if slot is InventorySlot:
		key = slot.item_key
	elif typeof(slot) == TYPE_DICTIONARY:
		if slot.has("item_key"):
			key = slot.item_key
		else:
			return false
	else:
		# assume it's a raw key
		key = slot

	if key == null:
		return false

	# now check recipe availability
	# If key itself is a stack dict (e.g. { item_key, amount }), extract the inner key
	if typeof(key) == TYPE_DICTIONARY and key.has("item_key"):
		key = key.item_key

	# If key is a string path (from some legacy sources), try to map it to an enum key
	if typeof(key) == TYPE_STRING:
		var found_k = null
		for k in ItemConfig.ITEM_RESOURCES:
			if ItemConfig.ITEM_RESOURCES[k] == str(key):
				found_k = k
				break
		if found_k == null:
			return false
		key = found_k

	# Only proceed if key is an int/enum (ItemConfig.Keys)
	if typeof(key) != TYPE_INT:
		return false

	var res := ItemConfig.get_item_resource(key)
	if res == null:
		return false

	if res.cooking_recipe == null:
		return false

	return true


func _drop_data(_at_position: Vector2, old_slot : Variant) -> void:
	# accept InventorySlot node, dict stack, or raw key
	var key = null
	var amount = 1

	if old_slot is InventorySlot:
		var slot_data = old_slot.item_key
		if typeof(slot_data) == TYPE_DICTIONARY and slot_data.has("item_key"):
			key = slot_data["item_key"]
			amount = slot_data["amount"]  # Get the full amount for batch cooking
		else:
			key = slot_data
			amount = 1
	elif typeof(old_slot) == TYPE_DICTIONARY:
		if old_slot.has("item_key"):
			key = old_slot.item_key
			amount = old_slot.get("amount", 1)
		else:
			return
	else:
		# assume raw key
		key = old_slot
		amount = 1

	# Set the item with amount for batch cooking
	set_item_key({"item_key": key, "amount": amount})
	
	# Remove all items from the source slot using the new delete all function
	if old_slot is InventorySlot:
		EventSystem.INV_delete_all_items_by_index.emit(old_slot.get_index(), old_slot is HotbarSlot)
	else:
		# fallback: emit delete by key (legacy support)
		EventSystem.INV_delete_item.emit(key)
	
	starting_ingredient_enabled.emit()
	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)


# Override set_item_key to emit amount changes
func set_item_key(_item_key) -> void:
	super.set_item_key(_item_key)
	
	# Emit amount change for countdown timer update
	var current_amount = 0
	if item_key != null:
		if typeof(item_key) == TYPE_DICTIONARY and item_key.has("amount"):
			current_amount = item_key["amount"]
		else:
			current_amount = 1
	
	starting_ingredient_changed.emit(current_amount)
	print("[DEBUG] StartingCookingSlot: Amount changed to: ", current_amount)
