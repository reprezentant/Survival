class_name InventoryContextMenu
extends CanvasLayer

signal action_selected(action: String)


func _init() -> void:
	layer = 100


func setup(actions: Array[String], at_position: Vector2) -> void:
	# Full-screen backdrop — catches outside clicks to close menu
	var backdrop := Control.new()
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	backdrop.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			queue_free()
	)

	var panel := PanelContainer.new()
	panel.position = at_position
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	for action in actions:
		var btn := Button.new()
		btn.text = action
		btn.custom_minimum_size = Vector2(120, 34)
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func() -> void:
			action_selected.emit(action)
			queue_free()
		)
		vbox.add_child(btn)

	# Push menu onto screen if it would overflow right/bottom edge
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var screen := panel.get_viewport_rect().size
	var sz := panel.size
	if at_position.x + sz.x > screen.x:
		panel.position.x = at_position.x - sz.x
	if at_position.y + sz.y > screen.y:
		panel.position.y = at_position.y - sz.y
