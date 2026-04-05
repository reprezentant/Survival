class_name EquippableConsumable
extends EquippableItem

var consumable_item_resource: ItemResource


func try_to_use() -> void:
	if animation_player.is_playing():
		return
	
	# Apply consumption effects based on item type
	_apply_consumption_effects()
	
	# Play use animation
	animation_player.play("use_item")
	
	# Remove item from inventory after consumption
	animation_player.animation_finished.connect(_on_consumption_complete, CONNECT_ONE_SHOT)


func _apply_consumption_effects() -> void:
	if not consumable_item_resource:
		print("[WARNING] EquippableConsumable: No item resource set!")
		return
	
	# Cast to ConsumableItemResource to access health_change and energy_change
	var consumable_resource = consumable_item_resource as ConsumableItemResource
	if not consumable_resource:
		print("[ERROR] EquippableConsumable: Item resource is not ConsumableItemResource!")
		return
	
	# Get item key from resource path to determine journal key
	var resource_path = consumable_item_resource.resource_path
	var journal_key: ItemConfig.Keys
	
	# Apply effects from resource
	if consumable_resource.health_change != 0:
		EventSystem.PLA_change_health.emit(consumable_resource.health_change)
		print("[DEBUG] EquippableConsumable: Health change: ", consumable_resource.health_change)
	
	if consumable_resource.energy_change != 0:
		EventSystem.PLA_change_energy.emit(consumable_resource.energy_change)
		print("[DEBUG] EquippableConsumable: Energy change: ", consumable_resource.energy_change)
	
	# Determine journal key based on item type
	if "fruit" in resource_path:
		journal_key = ItemConfig.Keys.Fruit
	elif "mushroom" in resource_path:
		journal_key = ItemConfig.Keys.Mushroom
	elif "cooked_meat" in resource_path:
		journal_key = ItemConfig.Keys.CookedMeat
	else:
		print("[WARNING] EquippableConsumable: Unknown consumable type:", resource_path)
		return
		
	# Mark as tested in journal
	EventSystem.JOU_test.emit(journal_key)


func _on_consumption_complete(_anim_name: String) -> void:
	# Remove the consumed item from inventory
	if consumable_item_resource:
		var item_key = _get_item_key_from_resource(consumable_item_resource)
		if item_key != -1:
			print("[DEBUG] EquippableConsumable: Removing consumed item from inventory")
			EventSystem.INV_delete_item_count.emit(item_key, 1)


func _get_item_key_from_resource(item_resource: ItemResource) -> int:
	var resource_path = item_resource.resource_path
	
	if "fruit" in resource_path:
		return ItemConfig.Keys.Fruit
	elif "mushroom" in resource_path:
		return ItemConfig.Keys.Mushroom
	elif "cooked_meat" in resource_path:
		return ItemConfig.Keys.CookedMeat
		
	return -1  # Unknown item


func destroy_self() -> void:
	EventSystem.EQU_unequip_item.emit()
