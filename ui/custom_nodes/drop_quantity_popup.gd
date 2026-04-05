class_name DropQuantityPopup
extends CanvasLayer

signal drop_confirmed(amount: int)
signal drop_cancelled


func _init() -> void:
	layer = 100


func setup(item_key, max_amount: int, action_text: String = "Wyrzuć", show_warning: bool = false, _warning_type: String = "ostrzeżenie") -> void:
	# Full-screen root control on this CanvasLayer
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Semi-transparent overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	# CenterContainer centres the panel on screen
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var item_name := ItemConfig.get_item_resource(item_key).display_name
	var title := Label.new()
	title.text = action_text + " " + item_name + "?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Warning message (if needed)
	if show_warning:
		var warning_container := HBoxContainer.new()
		warning_container.alignment = BoxContainer.ALIGNMENT_CENTER
		warning_container.add_theme_constant_override("separation", 8)
		vbox.add_child(warning_container)
		
		var warning_icon := Label.new()
		warning_icon.text = "⚠️"
		warning_icon.add_theme_font_size_override("font_size", 18)
		warning_container.add_child(warning_icon)
		
		var warning_msg := Label.new()
		if _warning_type == "ZNIKNĄ NA ZAWSZE":
			warning_msg.text = "Te przedmioty ZNIKNĄ NA ZAWSZE!"
			warning_msg.add_theme_color_override("font_color", Color.RED)
			warning_msg.add_theme_font_size_override("font_size", 14)
		else:
			warning_msg.text = "Ten przedmiot jest cenny i może się zgubić!"
			warning_msg.add_theme_color_override("font_color", Color.ORANGE_RED)
		warning_container.add_child(warning_msg)

	# Amount counter
	var counter_label := Label.new()
	counter_label.text = "%d / %d" % [max_amount, max_amount]
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(counter_label)

	# Slider
	var slider := HSlider.new()
	slider.min_value = 1
	slider.max_value = max_amount
	slider.value = max_amount
	slider.step = 1
	slider.custom_minimum_size = Vector2(300, 28)
	vbox.add_child(slider)

	# SpinBox
	var spinbox := SpinBox.new()
	spinbox.min_value = 1
	spinbox.max_value = max_amount
	spinbox.value = max_amount
	spinbox.step = 1
	vbox.add_child(spinbox)

	# Sync slider ↔ spinbox ↔ counter
	slider.value_changed.connect(func(v: float) -> void:
		spinbox.set_value_no_signal(v)
		counter_label.text = "%d / %d" % [int(v), max_amount]
	)
	spinbox.value_changed.connect(func(v: float) -> void:
		slider.set_value_no_signal(v)
		counter_label.text = "%d / %d" % [int(v), max_amount]
	)

	# Buttons
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox)

	var cancel_btn := Button.new()
	cancel_btn.text = "Anuluj"
	cancel_btn.custom_minimum_size = Vector2(110, 36)
	cancel_btn.pressed.connect(_on_cancel)
	hbox.add_child(cancel_btn)

	var drop_btn := Button.new()
	drop_btn.text = action_text
	drop_btn.custom_minimum_size = Vector2(110, 36)
	drop_btn.pressed.connect(func() -> void:
		drop_confirmed.emit(int(spinbox.value))
		queue_free()
	)
	hbox.add_child(drop_btn)


func _on_cancel() -> void:
	drop_cancelled.emit()
	queue_free()
