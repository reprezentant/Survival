extends HBoxContainer


var _connected := false

func _enter_tree() -> void:
	if _connected:
		return

	EventSystem.connect_once("INV_hotbar_updated", Callable(self, "update_hotbar"))
	EventSystem.connect_once("EQU_active_hotbar_slot_updated", Callable(self, "update_active_slot"))
	# EQU_unequip_item is emitted without arguments in several places.
	# Connect it to a small wrapper that accepts no args and forwards a `null`
	# to update_active_slot to avoid a runtime "expected 1 argument(s), but called with 0" error.
	EventSystem.connect_once("EQU_unequip_item", Callable(self, "on_unequip_item"))

	_connected = true


func update_hotbar(hotbar:Array) -> void:
	for slot in get_children():
		slot.set_item_key(hotbar[slot.get_index()])


func update_active_slot(slot_index) -> void:
	for slot in get_children():
		slot.set_active(slot.get_index() == slot_index)


func on_unequip_item() -> void:
	# when unequipping, no slot index is provided -> mark all slots inactive
	update_active_slot(null)
