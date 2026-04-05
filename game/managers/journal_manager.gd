extends Node


var _states: Dictionary = {}  # int(JournalConfig.Keys) -> JournalConfig.State
var _new_updates: Dictionary = {}  # int(JournalConfig.Keys) -> bool (has new update)
var _read_entries: Dictionary = {}  # int(JournalConfig.Keys) -> bool (has been read by player)


func _enter_tree() -> void:
	print("[DEBUG] JournalManager: Initializing...")
	for key in JournalConfig.get_all_keys():
		_states[int(key)] = JournalConfig.State.UNKNOWN
		_new_updates[int(key)] = false
		_read_entries[int(key)] = false

	print("[DEBUG] JournalManager: Connecting to events...")
	EventSystem.connect_once("JOU_ask_state", Callable(self, "_broadcast_state"))
	EventSystem.connect_once("JOU_discover", Callable(self, "_on_discover"))
	EventSystem.connect_once("JOU_test", Callable(self, "_on_test"))
	EventSystem.connect_once("JOU_entry_read", Callable(self, "mark_entry_as_read"))
	EventSystem.connect_once("INV_try_to_pickup_item", Callable(self, "_on_item_pickup"))
	print("[DEBUG] JournalManager: Initialization complete!")


# Item picked up from world → discover
func _on_item_pickup(item_key: ItemConfig.Keys, _destroy: Callable, _amount: int) -> void:
	print("[DEBUG] JournalManager: Item picked up - ", item_key)
	var journal_key = JournalConfig.map_item_key_to_journal_key(int(item_key))
	_on_discover(journal_key)


func _on_discover(entry_key: int) -> void:
	print("[DEBUG] JournalManager: Discovering entry - ", entry_key)
	
	# If it's from ItemConfig, map it to JournalConfig key
	var journal_entry_key = entry_key
	if entry_key <= 18:  # ItemConfig key range
		journal_entry_key = JournalConfig.map_item_key_to_journal_key(entry_key)
		print("[DEBUG] JournalManager: Mapped ItemConfig key ", entry_key, " to JournalConfig key ", journal_entry_key)
	
	if not _states.has(journal_entry_key):
		print("[DEBUG] JournalManager: Entry key not found in states!")
		return
	if _states[journal_entry_key] == JournalConfig.State.UNKNOWN:
		print("[DEBUG] JournalManager: Setting entry to DISCOVERED")
		_states[journal_entry_key] = JournalConfig.State.DISCOVERED
		_broadcast_state()
	else:
		print("[DEBUG] JournalManager: Entry already discovered/tested")


func _on_test(entry_key: int) -> void:
	# If it's from ItemConfig, map it to JournalConfig key
	var journal_entry_key = entry_key
	if entry_key <= 18:  # ItemConfig key range
		journal_entry_key = JournalConfig.map_item_key_to_journal_key(entry_key)
		print("[DEBUG] JournalManager: Mapped ItemConfig test key ", entry_key, " to JournalConfig key ", journal_entry_key)
	
	if not _states.has(journal_entry_key):
		return
	
	# First discover if not discovered yet
	if _states[journal_entry_key] == JournalConfig.State.UNKNOWN:
		_states[journal_entry_key] = JournalConfig.State.DISCOVERED
	
	# Then test
	if _states[journal_entry_key] != JournalConfig.State.TESTED:
		_states[journal_entry_key] = JournalConfig.State.TESTED
		# Mark as having new update when transitioning to TESTED
		_new_updates[journal_entry_key] = true
		_broadcast_state()


func _broadcast_state() -> void:
	print("[DEBUG] JournalManager: Broadcasting state update")
	print("[DEBUG] JournalManager: Current states: ", _states)
	
	# Safety check - ensure dictionaries are initialized
	if _states == null:
		_states = {}
	if _new_updates == null:
		_new_updates = {}
	if _read_entries == null:
		_read_entries = {}
	
	var state_data = {
		"states": _states.duplicate(),
		"new_updates": _new_updates.duplicate(),
		"read_entries": _read_entries.duplicate()
	}
	EventSystem.JOU_state_updated.emit(state_data)


# Function to mark entry as read (removes new update status)
func mark_entry_as_read(entry_key: int) -> void:
	print("[DEBUG] JournalManager: Marking entry as read - ", entry_key)
	if _new_updates == null:
		_new_updates = {}
	if _read_entries == null:
		_read_entries = {}
	
	# Mark as read and remove new update status
	if _new_updates.has(entry_key):
		_new_updates[entry_key] = false
	if _read_entries.has(entry_key):
		_read_entries[entry_key] = true
