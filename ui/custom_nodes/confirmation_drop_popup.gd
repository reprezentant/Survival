class_name ConfirmationDropPopup
extends CanvasLayer

signal drop_confirmed
signal drop_cancelled


func _init() -> void:
	layer = 100


func setup(item_resource: ItemResource) -> void:
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
	panel.custom_minimum_size = Vector2(380, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Warning icon and title
	var title_container := HBoxContainer.new()
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_container)
	
	var warning_label := Label.new()
	warning_label.text = "⚠️"
	warning_label.add_theme_font_size_override("font_size", 24)
	title_container.add_child(warning_label)
	
	var title := Label.new()
	title.text = "Czy na pewno chcesz usunąć?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title_container.add_child(title)

	# Item info
	var item_info := HBoxContainer.new()
	item_info.alignment = BoxContainer.ALIGNMENT_CENTER
	item_info.add_theme_constant_override("separation", 10)
	vbox.add_child(item_info)
	
	var icon := TextureRect.new()
	icon.texture = item_resource.icon
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	item_info.add_child(icon)
	
	var item_label := Label.new()
	item_label.text = item_resource.display_name
	item_label.add_theme_font_size_override("font_size", 18)
	item_info.add_child(item_label)

	# Warning message
	var warning_msg := Label.new()
	warning_msg.text = "Ten przedmiot jest cenny i trudny do odzyskania."
	warning_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_msg.add_theme_color_override("font_color", Color.ORANGE_RED)
	vbox.add_child(warning_msg)

	# Buttons
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox)

	var cancel_btn := Button.new()
	cancel_btn.text = "Anuluj"
	cancel_btn.custom_minimum_size = Vector2(120, 36)
	cancel_btn.pressed.connect(_on_cancel)
	hbox.add_child(cancel_btn)

	var drop_btn := Button.new()
	drop_btn.text = "Usuń"
	drop_btn.custom_minimum_size = Vector2(120, 36)
	drop_btn.modulate = Color.LIGHT_CORAL
	drop_btn.pressed.connect(_on_confirm)
	hbox.add_child(drop_btn)


func _on_cancel() -> void:
	drop_cancelled.emit()
	queue_free()


func _on_confirm() -> void:
	drop_confirmed.emit()
	queue_free()