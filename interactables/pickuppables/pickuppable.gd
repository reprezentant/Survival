class_name Pickuppable
extends Interactable


@export var item_key : ItemConfig.Keys
@onready var object : Node3D = get_parent()


func start_interaction() -> void:
	# emit pickup request for a single unit
	EventSystem.INV_try_to_pickup_item.emit(item_key, destroy, 1)


func destroy() -> void:
	EventSystem.SFX_play_sfx.emit(SFXConfig.Keys.ItemPickup)
	object.queue_free()
