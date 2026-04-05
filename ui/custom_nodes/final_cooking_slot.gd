class_name FinalCookingSlot
extends InventorySlot

signal cooked_food_taken(amount_taken: int)

func _can_drop_data(_at_position: Vector2, _slot : Variant) -> bool:
	return false

var _pending_take_key = null
var _pending_take_amount = 0  # Track how many items we're trying to take

func _on_inv_add_item_ack(added:int, _leftover:int) -> void:
	# disconnect and handle ack
	EventSystem.INV_add_item_ack.disconnect(Callable(self, "_on_inv_add_item_ack"))
	
	if added > 0 and _pending_take_key != null:
		# Emit signal with the actual amount that was taken
		cooked_food_taken.emit(added)
		
		# Update slot display - reduce by taken amount or clear if all taken
		if typeof(item_key) == TYPE_DICTIONARY and item_key.has("amount"):
			var remaining = item_key["amount"] - added
			if remaining <= 0:
				set_item_key(null)
			else:
				# Still have some left - update the amount
				set_item_key({
					"item_key": item_key["item_key"],
					"amount": remaining
				})
				print("[DEBUG] FinalCookingSlot: Took ", added, ", remaining: ", remaining)
		else:
			# Single item taken
			set_item_key(null)
	
	# Always reset pending flags
	_pending_take_key = null
	_pending_take_amount = 0


func _gui_input(event: InputEvent) -> void:
	# Allow clicking the final cooked slot to pick up the cooked food into the player's inventory
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if item_key == null:
			return

		# if a previous pick-up is pending, ignore further clicks
		if _pending_take_key != null:
			print("FinalCookingSlot: pickup already pending")
			return

		var key = null
		var amount = 1
		
		# Handle both single items and stacked items
		if typeof(item_key) == TYPE_DICTIONARY and item_key.has("item_key"):
			key = item_key["item_key"]
			amount = item_key.get("amount", 1)
		else:
			key = item_key
			amount = 1

		if typeof(key) == TYPE_STRING:
			# map resource path string to enum key if needed
			var found_k = null
			for k in ItemConfig.ITEM_RESOURCES:
				if ItemConfig.ITEM_RESOURCES[k] == str(key):
					found_k = k
					break
			if found_k == null:
				return
			key = found_k

		if typeof(key) != TYPE_INT:
			return

		# Emit add-to-inventory for the full amount (tries to add to any free slot)
		# Wait for ack to know whether inventory accepted the item
		_pending_take_key = key
		_pending_take_amount = amount
		print("FinalCookingSlot: requesting add for key=", key, " amount=", amount)
		EventSystem.INV_add_item_ack.connect(Callable(self, "_on_inv_add_item_ack"))
		EventSystem.INV_add_item_to_inventory.emit(key, amount)
		# Discover the cooked item in Journal
		EventSystem.JOU_discover.emit(int(key))
		print("FinalCookingSlot: Journal discover emitted for cooked item:", key)
