# TEMPORARY TEST: Press 'T' in inventory to get campfire materials
# REMOVE THIS WHEN COOKING SYSTEM IS COMPLETE
class_name PlayerMenuBase
extends Bulletin


@onready var inventory_slot_container: GridContainer = %InventorySlotContainer
@onready var item_info_label: Label = %ItemInfoLabel
@onready var extra_info_label: Label = %ExtraInfoLabel
@onready var backpack_tab_btn: Button = %BackpackTabBtn
@onready var crafting_tab_btn: Button = %CraftingTabBtn
@onready var journal_tab_btn: Button = %JournalTabBtn
@onready var backpack_panel: Control = %BackpackPanel
@onready var crafting_panel: Control = %CraftingPanel
@onready var journal_panel: Control = %JournalPanel
@onready var items_tab_btn: Button = %ItemsTabBtn
@onready var creatures_tab_btn: Button = %CreaturesTabBtn
@onready var objects_tab_btn: Button = %ObjectsTabBtn
@onready var journal_entry_container: VBoxContainer = %JournalEntryContainer
@onready var journal_info_title: Label = %JournalInfoTitle
@onready var journal_info_desc: Label = %JournalInfoDesc

var _connected := false
var journal_states: Dictionary = {}
var journal_new_updates: Dictionary = {}
var journal_read_entries: Dictionary = {}
var current_journal_category: JournalConfig.Category = JournalConfig.Category.ITEMS
var entry_buttons: Array = []


func _enter_tree() -> void:
	if _connected:
		return

	EventSystem.connect_once("INV_inventory_updated", Callable(self, "update_inventory"))
	# Connect to journal events with error handling
	print("[DEBUG] PlayerMenuBase: Attempting to connect to journal events")
	if EventSystem.has_signal("JOU_state_updated"):
		if not EventSystem.is_connected("JOU_state_updated", Callable(self, "_on_journal_state_updated")):
			EventSystem.connect("JOU_state_updated", Callable(self, "_on_journal_state_updated"))
		else:
			print("[DEBUG] PlayerMenuBase: Already connected to JOU_state_updated")
	else:
		print("[WARNING] PlayerMenuBase: JOU_state_updated signal not found in EventSystem")
	_connected = true


func _ready() -> void:
	# Set mouse filter to ignore clicks on empty areas to show game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	EventSystem.PLA_freeze_player.emit()
	EventSystem.INV_ask_update_inventory.emit()

	if inventory_slot_container:
		for inventory_slot in inventory_slot_container.get_children():
			inventory_slot.mouse_entered.connect(show_item_info.bind(inventory_slot))
			inventory_slot.mouse_exited.connect(hide_item_info)

	for hotbar_slot in get_tree().get_nodes_in_group("HotbarSlots"):
		hotbar_slot.mouse_entered.connect(show_item_info.bind(hotbar_slot))
		hotbar_slot.mouse_exited.connect(hide_item_info)

	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)

	var scrap_slot = get_node("%ScrapSlot") if has_node("%ScrapSlot") else null
	if scrap_slot and scrap_slot.has_signal("item_scrapped"):
		scrap_slot.item_scrapped.connect(hide_item_info)

	# Connect tab buttons if they exist
	if backpack_tab_btn:
		backpack_tab_btn.pressed.connect(_switch_to_backpack)
	if crafting_tab_btn:
		crafting_tab_btn.pressed.connect(_switch_to_crafting)
	if journal_tab_btn:
		journal_tab_btn.pressed.connect(_switch_to_journal)
	
	# Connect journal category tab buttons with safety checks
	if items_tab_btn:
		items_tab_btn.pressed.connect(_switch_journal_category.bind(JournalConfig.Category.ITEMS))
	if creatures_tab_btn:
		creatures_tab_btn.pressed.connect(_switch_journal_category.bind(JournalConfig.Category.CREATURES))
	if objects_tab_btn:
		objects_tab_btn.pressed.connect(_switch_journal_category.bind(JournalConfig.Category.OBJECTS))

	# Only switch to backpack if we have the required UI elements
	if backpack_panel and crafting_panel and journal_panel:
		_switch_to_backpack()
	
	# Request current journal state (with delay to ensure full initialization)
	call_deferred("_request_journal_state")


func _setup_connections() -> void:
	# Virtual function for child classes to override connection setup
	pass


## TEMPORARY TEST FUNCTION - REMOVE AFTER COOKING IS DONE ##
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		print("[DEBUG] TEST: Adding campfire materials...")
		
		# Materials needed for complete campfire setup:
		# For Multitool: 1 Stick, 1 Stone, 1 Flintstone, 1 RawMeat
		# For Tinderbox: 2 Stick, 1 Stone, 1 Flintstone, 1 Coal  
		# For Campfire: 3 Stick, 10 Stone
		# TOTAL: 6 Stick, 12 Stone, 2 Flintstone, 1 Coal, 1 RawMeat
		# PLUS: 20 Plants for general testing
		
		EventSystem.INV_add_item_to_inventory.emit(ItemConfig.Keys.Stick, 6)      # Stick
		EventSystem.INV_add_item_to_inventory.emit(ItemConfig.Keys.Stone, 12)     # Stone  
		EventSystem.INV_add_item_to_inventory.emit(ItemConfig.Keys.Flintstone, 2) # Flintstone
		EventSystem.INV_add_item_to_inventory.emit(ItemConfig.Keys.Coal, 1)       # Coal
		EventSystem.INV_add_item_to_inventory.emit(ItemConfig.Keys.RawMeat, 1)    # RawMeat
		EventSystem.INV_add_item_to_inventory.emit(ItemConfig.Keys.Plant, 20)     # Plants for testing
		
		print("[DEBUG] TEST: All campfire materials + plants added to inventory!")


func _switch_to_backpack() -> void:
	if not backpack_panel or not crafting_panel or not journal_panel:
		return
	backpack_panel.visible = true
	crafting_panel.visible = false
	journal_panel.visible = false
	var scrap_slot = get_node("%ScrapSlot") if has_node("%ScrapSlot") else null
	if scrap_slot:
		scrap_slot.visible = true
	if extra_info_label:
		extra_info_label.text = ""
	if backpack_tab_btn and crafting_tab_btn and journal_tab_btn:
		_set_tab_active(backpack_tab_btn, true)
		_set_tab_active(crafting_tab_btn, false)
		_set_tab_active(journal_tab_btn, false)


func _switch_to_crafting() -> void:
	if not backpack_panel or not crafting_panel or not journal_panel:
		return
	backpack_panel.visible = false
	crafting_panel.visible = true
	journal_panel.visible = false
	var scrap_slot = get_node("%ScrapSlot") if has_node("%ScrapSlot") else null
	if scrap_slot:
		scrap_slot.visible = false
	if item_info_label:
		item_info_label.text = ""
	if backpack_tab_btn and crafting_tab_btn and journal_tab_btn:
		_set_tab_active(crafting_tab_btn, true)
		_set_tab_active(backpack_tab_btn, false)
		_set_tab_active(journal_tab_btn, false)


func _switch_to_journal() -> void:
	print("[DEBUG] PlayerMenuBase: Switching to journal")
	if not backpack_panel or not crafting_panel or not journal_panel:
		return
	backpack_panel.visible = false
	crafting_panel.visible = false
	journal_panel.visible = true
	var scrap_slot = get_node("%ScrapSlot") if has_node("%ScrapSlot") else null
	if scrap_slot:
		scrap_slot.visible = false
	if item_info_label:
		item_info_label.text = ""
	_set_tab_active(journal_tab_btn, true)
	_set_tab_active(backpack_tab_btn, false)
	_set_tab_active(crafting_tab_btn, false)
	
	# Initialize journal with items category (with safety check)
	if items_tab_btn and journal_entry_container:
		_switch_journal_category(JournalConfig.Category.ITEMS)
	else:
		print("[WARNING] PlayerMenuBase: Journal UI elements not ready yet")


func _set_tab_active(btn: Button, active: bool) -> void:
	if not btn:
		return
	if active:
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		btn.modulate = Color(0.65, 0.60, 0.50, 1.0)


func show_item_info(inventory_slot: InventorySlot) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return

	var ik = inventory_slot.item_key
	if ik == null:
		return

	var item_key = ik.item_key if typeof(ik) == TYPE_DICTIONARY else ik
	var item_resource: ItemResource = ItemConfig.get_item_resource(item_key)
	if item_info_label:
		item_info_label.text = item_resource.display_name + "\n" + item_resource.description


func hide_item_info() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return

	if item_info_label:
		item_info_label.text = ""


func update_inventory(inventory: Array) -> void:
	if not inventory_slot_container:
		return
	for i in range(inventory.size()):
		if i < inventory_slot_container.get_child_count():
			inventory_slot_container.get_child(i).set_item_key(inventory[i])


func close() -> void:
	EventSystem.BUL_destroy_bulletin.emit(BulletinConfig.Keys.CraftingMenu)
	EventSystem.PLA_unfreeze_player.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)


# Journal-specific functions
func _request_journal_state() -> void:
	print("[DEBUG] PlayerMenuBase: Requesting journal state (deferred)")
	if EventSystem.has_signal("JOU_ask_state"):
		EventSystem.JOU_ask_state.emit()
	else:
		print("[WARNING] PlayerMenuBase: JOU_ask_state signal not found")


func _on_journal_state_updated(state_data) -> void:
	print("[DEBUG] PlayerMenuBase: Journal state updated:", state_data)
	# Handle both old format (just states) and new format (states + new_updates + read_entries)
	if state_data == null:
		print("[WARNING] PlayerMenuBase: Received null state_data")
		journal_states = {}
		journal_new_updates = {}
		journal_read_entries = {}
		return
		
	if typeof(state_data) == TYPE_DICTIONARY and state_data.has("states"):
		journal_states = state_data.get("states", {})
		journal_new_updates = state_data.get("new_updates", {})
		journal_read_entries = state_data.get("read_entries", {})
	else:
		# Fallback for old format
		journal_states = state_data if state_data != null else {}
		journal_new_updates = {}
		journal_read_entries = {}
	_refresh_journal_entries()


func _switch_journal_category(category: JournalConfig.Category) -> void:
	print("[DEBUG] PlayerMenuBase: Switching journal category to:", category)
	current_journal_category = category
	
	# Safety checks for tab buttons
	if items_tab_btn:
		_set_journal_tab_active(items_tab_btn, category == JournalConfig.Category.ITEMS)
	if creatures_tab_btn:
		_set_journal_tab_active(creatures_tab_btn, category == JournalConfig.Category.CREATURES)
	if objects_tab_btn:
		_set_journal_tab_active(objects_tab_btn, category == JournalConfig.Category.OBJECTS)
	
	_refresh_journal_entries()


func _set_journal_tab_active(btn: Button, active: bool) -> void:
	if not btn:
		return
	if active:
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		btn.modulate = Color(0.65, 0.60, 0.50, 1.0)


func _refresh_journal_entries() -> void:
	print("[DEBUG] PlayerMenuBase: Refreshing journal entries for category:", current_journal_category)
	
	# Safety check - ensure journal_entry_container exists
	if not journal_entry_container:
		print("[ERROR] PlayerMenuBase: journal_entry_container is null, cannot refresh")
		return
	
	# Clear existing entry buttons
	for button in entry_buttons:
		if is_instance_valid(button):
			button.queue_free()
	entry_buttons.clear()
	
	# Safety check - ensure journal_states is valid
	if journal_states == null:
		print("[DEBUG] PlayerMenuBase: journal_states is null, initializing empty")
		journal_states = {}
		
	if journal_new_updates == null:
		print("[DEBUG] PlayerMenuBase: journal_new_updates is null, initializing empty")
		journal_new_updates = {}
		
	if journal_read_entries == null:
		print("[DEBUG] PlayerMenuBase: journal_read_entries is null, initializing empty")
		journal_read_entries = {}
	
	# Get entries for current category
	var category_keys = JournalConfig.get_keys_by_category(current_journal_category) 
	print("[DEBUG] PlayerMenuBase: Found", category_keys.size(), "keys for category")
	
	# Create entry buttons for discovered items
	for key in category_keys:
		var int_key = int(key)  # Journal states uses int keys
		if journal_states.has(int_key) and journal_states[int_key] != JournalConfig.State.UNKNOWN:
			# Check if entry needs exclamation mark (new update OR not read yet)
			var has_new_update = false
			var is_unread = false
			if journal_new_updates != null:
				has_new_update = journal_new_updates.get(int_key, false)
			if journal_read_entries != null:
				is_unread = not journal_read_entries.get(int_key, false)
				
			var needs_exclamation = has_new_update or is_unread
			_create_journal_entry_button(key, journal_states[int_key], needs_exclamation)
	
	# Clear info area - with safety checks
	if journal_info_title:
		journal_info_title.text = ""
	if journal_info_desc:
		journal_info_desc.text = "Select an entry to see details"


func _create_journal_entry_button(key: JournalConfig.Keys, state: JournalConfig.State, needs_exclamation: bool = false) -> void:
	# Create container for entry
	var container = HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create main button with entry name
	var button = Button.new()
	button.text = JournalConfig.get_title(key)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Style based on state
	if state == JournalConfig.State.TESTED:
		button.modulate = Color(0.8, 1.0, 0.8)  # Green tint for tested
	else:
		button.modulate = Color(1.0, 1.0, 0.8)  # Yellow tint for discovered
	
	button.pressed.connect(_show_journal_entry_info.bind(key, state))
	
	# Add button to container
	container.add_child(button)
	
	# Add exclamation mark if needed - positioned on the right
	if needs_exclamation:
		var exclamation_label = Label.new()
		exclamation_label.text = "!"
		exclamation_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		exclamation_label.add_theme_font_size_override("font_size", 18)  # Make it larger
		exclamation_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		exclamation_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		container.add_child(exclamation_label)
	
	journal_entry_container.add_child(container)
	entry_buttons.append(container)  # Store container instead of button
	print("[DEBUG] PlayerMenuBase: Created entry button for:", JournalConfig.get_title(key))


func _show_journal_entry_info(key: JournalConfig.Keys, state: JournalConfig.State) -> void:
	# Mark entry as read (removes exclamation mark)
	EventSystem.JOU_entry_read.emit(int(key))
	
	if journal_info_title:
		journal_info_title.text = JournalConfig.get_title(key)
	
	if journal_info_desc:
		if state == JournalConfig.State.TESTED:
			journal_info_desc.text = JournalConfig.get_tested_text(key)
		else:
			journal_info_desc.text = JournalConfig.get_discovered_text(key)
