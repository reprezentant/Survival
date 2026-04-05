class_name StartingCookingSlot
extends InventorySlot


signal starting_ingredient_enabled
signal starting_ingredient_disabled  # Used in cooking menu for removing items
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
	# During cooking, allow adding more of the same item
	if cooking_in_progress and item_key != null:
		var cooking_key = null
		if slot is InventorySlot:
			var slot_data = slot.item_key
			if typeof(slot_data) == TYPE_DICTIONARY and slot_data.has("item_key"):
				cooking_key = slot_data["item_key"]
			else:
				cooking_key = slot_data
		elif typeof(slot) == TYPE_DICTIONARY:
			if slot.has("item_key"):
				cooking_key = slot.item_key
			else:
				return false
		else:
			# assume raw key
			cooking_key = slot
		
		# Check if it's the same item type as currently cooking
		var current_key = null
		if typeof(item_key) == TYPE_DICTIONARY and item_key.has("item_key"):
			current_key = item_key["item_key"]
		else:
			current_key = item_key
		
		if cooking_key == current_key:
			return true  # Same item type, allow stacking
		else:
			return false  # Different item, reject
	
	# If slot already has item and not cooking, only allow same item type
	if item_key != null and not cooking_in_progress:
		# Check if it's the same item type
		var current_key = null
		if typeof(item_key) == TYPE_DICTIONARY and item_key.has("item_key"):
			current_key = item_key["item_key"]
		else:
			current_key = item_key
		
		# Get dropped item key  
		var dropped_key = null
		if slot is InventorySlot:
			var slot_data = slot.item_key
			if typeof(slot_data) == TYPE_DICTIONARY and slot_data.has("item_key"):
				dropped_key = slot_data["item_key"]
			else:
				dropped_key = slot_data
		elif typeof(slot) == TYPE_DICTIONARY:
			if slot.has("item_key"):
				dropped_key = slot.item_key
			else:
				return false
		else:
			dropped_key = slot
		
		# Only allow if same item type
		if current_key != dropped_key:
			print("[DEBUG] StartingCookingSlot: Different item types, rejecting")
			return false

	# slot can be an InventorySlot node, a dictionary { item_key, amount } or a raw item_key
	var item_key_to_drop = null
	if slot is InventorySlot:
		item_key_to_drop = slot.item_key
	elif typeof(slot) == TYPE_DICTIONARY:
		if slot.has("item_key"):
			item_key_to_drop = slot.item_key
		else:
			return false
	else:
		# assume it's a raw key
		item_key_to_drop = slot

	if item_key_to_drop == null:
		return false

	# now check recipe availability
	# If key itself is a stack dict (e.g. { item_key, amount }), extract the inner key
	if typeof(item_key_to_drop) == TYPE_DICTIONARY and item_key_to_drop.has("item_key"):
		item_key_to_drop = item_key_to_drop.item_key

	# If key is a string path (from some legacy sources), try to map it to an enum key
	if typeof(item_key_to_drop) == TYPE_STRING:
		var found_k = null
		for k in ItemConfig.ITEM_RESOURCES:
			if ItemConfig.ITEM_RESOURCES[k] == str(item_key_to_drop):
				found_k = k
				break
		if found_k == null:
			return false
		item_key_to_drop = found_k

	# Only proceed if key is an int/enum (ItemConfig.Keys)
	if typeof(item_key_to_drop) != TYPE_INT:
		return false

	var res := ItemConfig.get_item_resource(item_key_to_drop)
	if res == null:
		return false

	if res.cooking_recipe == null:
		return false

	return true


func _drop_data(_at_position: Vector2, old_slot : Variant) -> void:
	# accept InventorySlot node, dict stack, or raw key
	var dropped_item_key = null
	var available_amount = 1

	if old_slot is InventorySlot:
		var slot_data = old_slot.item_key
		if typeof(slot_data) == TYPE_DICTIONARY and slot_data.has("item_key"):
			dropped_item_key = slot_data["item_key"]
			available_amount = slot_data["amount"]
		else:
			dropped_item_key = slot_data
			available_amount = 1
	elif typeof(old_slot) == TYPE_DICTIONARY:
		if old_slot.has("item_key"):
			dropped_item_key = old_slot.item_key
			available_amount = old_slot.get("amount", 1)
		else:
			return
	else:
		# assume raw key
		dropped_item_key = old_slot
		available_amount = 1

	# If only 1 item, don't ask - just take it
	if available_amount <= 1:
		_process_cooking_drop(old_slot, dropped_item_key, 1)
		return
	
	# Multiple items - ask how many to cook
	var popup := DropQuantityPopup.new()
	get_viewport().add_child(popup)
	popup.setup(dropped_item_key, available_amount, "Ugotuj")
	
	popup.drop_confirmed.connect(func(cook_amount: int) -> void:
		_process_cooking_drop(old_slot, dropped_item_key, cook_amount)
	)
	# If cancelled, do nothing


func _process_cooking_drop(old_slot: Variant, key, cook_amount: int) -> void:
	# Normal cooking logic - prefer adding to starting slot first
	if cooking_in_progress and item_key != null:
		# If cooking in progress, add to existing items in starting slot
		var current_amount = 0
		if typeof(item_key) == TYPE_DICTIONARY and item_key.has("amount"):
			current_amount = item_key["amount"]
		else:
			current_amount = 1
		
		# Stack with existing
		var new_total = current_amount + cook_amount
		set_item_key({"item_key": key, "amount": new_total})
		
		# Update cooking system with new amount
		starting_ingredient_changed.emit(new_total)
		print("[DEBUG] StartingCookingSlot: Added ", cook_amount, " to cooking. New total: ", new_total)
	elif item_key == null:
		# Starting slot empty - add raw ingredients here (don't auto-cook!)
		set_item_key({"item_key": key, "amount": cook_amount})
		starting_ingredient_enabled.emit()
		print("[DEBUG] StartingCookingSlot: Added raw ingredients to starting slot: ", cook_amount)
	else:
		# Starting slot occupied by different item - reject
		print("[DEBUG] StartingCookingSlot: Starting slot occupied, cannot add different item")
		return
	
	# Remove items from source slot
	_remove_items_from_source(old_slot, key, cook_amount)
	
	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)


# Helper function to remove items from source
func _remove_items_from_source(old_slot: Variant, key, cook_amount: int) -> void:
	if old_slot is InventorySlot:
		# Delete specific amount from source
		var slot_index = old_slot.get_index()
		for i in cook_amount:
			EventSystem.INV_delete_item_by_index.emit(slot_index, old_slot is HotbarSlot)
	else:
		# fallback: emit delete by key (legacy support)
		for i in cook_amount:
			EventSystem.INV_delete_item.emit(key)


# Override set_item_key to emit amount changes
func set_item_key(_item_key) -> void:
	var was_empty = (item_key == null)
	var will_be_empty = (_item_key == null)
	
	super.set_item_key(_item_key)
	
	# Emit signals based on state changes
	if not was_empty and will_be_empty:
		# Item was removed - emit disabled signal
		starting_ingredient_disabled.emit()
		print("[DEBUG] StartingCookingSlot: Item removed, emitting disabled signal")
	elif was_empty and not will_be_empty:
		# Item was added - emit enabled signal  
		starting_ingredient_enabled.emit()
		print("[DEBUG] StartingCookingSlot: Item added, emitting enabled signal")
	
	# Emit amount change for countdown timer update
	var current_amount = 0
	if item_key != null:
		if typeof(item_key) == TYPE_DICTIONARY and item_key.has("amount"):
			current_amount = item_key["amount"]
		else:
			current_amount = 1
	
	starting_ingredient_changed.emit(current_amount)
	print("[DEBUG] StartingCookingSlot: Amount changed to: ", current_amount)
