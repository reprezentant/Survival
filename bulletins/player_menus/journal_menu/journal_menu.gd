extends PlayerMenuBase


@onready var items_tab_btn: Button = %ItemsTabBtn
@onready var creatures_tab_btn: Button = %CreaturesTabBtn
@onready var objects_tab_btn: Button = %ObjectsTabBtn
@onready var journal_entry_container: VBoxContainer = %JournalEntryContainer
@onready var journal_info_title: Label = %JournalInfoTitle
@onready var journal_info_desc: Label = %JournalInfoDesc

var journal_states: Dictionary = {}
var current_category: JournalConfig.Category = JournalConfig.Category.ITEMS
var entry_buttons: Array = []


func _ready() -> void:
	print("[DEBUG] JournalMenu: _ready() called")
	super()
	
	print("[DEBUG] JournalMenu: Checking if nodes exist...")
	if not items_tab_btn:
		print("[ERROR] JournalMenu: items_tab_btn is null!")
		return
	if not journal_entry_container:
		print("[ERROR] JournalMenu: journal_entry_container is null!")
		return
	
	print("[DEBUG] JournalMenu: All nodes found, proceeding...")
	
	# Connect category tab buttons
	items_tab_btn.pressed.connect(_switch_to_category.bind(JournalConfig.Category.ITEMS))
	creatures_tab_btn.pressed.connect(_switch_to_category.bind(JournalConfig.Category.CREATURES))
	objects_tab_btn.pressed.connect(_switch_to_category.bind(JournalConfig.Category.OBJECTS))
	
	# Connect to journal events - use regular connect instead of connect_once
	print("[DEBUG] JournalMenu: Connecting to JOU_state_updated")
	if not EventSystem.is_connected("JOU_state_updated", Callable(self, "_on_journal_state_updated")):
		EventSystem.connect("JOU_state_updated", Callable(self, "_on_journal_state_updated"))
	else:
		print("[DEBUG] JournalMenu: Already connected to JOU_state_updated")
	
	# Request current journal state
	print("[DEBUG] JournalMenu: Requesting journal state")
	EventSystem.JOU_ask_state.emit()
	
	# Auto-switch to journal tab when menu opens (override parent's _switch_to_backpack)
	_switch_to_journal()
	
	# Start with items category
	_switch_to_category(JournalConfig.Category.ITEMS)


func _on_journal_state_updated(states: Dictionary) -> void:
	print("[DEBUG] JournalMenu: Received state update with ", states.size(), " entries")
	journal_states = states
	_refresh_entries()


func _switch_to_category(category: JournalConfig.Category) -> void:
	current_category = category
	
	# Update tab buttons visual state
	_set_category_tab_active(items_tab_btn, category == JournalConfig.Category.ITEMS)
	_set_category_tab_active(creatures_tab_btn, category == JournalConfig.Category.CREATURES)
	_set_category_tab_active(objects_tab_btn, category == JournalConfig.Category.OBJECTS)
	
	# Clear info
	journal_info_title.text = "Select an entry to see details"
	journal_info_desc.text = ""
	
	_refresh_entries()


func _set_category_tab_active(btn: Button, active: bool) -> void:
	if active:
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		btn.modulate = Color(0.7, 0.7, 0.7, 1.0)


func _refresh_entries() -> void:
	print("[DEBUG] JournalMenu: Refreshing entries for category ", current_category)
	# Clear existing entries
	for child in journal_entry_container.get_children():
		child.queue_free()
	entry_buttons.clear()
	
	# Add entries for current category
	var keys = JournalConfig.get_all_keys()
	print("[DEBUG] JournalMenu: Total keys to check: ", keys.size())
	for key in keys:
		if JournalConfig.get_category(key) == current_category:
			print("[DEBUG] JournalMenu: Checking key ", key, " category matches")
			_create_entry_button(key)


func _create_entry_button(key: JournalConfig.Keys) -> void:
	var state = journal_states.get(int(key), JournalConfig.State.UNKNOWN)
	print("[DEBUG] JournalMenu: Creating entry for ", key, " with state ", state)
	
	# Skip unknown entries (not yet discovered)
	if state == JournalConfig.State.UNKNOWN:
		print("[DEBUG] JournalMenu: Skipping unknown entry")
		return
	
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 32)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Set button text with state indicator
	var title = JournalConfig.get_title(key)
	var state_icon = "👁" if state == JournalConfig.State.DISCOVERED else "⭐"
	button.text = state_icon + " " + title
	print("[DEBUG] JournalMenu: Button text set to: ", button.text)
	
	# Style based on state
	if state == JournalConfig.State.DISCOVERED:
		button.modulate = Color(1.0, 0.8, 0.4, 1.0)  # Orange tint for discovered
	else:
		button.modulate = Color(0.4, 1.0, 0.4, 1.0)  # Green tint for tested
	
	# Connect button
	button.pressed.connect(_on_entry_selected.bind(key))
	
	# Add icon if it's an item (items have icons)
	if current_category == JournalConfig.Category.ITEMS:
		var icon = JournalConfig.get_icon(key)
		if icon:
			button.icon = icon
	
	journal_entry_container.add_child(button)
	entry_buttons.append(button)
	print("[DEBUG] JournalMenu: Button added to container")


func _on_entry_selected(key: JournalConfig.Keys) -> void:
	var state = journal_states.get(int(key), JournalConfig.State.UNKNOWN)
	var title = JournalConfig.get_title(key)
	
	journal_info_title.text = title.to_upper()
	
	if state == JournalConfig.State.DISCOVERED:
		journal_info_desc.text = JournalConfig.get_discovered_text(key)
	elif state == JournalConfig.State.TESTED:
		journal_info_desc.text = JournalConfig.get_tested_text(key)
	else:
		journal_info_desc.text = "Entry not yet discovered."


# Override to also switch to journal when menu opens
func _switch_to_journal() -> void:
	super._switch_to_journal()
	# Request fresh journal state when switching to journal
	EventSystem.JOU_ask_state.emit()


func close() -> void:
	EventSystem.BUL_destroy_bulletin.emit(BulletinConfig.Keys.JournalMenu)
	EventSystem.PLA_unfreeze_player.emit()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.UIClick)