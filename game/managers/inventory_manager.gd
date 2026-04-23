extends Node


const INVENTORY_SIZE = 28
var inventory := []

const HOTBAR_SIZE = 9
var hotbar := []

# Guard to ensure signals are connected only once
var _connected := false

# Stack settings
const MAX_STACK := 50
# Stackable resources: patyki, kamienie, jedzenie itp.
# Using actual enum names from `ItemConfig.Keys`.
var STACKABLE_ITEMS := [
	ItemConfig.Keys.Stick,
	ItemConfig.Keys.Stone,
	ItemConfig.Keys.Fruit,
	ItemConfig.Keys.RawMeat,
	ItemConfig.Keys.CookedMeat,
	ItemConfig.Keys.Plant,
	ItemConfig.Keys.Mushroom,
]


func _enter_tree() -> void:
	if _connected:
		return

	EventSystem.connect_once("INV_try_to_pickup_item", Callable(self, "try_to_pickup_item"))
	EventSystem.connect_once("INV_ask_update_inventory", Callable(self, "send_inventory"))
	EventSystem.connect_once("INV_switch_two_inventory_item_indexes", Callable(self, "switch_two_item_indexes"))
	EventSystem.connect_once("INV_add_item_to_inventory", Callable(self, "add_item"))
	EventSystem.connect_once("INV_delete_blueprint_costs_from_inventory", Callable(self, "delete_blueprint_costs"))
	EventSystem.connect_once("INV_delete_item_count", Callable(self, "delete_item_count"))
	EventSystem.connect_once("INV_delete_item_by_index", Callable(self, "delete_item_by_index"))
	EventSystem.connect_once("INV_delete_all_items_by_index", Callable(self, "delete_all_items_by_index"))
	EventSystem.connect_once("INV_add_item_by_index", Callable(self, "add_item_by_index"))
	EventSystem.connect_once("INV_drop_item_to_world", Callable(self, "drop_item_to_world"))
	EventSystem.connect_once("SET_save_game", Callable(self, "save_inventory"))
	EventSystem.connect_once("SET_load_game", Callable(self, "load_inventory"))

	_connected = true


func _ready() -> void:
	inventory.resize(INVENTORY_SIZE)
	hotbar.resize(HOTBAR_SIZE)


func send_inventory() -> void:
	EventSystem.INV_inventory_updated.emit(inventory)


func save_inventory() -> void:
	var data := {"inventory": [], "hotbar": []}
	for slot in inventory:
		if slot == null:
			data.inventory.append(null)
		elif typeof(slot) == TYPE_DICTIONARY:
			data.inventory.append({"item_key": int(slot.item_key), "amount": int(slot.amount)})
		else:
			data.inventory.append({"item_key": int(slot), "amount": 1})

	for slot in hotbar:
		if slot == null:
			data.hotbar.append(null)
		elif typeof(slot) == TYPE_DICTIONARY:
			data.hotbar.append({"item_key": int(slot.item_key), "amount": int(slot.amount)})
		else:
			data.hotbar.append({"item_key": int(slot), "amount": 1})

	var json_str := JSON.stringify(data)
	var f := FileAccess.open("user://inventory.json", FileAccess.ModeFlags.WRITE)
	if f:
		f.store_string(json_str)
		f.close()


func load_inventory() -> void:
	if not FileAccess.file_exists("user://inventory.json"):
		return

	var f := FileAccess.open("user://inventory.json", FileAccess.ModeFlags.READ)
	if not f:
		return

	var raw := f.get_as_text()
	f.close()

	var j = JSON.new()
	var parsed = j.parse(raw)
	if parsed.error != OK:
		return

	var data = parsed.result
	if typeof(data) != TYPE_DICTIONARY:
		return

	var inv = data.get("inventory", [])
	var hb = data.get("hotbar", [])

	for i in range(min(inventory.size(), inv.size())):
		var s = inv[i]
		if s == null:
			inventory[i] = null
		else:
			# s.item_key is saved as resource path string, find matching key
			var path:String = str(s.item_key)
			var found_key = null
			for k in ItemConfig.ITEM_RESOURCES:
				if ItemConfig.ITEM_RESOURCES[k] == path:
					found_key = k
					break

			if found_key == null:
				inventory[i] = null
			else:
				inventory[i] = {"item_key": found_key, "amount": int(s.amount)}

	for i in range(min(hotbar.size(), hb.size())):
		var s2 = hb[i]
		if s2 == null:
			hotbar[i] = null
		else:
			var path2:String = str(s2.item_key)
			var found_key2 = null
			for k2 in ItemConfig.ITEM_RESOURCES:
				if ItemConfig.ITEM_RESOURCES[k2] == path2:
					found_key2 = k2
					break

			if found_key2 == null:
				hotbar[i] = null
			else:
				hotbar[i] = {"item_key": found_key2, "amount": int(s2.amount)}

	EventSystem.INV_inventory_updated.emit(inventory)
	EventSystem.INV_hotbar_updated.emit(hotbar)


func get_inventory_item_keys() -> Array:
	# returns an array of ItemConfig.Keys (one per unit)
	var keys := []
	for slot in inventory:
		if slot == null:
			continue
		if typeof(slot) == TYPE_DICTIONARY:
			for i in range(slot.amount):
				keys.append(slot.item_key)
		else:
			keys.append(slot)

	return keys


func count_item(item_key:ItemConfig.Keys) -> int:
	var total := 0
	for slot in inventory:
		if slot == null:
			continue
		if typeof(slot) == TYPE_DICTIONARY and slot.item_key == item_key:
			total += slot.amount
		elif slot == item_key:
			total += 1

	return total


func is_stackable(item_key:ItemConfig.Keys) -> bool:
	return item_key in STACKABLE_ITEMS


func can_add_item(item_key:ItemConfig.Keys) -> bool:
	# If stackable and there's an existing stack with space -> allowed
	if is_stackable(item_key):
		for slot in inventory:
			if slot and slot.item_key == item_key and slot.amount < MAX_STACK:
				return true

	# Otherwise need a free slot
	return get_free_slots() > 0


func try_to_pickup_item(item_key:ItemConfig.Keys, destroy_pickuppable:Callable, amount:int = 1) -> void:
	# pickup `amount` units (default 1)
	if not can_add_item(item_key):
		return

	var leftover := add_item(item_key, amount)
	if leftover == 0:
		destroy_pickuppable.call()


func switch_two_item_indexes(slot1:int, slot1_is_hotbar_slot:bool, slot2:int, slot2_is_hotbar_slot:bool) -> void:
	var item1 = inventory[slot1] if not slot1_is_hotbar_slot else hotbar[slot1]
	var item2 = inventory[slot2] if not slot2_is_hotbar_slot else hotbar[slot2]

	if not slot1_is_hotbar_slot:
		inventory[slot1] = item2
	else:
		hotbar[slot1] = item2

	if not slot2_is_hotbar_slot:
		inventory[slot2] = item1
	else:
		hotbar[slot2] = item1

	EventSystem.INV_inventory_updated.emit(inventory)
	EventSystem.INV_hotbar_updated.emit(hotbar)


func get_free_slots() -> int:
	var free_slots := 0
	for slot in inventory:
		if not slot:
			free_slots += 1

	return free_slots


func add_item(item_key:ItemConfig.Keys, amount:int = 1) -> int:
	# Adds up to `amount` items, returns leftover that couldn't be added (0 if all added)
	var remaining := amount

	# Stackable: fill existing stacks first
	if is_stackable(item_key):
		for i in range(inventory.size()):
			if remaining <= 0:
				break
			var slot = inventory[i]
			if slot and slot.item_key == item_key and slot.amount < MAX_STACK:
				var space:int = MAX_STACK - int(slot.amount)
				var to_add:int = int(min(space, remaining))
				slot.amount += to_add
				inventory[i] = slot
				remaining -= to_add

		# Put remaining into empty slots as new stacks
		for i in range(inventory.size()):
			if remaining <= 0:
				break
			if inventory[i] == null:
				var to_put:int = int(min(MAX_STACK, remaining))
				inventory[i] = {"item_key": item_key, "amount": to_put}
				remaining -= to_put

		EventSystem.INV_inventory_updated.emit(inventory)
		var added := amount - remaining
		EventSystem.INV_add_item_ack.emit(added, remaining)
		if added > 0:
			EventSystem.UI_show_pickup_notification.emit(item_key, added)
		return remaining

	# Non-stackable: need one slot per unit
	for i in range(inventory.size()):
		if remaining <= 0:
			break
		if inventory[i] == null:
			inventory[i] = {"item_key": item_key, "amount": 1}
			remaining -= 1

	EventSystem.INV_inventory_updated.emit(inventory)
	var added2 := amount - remaining
	EventSystem.INV_add_item_ack.emit(added2, remaining)
	if added2 > 0:
		EventSystem.UI_show_pickup_notification.emit(item_key, added2)
	return remaining


func delete_blueprint_costs(costs:Array[CraftingBlueprintCostDataResource]) -> void:
	for cost in costs:
		delete_item_count(cost.item_key, cost.amount)


func delete_item_count(item_key:ItemConfig.Keys, amount:int) -> void:
	# Remove up to `amount` units from inventory, starting from the last slots
	var remaining := amount
	for i in range(inventory.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var slot = inventory[i]
		if slot == null:
			continue
		if typeof(slot) == TYPE_DICTIONARY and slot.item_key == item_key:
			if slot.amount > remaining:
				slot.amount -= remaining
				inventory[i] = slot
				remaining = 0
			else:
				remaining -= slot.amount
				inventory[i] = null
		elif typeof(slot) != TYPE_DICTIONARY and slot == item_key:
			# legacy single-key slot
			inventory[i] = null
			remaining -= 1

	EventSystem.INV_inventory_updated.emit(inventory)


func delete_item(item_key:ItemConfig.Keys) -> void:
	# remove single unit from last occurrence
	for i in range(inventory.size() - 1, -1, -1):
		var slot = inventory[i]
		if not slot:
			continue
		if typeof(slot) == TYPE_DICTIONARY and slot.item_key == item_key:
			if slot.amount > 1:
				slot.amount -= 1
				inventory[i] = slot
			else:
				inventory[i] = null
		elif typeof(slot) != TYPE_DICTIONARY and slot == item_key:
			# legacy single-key slot
			inventory[i] = null

			EventSystem.INV_inventory_updated.emit(inventory)
			return


func delete_item_by_index(index:int, is_in_hotbar:bool) -> void:
	if is_in_hotbar:
		var slot = hotbar[index]
		if slot:
			if slot.amount > 1:
				slot.amount -= 1
				hotbar[index] = slot
			else:
				hotbar[index] = null

		EventSystem.INV_hotbar_updated.emit(hotbar)

	else:
		var slot = inventory[index]
		if slot:
			if slot.amount > 1:
				slot.amount -= 1
				inventory[index] = slot
			else:
				inventory[index] = null

		EventSystem.INV_inventory_updated.emit(inventory)


func delete_all_items_by_index(index:int, is_in_hotbar:bool) -> void:
	# Delete entire stack at once (for batch cooking)
	if is_in_hotbar:
		hotbar[index] = null
		EventSystem.INV_hotbar_updated.emit(hotbar)
	else:
		inventory[index] = null
		EventSystem.INV_inventory_updated.emit(inventory)


func add_item_by_index(item_key:ItemConfig.Keys, index:int, is_in_hotbar:bool) -> void:
	if is_in_hotbar:
		hotbar[index] = {"item_key": item_key, "amount": 1}
		EventSystem.INV_hotbar_updated.emit(hotbar)

	else:
		inventory[index] = {"item_key": item_key, "amount": 1}
		EventSystem.INV_inventory_updated.emit(inventory)


func drop_item_to_world(slot_index: int, is_hotbar_slot: bool, amount_to_drop: int = 1) -> void:
	var slot_array := hotbar if is_hotbar_slot else inventory
	var slot = slot_array[slot_index]
	if slot == null:
		return

	var key
	var available := 1
	if typeof(slot) == TYPE_DICTIONARY:
		key = slot.item_key
		available = int(slot.amount)
	else:
		key = slot

	var drop_count := mini(amount_to_drop, available)

	# Partial drop: reduce stack; full drop: clear slot
	if drop_count >= available:
		slot_array[slot_index] = null
	else:
		slot_array[slot_index] = {"item_key": key, "amount": available - drop_count}

	if is_hotbar_slot:
		EventSystem.INV_hotbar_updated.emit(hotbar)
	else:
		EventSystem.INV_inventory_updated.emit(inventory)

	# Only spawn items that have a world scene defined
	if not ItemConfig.has_pickuppable_scene(key):
		return

	var player: Node3D = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	var drop_scene := ItemConfig.get_pickuppable_item_scene(key)
	var space_state := player.get_world_3d().direct_space_state

	for _i in range(drop_count):
		var xz_offset := Vector3(randf_range(-0.4, 0.4), 0.0, randf_range(-0.4, 0.4))
		var base_pos := player.global_position + (-player.global_transform.basis.z * 1.2) + xz_offset

		var query := PhysicsRayQueryParameters3D.new()
		query.from = base_pos + Vector3(0, 5.0, 0)
		query.to = base_pos + Vector3(0, -10.0, 0)
		query.collision_mask = 1  # environment layer
		var result := space_state.intersect_ray(query)

		var drop_y := base_pos.y
		if result:
			drop_y = (result.position.y as float) + 0.05

		var drop_transform := Transform3D(Basis(), Vector3(base_pos.x, drop_y, base_pos.z))
		EventSystem.SPA_spawn_scene.emit(drop_scene, drop_transform)

	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.ItemPickup)
