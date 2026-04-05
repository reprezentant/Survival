extends Node


var active_slot
var hotbar:Array

var _connected := false


func _enter_tree() -> void:
	if _connected:
		return

	EventSystem.connect_once("INV_hotbar_updated", Callable(self, "hotbar_updated"))
	EventSystem.connect_once("EQU_hotkey_pressed", Callable(self, "hotkey_pressed"))
	EventSystem.connect_once("EQU_delete_equipped_item", Callable(self, "delete_equipped_item"))

	_connected = true


func _ready() -> void:
	EventSystem.EQU_active_hotbar_slot_updated.emit(null)


func hotbar_updated(_hotbar:Array) -> void:
	hotbar = _hotbar

	if active_slot != null:
		var slot = hotbar[active_slot]
		if slot == null:
			EventSystem.EQU_unequip_item.emit()
			active_slot = null


func hotkey_pressed(hotkey:int) -> void:
	var hotkey_index := hotkey - 1

	# Defensive checks: hotbar may not be initialized yet or index may be out of bounds
	if typeof(hotbar) != TYPE_ARRAY or hotbar.is_empty():
		return
	if hotkey_index < 0 or hotkey_index >= hotbar.size():
		return

	var slot = hotbar[hotkey_index]
	if slot == null:
		return

	# slot can be either an ItemConfig.Keys (legacy) or a dictionary { item_key, amount }
	var item_to_equip = slot.item_key if typeof(slot) == TYPE_DICTIONARY else slot

	if hotkey_index != active_slot:
		active_slot = hotkey_index
		EventSystem.EQU_equip_item.emit(item_to_equip)
		EventSystem.EQU_active_hotbar_slot_updated.emit(hotkey_index)

	else:
		active_slot = null
		EventSystem.EQU_unequip_item.emit()


func delete_equipped_item() -> void:
	EventSystem.INV_delete_item_by_index.emit(active_slot, true)
	EventSystem.EQU_active_hotbar_slot_updated.emit(null)
	active_slot = null
