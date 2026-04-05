class_name InteractableCooker
extends Interactable

@onready var cooking_timer: Timer = $CookingTimer
@onready var food_visuals_holder: Marker3D = $FoodVisualsHolder
@onready var fire_particles: GPUParticles3D = $GPUParticles3D
@onready var fire_light: OmniLight3D = $OmniLight3D
@onready var audio_stream_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var fire_always_on := true

var cooking_recipe: CookingRecipeResource
var cooked_item_data: Dictionary = {}  # Store { item_key: ItemConfig.Keys, amount: int }
var cooking_amount: int = 1  # Amount being cooked for batch cooking
var stored_slot_items: Dictionary = {}  # Store items in cooking slots when menu closes

enum CookingStates {
	Inactive,
	ReadyToCook,
	Cooking,
	Cooked
}

var state := CookingStates.Inactive
var menu_open := false  # Track if menu is currently open


func _ready() -> void:
	# Connect cooking timer to finish cooking when time's up
	if cooking_timer and not cooking_timer.timeout.is_connected(cooking_finished):
		cooking_timer.timeout.connect(cooking_finished)
	
	# Connect to bulletin events to track menu state
	if not EventSystem.BUL_create_bulletin.is_connected(_on_bulletin_created):
		EventSystem.BUL_create_bulletin.connect(_on_bulletin_created)
	if not EventSystem.BUL_destroy_bulletin.is_connected(_on_bulletin_destroyed):
		EventSystem.BUL_destroy_bulletin.connect(_on_bulletin_destroyed)
	
	if fire_always_on:
		fire_particles.emitting = true
		fire_light.show()
		audio_stream_player.play()


func _on_bulletin_created(bulletin_key, _args = null) -> void:
	if bulletin_key == BulletinConfig.Keys.CookingMenu:
		menu_open = true
		print("[DEBUG] Cooker: Menu opened")


func _on_bulletin_destroyed(bulletin_key) -> void:
	if bulletin_key == BulletinConfig.Keys.CookingMenu:
		menu_open = false
		print("[DEBUG] Cooker: Menu closed")


func start_interaction() -> void:
	# Prevent opening menu if already open
	if menu_open:
		print("[DEBUG] Cooker: Menu already open, ignoring interaction")
		return
	
	EventSystem.BUL_create_bulletin.emit(
		BulletinConfig.Keys.CookingMenu,
		[
			cooking_recipe,
			0.0 if state != CookingStates.Cooking or not cooking_recipe else (float(cooking_recipe.cooking_time) * cooking_amount - cooking_timer.time_left),
			self,
			state,
			cooked_item_data,  # Pass cooked item data for persistence
			cooking_amount,  # Pass current cooking amount
			stored_slot_items  # Pass stored slot items
		]
	)


func uncooked_item_added(recipe: CookingRecipeResource, amount: int = 1) -> void:
	state = CookingStates.ReadyToCook
	cooking_recipe = recipe
	cooking_amount = amount
	food_visuals_holder.add_child(cooking_recipe.uncooked_item_visuals.instantiate())
	print("[DEBUG] Cooker: Uncooked item added, amount: ", amount)


func uncooked_item_removed() -> void:
	# Don't reset if currently cooking - preserve the cooking state
	if state == CookingStates.Cooking:
		print("[DEBUG] Cooker: Item removal blocked - cooking in progress")
		return
	
	state = CookingStates.Inactive
	cooking_recipe = null
	cooking_amount = 1  # Reset to default
	clear_food_visuals()
	print("[DEBUG] Cooker: Uncooked item removed, reset to inactive")


func cooked_item_removed(amount_taken: int = 1) -> void:
	# Reduce by the actual amount taken
	if cooked_item_data.has("amount") and cooked_item_data["amount"] > 0:
		cooked_item_data["amount"] -= amount_taken
		print("[DEBUG] Cooker: ", amount_taken, " cooked items taken, remaining: ", cooked_item_data["amount"])
		
		if cooked_item_data["amount"] <= 0:
			# All items taken, reset to inactive
			state = CookingStates.Inactive
			cooking_recipe = null
			cooking_amount = 1  # Reset cooking amount
			cooked_item_data = {}
			clear_food_visuals()
			print("[DEBUG] Cooker: All cooked items taken, reset to inactive")
	else:
		# Fallback: clear everything if no amount data
		state = CookingStates.Inactive
		cooking_recipe = null
		cooking_amount = 1  # Reset cooking amount
		cooked_item_data = {}
		clear_food_visuals()


func clear_food_visuals() -> void:
	for child in food_visuals_holder.get_children():
		child.queue_free()


func start_cooking() -> void:
	state = CookingStates.Cooking
	# Calculate total cooking time for batch cooking
	var total_cooking_time = float(cooking_recipe.cooking_time) * cooking_amount
	cooking_timer.start(total_cooking_time)
	print("[DEBUG] Cooker: Starting batch cooking for ", cooking_amount, " items, total time: ", total_cooking_time, " seconds")
	
	if not fire_always_on:
		fire_particles.emitting = true
		fire_light.show()
		audio_stream_player.play()


func cooking_finished() -> void:
	state = CookingStates.Cooked
	clear_food_visuals()
	
	# Store cooked item data with stacking support
	if cooking_recipe:
		var new_cooked_amount = cooking_amount
		var new_cooked_item = cooking_recipe.cooked_item
		
		# Check if we already have cooked items and can stack
		if cooked_item_data.has("item_key") and cooked_item_data.has("amount"):
			if cooked_item_data["item_key"] == new_cooked_item:
				# Same item type - stack with existing
				var total_amount = cooked_item_data["amount"] + new_cooked_amount
				cooked_item_data = {
					"item_key": new_cooked_item,
					"amount": total_amount
				}
				print("[DEBUG] Cooker: Stacked cooked items. Previous: ", cooked_item_data["amount"] - new_cooked_amount, ", New: ", new_cooked_amount, ", Total: ", total_amount)
			else:
				# Different item type - replace
				cooked_item_data = {
					"item_key": new_cooked_item,
					"amount": new_cooked_amount
				}
				print("[DEBUG] Cooker: Replaced different cooked items with: ", cooked_item_data)
		else:
			# No existing items - set new
			cooked_item_data = {
				"item_key": new_cooked_item, 
				"amount": new_cooked_amount
			}
			print("[DEBUG] Cooker: Set first cooked items: ", cooked_item_data)
	
	# Reset cooking amount after finishing
	cooking_amount = 1
	
	if not fire_always_on:
		fire_particles.emitting = false
		fire_light.hide()
		audio_stream_player.stop()
	
	food_visuals_holder.add_child(cooking_recipe.cooked_item_visuals.instantiate())
	
	# WAŻNE: Reset cooking_recipe na samym końcu po wszystkich użyciach!
	cooking_recipe = null
	print("[DEBUG] Cooker: Reset cooking_recipe after finishing")


# Function to store slot items when menu is closed without cooking
func store_slot_items(slot_data: Dictionary) -> void:
	stored_slot_items = slot_data
	print("[DEBUG] Cooker: Stored slot items: ", stored_slot_items)


# Function to retrieve stored slot items when menu is reopened
func get_stored_slot_items() -> Dictionary:
	return stored_slot_items


# Function to clear stored slot items after they are used
func clear_stored_slot_items() -> void:
	stored_slot_items = {}
	print("[DEBUG] Cooker: Cleared stored slot items")
