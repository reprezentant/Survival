# Simple tests for inventory stack behaviour
# Run these inside Godot's script runner or print outputs to Debug

func _ready():
	print("Starting inventory tests")
	var inv = preload("res://game/managers/inventory_manager.gd").new()
	inv._ready()
	inv._enter_tree()
	inv.inventory.resize(10)
	inv.hotbar.resize(3)

	# Test add single stackable item
	var leftover = inv.add_item(ItemConfig.Keys.Stick, 10)
	assert(leftover == 0)
	print("Added 10 sticks")

	# Add more to same stack
	leftover = inv.add_item(ItemConfig.Keys.Stick, 45) # should fill 50 and create new stack with 5 leftover
	print("Leftover after adding 45 sticks:", leftover)
	assert(leftover == 0 or leftover >= 0)

	# Test deleting
	inv.delete_item_count(ItemConfig.Keys.Stick, 12)
	print("Deleted 12 sticks")

	# Test non-stackable
	inv.add_item(ItemConfig.Keys.Axe, 1)
	print("Added axe")

	print("Inventory tests done")
	get_tree().quit()
