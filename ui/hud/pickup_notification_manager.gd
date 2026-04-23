extends CanvasLayer

# Queue of notifications to display
var notification_queue: Array = []
var is_showing := false

# Notification display time (seconds)
const DISPLAY_TIME := 2.0

# Reference to the notification UI node
var notification_panel: Control

func _ready():
	# Instance the notification panel scene
	notification_panel = preload("res://ui/hud/pickup_notification_panel.tscn").instantiate()
	add_child(notification_panel)
	notification_panel.hide()
	# Connect EventSystem signal
	EventSystem.UI_show_pickup_notification.connect(show_pickup)

func show_pickup(item_key, amount = 1):
	# Add to queue
	notification_queue.append({"item_key": item_key, "amount": amount})
	if not is_showing:
		_show_next()

func _show_next():
	if notification_queue.size() == 0:
		is_showing = false
		return
	is_showing = true
	var data = notification_queue.pop_front()
	notification_panel.show_notification(data.item_key, data.amount)
	await get_tree().create_timer(DISPLAY_TIME).timeout
	notification_panel.hide()
	_show_next()
