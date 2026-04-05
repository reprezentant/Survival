extends PlayerMenuBase

# We'll find these dynamically after reparenting instead of using @onready
# @onready var starting_cooking_slot: StartingCookingSlot = %StartingCookingSlot  
# @onready var cooking_progress_bar: TextureProgressBar = %CookingProgressBar
# @onready var final_cooking_slot: FinalCookingSlot = %FinalCookingSlot
# @onready var cook_button: Button = %CookButton

var cooking_recipe: CookingRecipeResource
var time_cooked: float
var interactable_cooker: InteractableCooker
var cooking_state : InteractableCooker.CookingStates
var cooked_item_data: Dictionary = {}  # Persistent cooked item data
var cooking_amount: int = 1  # Current cooking amount
var countdown_timer: Timer
var remaining_time: float = 0.0
var stored_slot_items: Dictionary = {}  # Items stored in slots


func initialize(extra_arg) -> void:
	if not extra_arg or not extra_arg is Array:
		return
	
	cooking_recipe = extra_arg[0]
	time_cooked = extra_arg[1]
	interactable_cooker = extra_arg[2]
	cooking_state = extra_arg[3]
	if extra_arg.size() > 4:
		cooked_item_data = extra_arg[4]  # Get persistent cooked item data
	else:
		cooked_item_data = {}
	if extra_arg.size() > 5:
		cooking_amount = extra_arg[5]  # Get current cooking amount
	else:
		cooking_amount = 1
	
	if extra_arg.size() > 6:
		stored_slot_items = extra_arg[6]  # Get stored slot items
	else:
		stored_slot_items = {}
	
	print("[DEBUG] CookingMenu: Initialized - cooked_item_data: ", cooked_item_data, " cooking_amount: ", cooking_amount, " stored_slot_items: ", stored_slot_items)


func _ready() -> void:
	# Call parent ready first
	super._ready()
	
	# Set mouse filter to ignore empty areas to show game background
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# COMPLETELY REMOVE original cooking structure - this causes leftover tiles
	var original_vbox_full_path = get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer")
	if original_vbox_full_path:
		original_vbox_full_path.queue_free()
		print("[DEBUG] CookingMenu: FULLY REMOVED original VBoxContainer structure")
	else:
		print("[DEBUG] CookingMenu: Original VBoxContainer structure not found")
		
	# Set mouse filters for remaining elements to ignore clicks on empty areas 
	var margin_container = get_node_or_null("MarginContainer")
	if margin_container:
		margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var hbox_container = get_node_or_null("MarginContainer/HBoxContainer")
	if hbox_container:
		hbox_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	var window_vbox = get_node_or_null("MarginContainer/HBoxContainer/WindowVBox")
	if window_vbox:
		window_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	var content_rect = get_node_or_null("MarginContainer/HBoxContainer/WindowVBox/ContentRect")
	if content_rect:
		content_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	var info_rect = get_node_or_null("MarginContainer/HBoxContainer/WindowVBox/InfoRect")
	if info_rect:
		info_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Override panel visibility for cooking layout
	# Show inventory (backpack) on left, hide tabs and other panels
	if backpack_panel:
		backpack_panel.visible = true
		backpack_panel.mouse_filter = Control.MOUSE_FILTER_PASS  # Let clicks pass through
		print("[DEBUG] CookingMenu: Set backpack_panel visible")
	if crafting_panel:
		crafting_panel.visible = false  
	if journal_panel:
		journal_panel.visible = false
	
	# Hide tab buttons in cooking menu
	if backpack_tab_btn:
		backpack_tab_btn.visible = false
	if crafting_tab_btn:
		crafting_tab_btn.visible = false
	if journal_tab_btn:
		journal_tab_btn.visible = false
	
	# Hide journal category tabs too
	if items_tab_btn:
		items_tab_btn.visible = false
	if creatures_tab_btn:
		creatures_tab_btn.visible = false
	if objects_tab_btn:
		objects_tab_btn.visible = false
	
	# Hide scrap slot since it's not needed in cooking
	var scrap_slot = get_node("%ScrapSlot") if has_node("%ScrapSlot") else null
	if scrap_slot:
		scrap_slot.visible = false
	
	# Create cooking interface panel next to inventory
	_create_cooking_interface()
	
	# Defer connections to ensure nodes are fully ready
	call_deferred("_setup_connections")


func _create_cooking_interface():
	# Find the main HBoxContainer
	var hbox = get_node("MarginContainer/HBoxContainer")
	if not hbox:
		print("[ERROR] CookingMenu: Could not find main HBoxContainer")
		return
		
	# Debug: print the structure we're working with
	print("[DEBUG] CookingMenu: Main HBoxContainer found, children: ", hbox.get_child_count())
	for child in hbox.get_children():
		print("[DEBUG] CookingMenu: HBox child: ", child.name, " type: ", child.get_class())
		
	# Get backpack height to match cooking panel size
	var backpack_height = 400  # Default fallback
	if backpack_panel:
		await get_tree().process_frame  # Wait for layout update
		backpack_height = backpack_panel.size.y
		print("[DEBUG] CookingMenu: Backpack height: ", backpack_height)
	
	# Create cooking panel with matching height
	var cooking_vbox = VBoxContainer.new()
	cooking_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cooking_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Don't expand vertically!
	cooking_vbox.custom_minimum_size = Vector2(480, backpack_height)  # Wider to prevent right tile cutoff
	cooking_vbox.size = Vector2(480, backpack_height)  # Force exact size with more width
	cooking_vbox.name = "CookingPanel"
	cooking_vbox.mouse_filter = Control.MOUSE_FILTER_PASS  # Let clicks pass through
	hbox.add_child(cooking_vbox)
	
	# Add title
	var title_rect = NinePatchRect.new()
	title_rect.custom_minimum_size = Vector2(480, 50)  # Match panel width
	title_rect.texture = load("res://textures/panelInset_beige.png")
	title_rect.patch_margin_left = 32
	title_rect.patch_margin_top = 32
	title_rect.patch_margin_right = 48
	title_rect.patch_margin_bottom = 32
	cooking_vbox.add_child(title_rect)
	
	var title_label = Label.new()
	title_label.text = "Cooking"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.anchor_right = 1.0
	title_label.anchor_bottom = 1.0
	title_rect.add_child(title_label)
	
	# Create main cooking area
	var cooking_rect = NinePatchRect.new()
	cooking_rect.custom_minimum_size = Vector2(480, 180)  # Wider to prevent cutoff
	cooking_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cooking_rect.mouse_filter = Control.MOUSE_FILTER_PASS  # Let clicks pass through
	cooking_rect.texture = load("res://textures/panelInset_beige.png")
	cooking_rect.patch_margin_left = 32
	cooking_rect.patch_margin_top = 32
	cooking_rect.patch_margin_right = 48
	cooking_rect.patch_margin_bottom = 32
	cooking_vbox.add_child(cooking_rect)
	
	# Margin container inside cooking panel
	var cooking_margin = MarginContainer.new()
	cooking_margin.anchor_right = 1.0
	cooking_margin.anchor_bottom = 1.0
	cooking_margin.mouse_filter = Control.MOUSE_FILTER_PASS  # Let clicks pass through
	cooking_margin.add_theme_constant_override("margin_left", 32)
	cooking_margin.add_theme_constant_override("margin_top", 32)
	cooking_margin.add_theme_constant_override("margin_right", 32)
	cooking_margin.add_theme_constant_override("margin_bottom", 32)
	cooking_rect.add_child(cooking_margin)
	
	# Center container for cooking elements
	var center_container = CenterContainer.new()
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_container.mouse_filter = Control.MOUSE_FILTER_PASS  # Let clicks pass through
	cooking_margin.add_child(center_container)
	
	# Main cooking VBox
	var cooking_elements = VBoxContainer.new()
	cooking_elements.add_theme_constant_override("separation", 20)  # Reduced spacing for shorter layout
	cooking_elements.mouse_filter = Control.MOUSE_FILTER_PASS  # Let clicks pass through
	center_container.add_child(cooking_elements)
	
	# Create new container for cooking slots  
	var slots_hbox = HBoxContainer.new()
	slots_hbox.add_theme_constant_override("separation", 50)  # More space for even distribution
	slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_hbox.name = "CookingSlots"
	slots_hbox.mouse_filter = Control.MOUSE_FILTER_PASS  # Let clicks pass through
	cooking_elements.add_child(slots_hbox)
	
	# Search for cooking slots in the original structure and move them
	print("[DEBUG] CookingMenu: Searching for cooking slots...")
	
	# Try to find slots using unique names first (most reliable)
	# Don't use original slots - always create new ones
	
	print("[DEBUG] CookingMenu: Creating all new cooking elements")
	
	# Create new elements (always create fresh ones)
	var starting_slot = preload("res://ui/custom_nodes/inventory_slot.tscn").instantiate()
	starting_slot.set_script(preload("res://ui/custom_nodes/starting_cooking_slot.gd"))
	starting_slot.name = "StartingCookingSlot"
	print("[DEBUG] CookingMenu: Created new StartingCookingSlot")
	
	# Create container for progress bar with countdown
	var progress_container = Control.new()
	progress_container.custom_minimum_size = Vector2(90, 90)  # Match other slots
	progress_container.name = "ProgressContainer"
	
	# Create actual progress bar
	var progress_bar = TextureProgressBar.new()
	progress_bar.name = "CookingProgressBar"
	progress_bar.texture_under = load("res://textures/panel_brown.png")
	progress_bar.texture_progress = load("res://textures/panel_blue.png")
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	progress_bar.anchor_right = 1.0
	progress_bar.anchor_bottom = 1.0
	progress_container.add_child(progress_bar)
	
	# Create countdown label
	var countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.text = "--"  # Show "--" when no ingredients
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.anchor_right = 1.0
	countdown_label.anchor_bottom = 1.0
	countdown_label.add_theme_font_size_override("font_size", 24)
	countdown_label.add_theme_color_override("font_color", Color.WHITE)
	countdown_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	countdown_label.add_theme_constant_override("shadow_offset_x", 2)
	countdown_label.add_theme_constant_override("shadow_offset_y", 2)
	progress_container.add_child(countdown_label)
	
	# Replace progress_bar reference with container
	progress_bar = progress_container
	print("[DEBUG] CookingMenu: Created new CookingProgressBar with countdown")
	
	var final_slot = preload("res://ui/custom_nodes/inventory_slot.tscn").instantiate()
	final_slot.set_script(preload("res://ui/custom_nodes/final_cooking_slot.gd"))
	final_slot.name = "FinalCookingSlot"
	print("[DEBUG] CookingMenu: Created new FinalCookingSlot")
	
	var cook_btn = Button.new()
	cook_btn.name = "CookButton"
	cook_btn.text = "COOK"
	cook_btn.disabled = true
	print("[DEBUG] CookingMenu: Created new CookButton")
	
	# Add the new slots to the cooking interface
	print("[DEBUG] CookingMenu: Adding StartingCookingSlot")
	slots_hbox.add_child(starting_slot)
	starting_slot.custom_minimum_size = Vector2(90, 90)  # Larger for better distribution
	starting_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	starting_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	print("[DEBUG] CookingMenu: Adding CookingProgressBar")
	slots_hbox.add_child(progress_bar)
	progress_bar.custom_minimum_size = Vector2(90, 90)  # Match slot size for even distribution
	progress_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
	print("[DEBUG] CookingMenu: Adding FinalCookingSlot")
	slots_hbox.add_child(final_slot)
	final_slot.custom_minimum_size = Vector2(90, 90)  # Larger for better distribution
	final_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	final_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Create cook button container with extra margin top to move it down
	var btn_container = CenterContainer.new()
	btn_container.mouse_filter = Control.MOUSE_FILTER_PASS  # Let clicks pass through
	btn_container.add_theme_constant_override("margin_top", 20)  # Push button down
	cooking_elements.add_child(btn_container)
	
	var btn_rect = NinePatchRect.new()
	btn_rect.custom_minimum_size = Vector2(150, 50)
	btn_rect.texture = load("res://textures/panel_blue.png")
	btn_rect.patch_margin_left = 32
	btn_rect.patch_margin_top = 32
	btn_rect.patch_margin_right = 64
	btn_rect.patch_margin_bottom = 32
	btn_container.add_child(btn_rect)
	
	print("[DEBUG] CookingMenu: Adding new CookButton")
	btn_rect.add_child(cook_btn)
		
	cook_btn.anchor_right = 1.0
	cook_btn.anchor_bottom = 1.0
	cook_btn.add_theme_font_size_override("font_size", 18)
	cook_btn.name = "CookButton"  # Ensure the name is preserved
	
	# Ensure button signal is connected
	if not cook_btn.pressed.is_connected(start_cooking):
		cook_btn.pressed.connect(start_cooking)
	
	print("[DEBUG] CookingMenu: Cooking interface created successfully")
	print("[DEBUG] CookingMenu: Slots container children: ", slots_hbox.get_child_count())


func _setup_connections() -> void:
	print("[DEBUG] CookingMenu: Setting up connections...")
	
	# Wait a bit for all nodes to be fully ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find the cooking elements using find_child (much simpler than tree traversal)
	var starting_cooking_slot = find_child("StartingCookingSlot", true, false)
	var final_cooking_slot = find_child("FinalCookingSlot", true, false)
	var cook_btn = find_child("CookButton", true, false)
	var progress_bar = find_child("CookingProgressBar", true, false)
	
	print("[DEBUG] CookingMenu: Found slots - Starting: ", starting_cooking_slot != null, 
		  " Final: ", final_cooking_slot != null, " Button: ", cook_btn != null, " Progress: ", progress_bar != null)
	
	if not starting_cooking_slot or not final_cooking_slot:
		print("[ERROR] CookingMenu: Cooking slot nodes not found!")
		return
	
	print("[DEBUG] CookingMenu: Connecting slot signals...")
	
	# Connect mouse events for info display
	if not starting_cooking_slot.mouse_entered.is_connected(show_item_info):
		starting_cooking_slot.mouse_entered.connect(show_item_info.bind(starting_cooking_slot))
	if not starting_cooking_slot.mouse_exited.is_connected(hide_item_info):
		starting_cooking_slot.mouse_exited.connect(hide_item_info)
		
	if not final_cooking_slot.mouse_entered.is_connected(show_item_info):
		final_cooking_slot.mouse_entered.connect(show_item_info.bind(final_cooking_slot))
	if not final_cooking_slot.mouse_exited.is_connected(hide_item_info):
		final_cooking_slot.mouse_exited.connect(hide_item_info)
	
	# Connect cooking logic signals
	if not starting_cooking_slot.starting_ingredient_enabled.is_connected(uncooked_item_added):
		starting_cooking_slot.starting_ingredient_enabled.connect(uncooked_item_added)
	if not starting_cooking_slot.starting_ingredient_disabled.is_connected(uncooked_item_removed):
		starting_cooking_slot.starting_ingredient_disabled.connect(uncooked_item_removed)
	if not starting_cooking_slot.starting_ingredient_changed.is_connected(update_countdown_display):
		starting_cooking_slot.starting_ingredient_changed.connect(update_countdown_display)
	
	if not final_cooking_slot.cooked_food_taken.is_connected(interactable_cooker.cooked_item_removed):
		final_cooking_slot.cooked_food_taken.connect(interactable_cooker.cooked_item_removed)
	
	# Connect to InteractableCooker cooking finished signal
	if interactable_cooker.cooking_timer and not interactable_cooker.cooking_timer.timeout.is_connected(on_cooking_finished):
		interactable_cooker.cooking_timer.timeout.connect(on_cooking_finished)
	
	# Store references for other methods to use
	starting_cooking_slot.set_name("StartingCookingSlot")
	final_cooking_slot.set_name("FinalCookingSlot")
	
	# Initialize slots based on current cooking state
	print("[DEBUG] CookingMenu: Initializing state: ", cooking_state)
	if cooking_state == InteractableCooker.CookingStates.Cooked:
		# Restore cooked item from persistent data
		if cooked_item_data.has("item_key") and cooked_item_data.has("amount"):
			final_cooking_slot.set_item_key({
				"item_key": cooked_item_data["item_key"], 
				"amount": cooked_item_data["amount"]
			})
			print("[DEBUG] CookingMenu: Restored cooked item: ", cooked_item_data)
		else:
			print("[DEBUG] CookingMenu: No cooked item data found")
	elif cooking_state == InteractableCooker.CookingStates.Cooking:
		# Resume countdown display for ongoing cooking
		var progress_container = find_child("ProgressContainer", true, false)
		if progress_container:
			if not countdown_timer:
				countdown_timer = Timer.new()
				countdown_timer.wait_time = 0.1  # Update every 100ms
				countdown_timer.timeout.connect(_update_countdown)
				add_child(countdown_timer)
			countdown_timer.start()
			print("[DEBUG] CookingMenu: Resumed countdown for ongoing cooking")
			
			# Show current recipe being cooked
			if cooking_recipe and cooking_amount > 1:
				starting_cooking_slot.set_item_key({
					"item_key": cooking_recipe.uncooked_item,
					"amount": cooking_amount
				})
				starting_cooking_slot.cooking_in_progress = true
				
			# Disable cook button
			cook_btn = find_child("CookButton", true, false)
			if cook_btn:
				cook_btn.disabled = true
	elif cooking_state == InteractableCooker.CookingStates.ReadyToCook:
		# If cooker has recipe and amount, restore to slot (only if no stored slot items to restore later)
		if interactable_cooker.cooking_recipe and interactable_cooker.cooking_amount > 0 and stored_slot_items.is_empty():
			starting_cooking_slot.set_item_key({
				"item_key": interactable_cooker.cooking_recipe.uncooked_item,
				"amount": interactable_cooker.cooking_amount
			})
			print("[DEBUG] CookingMenu: Restored ReadyToCook state with recipe: ", interactable_cooker.cooking_recipe.uncooked_item, " amount: ", interactable_cooker.cooking_amount)
			# Enable cook button since we have valid items
		cook_btn = find_child("CookButton", true, false)
		if cook_btn:
			cook_btn.disabled = false
			starting_cooking_slot.set_item_key(null)
			final_cooking_slot.set_item_key(null)
	
	# Restore stored slot items if any (from previous menu closure)
	_restore_stored_slot_items(starting_cooking_slot, final_cooking_slot)


# Update countdown display based on amount of items in starting slot
func update_countdown_display(amount: int) -> void:
	var countdown_label = find_child("CountdownLabel", true, false)
	if not countdown_label:
		print("[ERROR] CookingMenu: CountdownLabel not found")
		return
		
	if amount <= 0:
		countdown_label.text = "--"
	else:
		# 1 meat = 5 seconds, so amount * 5
		var total_seconds = amount * 5
		var minutes = floori(float(total_seconds) / 60.0)  # Floor division for minutes
		var seconds = total_seconds % 60
		countdown_label.text = "%d:%02d" % [minutes, seconds]
		
	print("[DEBUG] CookingMenu: Updated countdown to: ", countdown_label.text, " (amount: ", amount, ")")


func uncooked_item_added() -> void:
	var cook_btn = find_child("CookButton", true, false)
	var starting_slot = find_child("StartingCookingSlot", true, false)
	
	if cook_btn:
		cook_btn.disabled = false
	
	# Get item key and amount for batch cooking
	if starting_slot:
		var slot_data = starting_slot.item_key
		var key = null
		var amount = 1
		
		if typeof(slot_data) == TYPE_DICTIONARY and slot_data.has("item_key"):
			key = slot_data["item_key"]
			amount = slot_data["amount"]
		else:
			key = slot_data
			amount = 1
		
		cooking_recipe = ItemConfig.get_item_resource(key).cooking_recipe
		time_cooked = 0
		
		print("[DEBUG] CookingMenu: Batch cooking ", amount, " items, total time: ", cooking_recipe.cooking_time * amount, " seconds")
		
		# Pass the amount to cooker for proper state saving
		interactable_cooker.uncooked_item_added(cooking_recipe, amount)


func uncooked_item_removed() -> void:
	var cook_btn = find_child("CookButton", true, false)
	
	if cook_btn:
		cook_btn.disabled = true
	cooking_recipe = null
	time_cooked = 0
	interactable_cooker.uncooked_item_removed()


func start_cooking() -> void:
	var starting_slot = find_child("StartingCookingSlot", true, false)
	var cook_btn = find_child("CookButton", true, false) 
	var progress_container = find_child("ProgressContainer", true, false)
	
	if starting_slot:
		starting_slot.cooking_in_progress = true
	if cook_btn:
		cook_btn.disabled = true
	
	# Calculate total cooking time based on amount
	var amount = cooking_amount  # Use current cooking amount
	if starting_slot:
		var slot_data = starting_slot.item_key
		if typeof(slot_data) == TYPE_DICTIONARY and slot_data.has("amount"):
			amount = slot_data["amount"]
			# Update cooking amount in cooker
			interactable_cooker.cooking_amount = amount
	
	var total_cooking_time = cooking_recipe.cooking_time * amount
	remaining_time = total_cooking_time - time_cooked
	print("[DEBUG] CookingMenu: Starting batch cooking for ", amount, " items, total time: ", total_cooking_time, " seconds")
	
	# Use InteractableCooker timer instead of our own tween
	if cooking_state != InteractableCooker.CookingStates.Cooking:
		interactable_cooker.start_cooking()
		EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)
	
	# Setup countdown display only
	if progress_container:
		# Setup countdown timer for display only
		if not countdown_timer:
			countdown_timer = Timer.new()
			countdown_timer.wait_time = 0.1  # Update every 100ms
			countdown_timer.timeout.connect(_update_countdown)
			add_child(countdown_timer)
		
		countdown_timer.start()
		_update_countdown()  # Initial update


func _update_countdown() -> void:
	# Check if InteractableCooker is still cooking
	if not interactable_cooker or interactable_cooker.state != InteractableCooker.CookingStates.Cooking:
		# Cooking finished, stop countdown
		if countdown_timer:
			countdown_timer.stop()
		return
	
	var progress_container = find_child("ProgressContainer", true, false)
	if progress_container:
		var countdown_label = progress_container.find_child("CountdownLabel", true, false)
		var progress_bar = progress_container.find_child("CookingProgressBar", true, false)
		
		if interactable_cooker.cooking_timer:
			var time_left = interactable_cooker.cooking_timer.time_left
			var total_time = cooking_recipe.cooking_time * cooking_amount
			
			if countdown_label:
				countdown_label.text = str(ceil(time_left))
				
			if progress_bar:
				var progress = 1.0 - (time_left / total_time) if total_time > 0 else 1.0
				progress_bar.value = progress


# Called when InteractableCooker finishes cooking
func on_cooking_finished() -> void:
	var final_slot = find_child("FinalCookingSlot", true, false)
	var starting_slot = find_child("StartingCookingSlot", true, false)
	var progress_container = find_child("ProgressContainer", true, false)
	
	print("[DEBUG] CookingMenu: InteractableCooker finished cooking")
	
	# Stop countdown timer
	if countdown_timer:
		countdown_timer.stop()
	
	# Update UI to show cooked items
	if final_slot and interactable_cooker.cooked_item_data.has("item_key"):
		final_slot.set_item_key({
			"item_key": interactable_cooker.cooked_item_data["item_key"],
			"amount": interactable_cooker.cooked_item_data["amount"]
		})
		print("[DEBUG] CookingMenu: Set final slot to: ", interactable_cooker.cooked_item_data)
	
	if starting_slot:
		starting_slot.set_item_key(null)
		starting_slot.cooking_in_progress = false
	
	# Reset progress bar and countdown
	if progress_container:
		var progress_bar = progress_container.find_child("CookingProgressBar", true, false)
		var countdown_label = progress_container.find_child("CountdownLabel", true, false)
		if progress_bar:
			progress_bar.value = 1.0  # Show completed
		if countdown_label:
			countdown_label.text = "0"


func close() -> void:
	# Save current slot items before closing
	_save_slot_items_before_close()
	
	# Cleanup countdown timer
	if countdown_timer:
		countdown_timer.stop()
		countdown_timer.queue_free()
		countdown_timer = null
	
	EventSystem.BUL_destroy_bulletin.emit(BulletinConfig.Keys.CookingMenu)
	EventSystem.PLA_unfreeze_player.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)


# Override tab switching methods to prevent layout changes in cooking menu
func _switch_to_backpack() -> void:
	# Do nothing - cooking menu has fixed layout
	pass

func _switch_to_crafting() -> void:
	# Do nothing - cooking menu has fixed layout  
	pass

func _switch_to_journal() -> void:
	# Do nothing - cooking menu has fixed layout
	pass


# Save slot items before closing menu
func _save_slot_items_before_close() -> void:
	var slot_data = {}
	
	var starting_slot = find_child("StartingCookingSlot", true, false)
	var final_slot = find_child("FinalCookingSlot", true, false)
	
	# Only save if cooking is not in progress and not cooked
	if cooking_state == InteractableCooker.CookingStates.Inactive or cooking_state == InteractableCooker.CookingStates.ReadyToCook:
		if starting_slot and starting_slot.item_key != null:
			slot_data["starting_slot"] = starting_slot.item_key
			print("[DEBUG] CookingMenu: Saving starting slot: ", starting_slot.item_key)
		
		if final_slot and final_slot.item_key != null:
			slot_data["final_slot"] = final_slot.item_key
			print("[DEBUG] CookingMenu: Saving final slot: ", final_slot.item_key)
		
		# Store in cooker for next opening
		if interactable_cooker:
			interactable_cooker.store_slot_items(slot_data)


# Restore stored slot items when menu reopens
func _restore_stored_slot_items(starting_slot, final_slot) -> void:
	if stored_slot_items.is_empty():
		print("[DEBUG] CookingMenu: No stored slot items to restore")
		return
	
	print("[DEBUG] CookingMenu: Restoring stored slot items: ", stored_slot_items)
	
	if stored_slot_items.has("starting_slot") and starting_slot:
		starting_slot.set_item_key(stored_slot_items["starting_slot"])
		print("[DEBUG] CookingMenu: Restored starting slot: ", stored_slot_items["starting_slot"])
		# Emit signal to notify cooker about the restored item
		starting_slot.starting_ingredient_enabled.emit()
	
	if stored_slot_items.has("final_slot") and final_slot:
		final_slot.set_item_key(stored_slot_items["final_slot"])
		print("[DEBUG] CookingMenu: Restored final slot: ", stored_slot_items["final_slot"])
	
	# Clear stored items after restoring
	if interactable_cooker:
		interactable_cooker.clear_stored_slot_items()

func _switch_journal_category(_category: JournalConfig.Category) -> void:
	# Do nothing - cooking menu doesn't use journal
	pass

func _request_journal_state() -> void:
	# Do nothing - cooking menu doesn't use journal
	pass

func _on_journal_state_updated(_states: Dictionary) -> void:
	# Do nothing - cooking menu doesn't use journal  
	pass
