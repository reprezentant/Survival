class_name HotbarSlot
extends InventorySlot


const ACTIVE_COLOR = Color.WHITE
const INACTIVE_COLOR = Color(0.8, 0.8, 0.8, 0.6)


func _ready() -> void:
	$HotkeyTextureRect/HotkeyLabel.text = str(get_index() + 1)


func _can_drop_data(_at_position: Vector2, slot: Variant) -> bool:
	var key = null
	# If drag data is a slot node (InventorySlot or HotbarSlot), extract its item_key
	if slot is InventorySlot:
		var ik = slot.item_key
		key = ik.item_key if typeof(ik) == TYPE_DICTIONARY else ik
	else:
		# slot may be a raw key (int) or a dictionary {item_key, amount}
		key = slot.item_key if typeof(slot) == TYPE_DICTIONARY else slot

	# Defensive: if key is still null or invalid, reject the drop
	if key == null:
		return false

	return ItemConfig.get_item_resource(key).is_equippable


func set_active(active:bool) -> void:
	modulate = INACTIVE_COLOR if not active else ACTIVE_COLOR
