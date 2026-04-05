extends Node

@onready var hud: Control = $HUD

func _enter_tree() -> void:
	EventSystem.connect_once("HUD_hide_hud", Callable(self, "hide_hud"))
	EventSystem.connect_once("HUD_show_hud", Callable(self, "show_hud"))


func _ready() -> void:
	hide_hud()


func hide_hud() -> void:
	remove_child(hud)


func show_hud() -> void:
	add_child(hud)
