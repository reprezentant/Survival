class_name InventorySlot
extends TextureRect

@onready var icon_texture_rect: TextureRect = $MarginContainer/IconTextureRect
@onready var amount_label: Label = $AmountLabel

var item_key
var _is_being_dragged := false


func set_item_key(_item_key) -> void:
	# _item_key can be either ItemConfig.Keys or a dictionary { item_key, amount }
	var prev_amount := 0
	if typeof(item_key) == TYPE_DICTIONARY:
		prev_amount = int(item_key.amount)

	item_key = _item_key
	update_icon()

	# if amount increased, play pop animation
	var new_amount := 1
	if typeof(item_key) == TYPE_DICTIONARY:
		new_amount = int(item_key.amount)

	if new_amount > prev_amount:
		# Simple fallback animation using SceneTreeTimer to avoid engine tween API mismatch
		amount_label.scale = Vector2(1.2, 1.2)
		var t1 := get_tree().create_timer(0.08)
		t1.timeout.connect(func():
			var t2 := get_tree().create_timer(0.12)
			t2.timeout.connect(func():
				amount_label.scale = Vector2(1, 1)
			)
		)


func update_icon() -> void:
	var key = null
	if item_key == null:
		icon_texture_rect.texture = null
		amount_label.visible = false
		return

	if typeof(item_key) == TYPE_DICTIONARY:
		key = item_key.item_key
	else:
		key = item_key

	icon_texture_rect.texture = ItemConfig.get_item_resource(key).icon

	# show amount for stacked resources
	var amt := 1
	if typeof(item_key) == TYPE_DICTIONARY:
		amt = item_key.amount

	if amt > 1:
		amount_label.text = _format_amount(amt)
		amount_label.visible = true
	else:
		amount_label.visible = false


func _format_amount(n:int) -> String:
	if n < 1000:
		return str(n)
	if n < 1000000:
		return str(int(n / 1000.0)) + "k"
	return str(int(n / 1000000.0)) + "M"


func _get_drag_data(_at_position: Vector2) -> Variant:
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


func _can_drop_data(_at_position: Vector2, slot: Variant) -> bool:
	# Normalize dragged data into a raw item key when possible
	var dragged_key = null
	if slot is InventorySlot:
		dragged_key = slot.item_key
	elif typeof(slot) == TYPE_DICTIONARY and slot.has("item_key"):
		dragged_key = slot.item_key
	else:
		dragged_key = slot

	if typeof(dragged_key) == TYPE_DICTIONARY and dragged_key.has("item_key"):
		dragged_key = dragged_key.item_key

	# If dragged_key is still null, disallow
	if dragged_key == null:
		return false

	# If this receiving slot is a HotbarSlot, only accept equippable items
	if self is HotbarSlot:
		# normalize dragged_key if necessary
		if typeof(dragged_key) == TYPE_STRING:
			var fk = null
			for k in ItemConfig.ITEM_RESOURCES:
				if ItemConfig.ITEM_RESOURCES[k] == str(dragged_key):
					fk = k
					break
			if fk == null:
				return false
			dragged_key = fk

		if typeof(dragged_key) != TYPE_INT:
			return false

		return ItemConfig.get_item_resource(dragged_key).is_equippable

	# If this receiving slot is a StartingCookingSlot, accept items with cooking recipes
	if self is StartingCookingSlot:
		if typeof(dragged_key) == TYPE_STRING:
			var fk2 = null
			for k2 in ItemConfig.ITEM_RESOURCES:
				if ItemConfig.ITEM_RESOURCES[k2] == str(dragged_key):
					fk2 = k2
					break
			if fk2 == null:
				return false
			dragged_key = fk2

		if typeof(dragged_key) != TYPE_INT:
			return false

		return ItemConfig.get_item_resource(dragged_key).cooking_recipe != null

	# Final cooking slot cannot accept drops
	if self is FinalCookingSlot:
		return false

	# Default: accept InventorySlot drags
	return slot is InventorySlot


func _drop_data(_at_position: Vector2, old_slot: Variant) -> void:
	if old_slot is StartingCookingSlot:
		var temp_own_key = item_key
		# Extract raw key from starting slot
		var raw_key = old_slot.item_key
		if typeof(raw_key) == TYPE_DICTIONARY and raw_key.has("item_key"):
			raw_key = raw_key.item_key
		EventSystem.INV_add_item_by_index.emit(raw_key, get_index(), self is HotbarSlot, 1)
		old_slot.set_item_key(temp_own_key)
		old_slot.starting_ingredient_disabled.emit()

	elif old_slot is FinalCookingSlot:
		var raw_key2 = old_slot.item_key
		if typeof(raw_key2) == TYPE_DICTIONARY and raw_key2.has("item_key"):
			raw_key2 = raw_key2.item_key
		EventSystem.INV_add_item_by_index.emit(raw_key2, get_index(), self is HotbarSlot, 1)
		old_slot.set_item_key(null)
		old_slot.cooked_food_taken.emit()

	else:
		# Normal swap between inventory/hotbar slots
		EventSystem.INV_switch_two_inventory_item_indexes.emit(
			old_slot.get_index(),
			old_slot is HotbarSlot,
			get_index(),
			self is HotbarSlot
			)

	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if _is_being_dragged and not is_drag_successful():
			_drop_to_world()
		_is_being_dragged = false


func _drop_to_world() -> void:
	if item_key == null:
		return

	var amount := 1
	var raw_key = item_key
	if typeof(item_key) == TYPE_DICTIONARY:
		raw_key = item_key.item_key
		amount = int(item_key.amount)

	# Check if item requires confirmation before dropping
	var item_resource = ItemConfig.get_item_resource(raw_key)
	if item_resource.requires_drop_confirmation:
		# Check if item will disappear (no pickuppable scene)
		var will_disappear = not ItemConfig.has_pickuppable_scene(raw_key)
		
		# For single items, show confirmation with disappear warning if needed
		if amount <= 1:
			var confirmation_popup := ConfirmationDropPopup.new()
			get_tree().current_scene.add_child(confirmation_popup)
			confirmation_popup.setup(item_resource, will_disappear)
			
			confirmation_popup.drop_confirmed.connect(func():
				# Drop single item when confirmed
				EventSystem.INV_drop_item_to_world.emit(get_index(), self is HotbarSlot, 1)
			)
			# If cancelled, do nothing - item stays in inventory
			return
		else:
			# For stacked items, show quantity popup with enhanced warning
			var quantity_popup := DropQuantityPopup.new()
			get_viewport().add_child(quantity_popup)
			var warning_text = "ostrzeżenie" if not will_disappear else "ZNIKNĄ NA ZAWSZE"
			quantity_popup.setup(raw_key, amount, "Wyrzuć", true, warning_text)
			quantity_popup.drop_confirmed.connect(func(drop_amount: int) -> void:
				EventSystem.INV_drop_item_to_world.emit(get_index(), self is HotbarSlot, drop_amount)
			)
			return

	# Single item — drop immediately (no confirmation needed)
	if amount <= 1:
		EventSystem.INV_drop_item_to_world.emit(get_index(), self is HotbarSlot, 1)
		return

	# Stack — ask how many
	var quantity_popup := DropQuantityPopup.new()
	get_viewport().add_child(quantity_popup)
	quantity_popup.setup(raw_key, amount)

	quantity_popup.drop_confirmed.connect(func(drop_amount: int) -> void:
		EventSystem.INV_drop_item_to_world.emit(get_index(), self is HotbarSlot, drop_amount)
	)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_RIGHT or not event.pressed:
		return
	if item_key == null:
		return
	if self is HotbarSlot or self is StartingCookingSlot or self is FinalCookingSlot:
		return

	var key = item_key.item_key if typeof(item_key) == TYPE_DICTIONARY else item_key
	var resource := ItemConfig.get_item_resource(key)

	var actions: Array[String] = []
	if resource is ConsumableItemResource:
		actions.append("Zjedz")
	
	# Add split stack option for stackable items with amount > 1
	var current_amount = 1
	if typeof(item_key) == TYPE_DICTIONARY and item_key.has("amount"):
		current_amount = int(item_key.amount)
	
	if current_amount > 1:
		actions.append("Podziel stos")

	if actions.is_empty():
		return

	get_viewport().set_input_as_handled()

	var menu := InventoryContextMenu.new()
	get_viewport().add_child(menu)
	menu.setup(actions, get_global_mouse_position())
	menu.action_selected.connect(func(action: String) -> void:
		if action == "Zjedz":
			_eat_item(key)
		elif action == "Podziel stos":
			_split_stack()
	)


func _eat_item(key: ItemConfig.Keys) -> void:
	var resource := ItemConfig.get_item_resource(key) as ConsumableItemResource
	if resource == null:
		return
	EventSystem.PLA_change_health.emit(resource.health_change)
	EventSystem.PLA_change_energy.emit(resource.energy_change)
	EventSystem.INV_delete_item_by_index.emit(get_index(), self is HotbarSlot)
	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.Eat)
	EventSystem.JOU_test.emit(int(key))


func _split_stack() -> void:
	if typeof(item_key) != TYPE_DICTIONARY or not item_key.has("amount"):
		return
		
	var current_amount = int(item_key.amount)
	if current_amount <= 1:
		return
		
	var raw_key = item_key.item_key
	var max_split = current_amount - 1  # Must leave at least 1 in original stack
	
	var split_popup := DropQuantityPopup.new()
	get_viewport().add_child(split_popup)
	split_popup.setup(raw_key, max_split, "Podziel stos")
	
	split_popup.drop_confirmed.connect(func(split_amount: int) -> void:
		_perform_stack_split(raw_key, split_amount, current_amount)
	)


func _perform_stack_split(raw_key, split_amount: int, original_amount: int) -> void:
	# Reduce original stack first
	var remaining_amount = original_amount - split_amount
	set_item_key({"item_key": raw_key, "amount": remaining_amount})
	
	# Add split items to inventory - let inventory manager find the best spot
	EventSystem.INV_add_item_to_inventory.emit(raw_key, split_amount)
	
	print("[DEBUG] InventorySlot: Split stack - kept ", remaining_amount, " splitting ", split_amount, " items")
	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)

