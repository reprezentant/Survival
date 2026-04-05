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


func _ready() -> void:
	# Connect cooking timer to finish cooking when time's up
	if cooking_timer and not cooking_timer.timeout.is_connected(cooking_finished):
		cooking_timer.timeout.connect(cooking_finished)
	
	if fire_always_on:
		fire_particles.emitting = true
		fire_light.show()
		audio_stream_player.play()


func start_interaction() -> void:
	EventSystem.BUL_create_bulletin.emit(
		BulletinConfig.Keys.CookingMenu,
		[
			cooking_recipe,
			0 if state != CookingStates.Cooking or not cooking_recipe else (cooking_recipe.cooking_time * cooking_amount - cooking_timer.time_left),
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
	state = CookingStates.Inactive
	cooking_recipe = null
	cooking_amount = 1
	clear_food_visuals()


func cooked_item_removed() -> void:
	# Only clear if no more cooked items remain
	if cooked_item_data.has("amount") and cooked_item_data["amount"] > 0:
		cooked_item_data["amount"] -= 1
		print("[DEBUG] Cooker: Cooked item taken, remaining: ", cooked_item_data["amount"])
		
		if cooked_item_data["amount"] <= 0:
			# All items taken, reset to inactive
			state = CookingStates.Inactive
			cooking_recipe = null
			cooked_item_data = {}
			clear_food_visuals()
			print("[DEBUG] Cooker: All cooked items taken, reset to inactive")
	else:
		# Fallback: clear everything if no amount data
		state = CookingStates.Inactive
		cooking_recipe = null
		cooked_item_data = {}
		clear_food_visuals()


func clear_food_visuals() -> void:
	for child in food_visuals_holder.get_children():
		child.queue_free()


func start_cooking() -> void:
	state = CookingStates.Cooking
	# Calculate total cooking time for batch cooking
	var total_cooking_time = cooking_recipe.cooking_time * cooking_amount
	cooking_timer.start(total_cooking_time)
	print("[DEBUG] Cooker: Starting batch cooking for ", cooking_amount, " items, total time: ", total_cooking_time, " seconds")
	
	if not fire_always_on:
		fire_particles.emitting = true
		fire_light.show()
		audio_stream_player.play()


func cooking_finished() -> void:
	state = CookingStates.Cooked
	clear_food_visuals()
	
	# Store cooked item data with correct amount from batch cooking
	if cooking_recipe:
		cooked_item_data = {
			"item_key": cooking_recipe.cooked_item,
			"amount": cooking_amount  # Use actual cooking amount
		}
		print("[DEBUG] Cooker: Batch cooking finished, stored cooked item: ", cooked_item_data)
	
	# Reset cooking amount after finishing
	cooking_amount = 1
	
	if not fire_always_on:
		fire_particles.emitting = false
		fire_light.hide()
		audio_stream_player.stop()
	
	food_visuals_holder.add_child(cooking_recipe.cooked_item_visuals.instantiate())


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
