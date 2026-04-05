extends Node


var bulletins := {}


func _enter_tree() -> void:
	EventSystem.connect_once("BUL_create_bulletin", Callable(self, "create_bulletin"))
	EventSystem.connect_once("BUL_destroy_bulletin", Callable(self, "destroy_bulletin"))
	EventSystem.connect_once("BUL_destroy_all_bulletins", Callable(self, "destroy_all_bulletins"))


func create_bulletin(bulletin_key:BulletinConfig.Keys, _extra_arg = null) -> void:
	if bulletins.has(bulletin_key):
		return
	print("[DEBUG] bulletin_controller.create_bulletin called for key:", bulletin_key)
	var new_bulletin:Bulletin = BulletinConfig.get_bulletin(bulletin_key)
	new_bulletin.initialize(_extra_arg)
	add_child(new_bulletin)
	bulletins[bulletin_key] = new_bulletin
	print("[DEBUG] bulletin instantiated and added to tree:", new_bulletin)


func destroy_bulletin(bulletin_key:BulletinConfig.Keys) -> void:
	if bulletins.has(bulletin_key):
		bulletins[bulletin_key].queue_free()
		bulletins.erase(bulletin_key)


func destroy_all_bulletins() -> void:
	for child in get_children():
		child.queue_free()
	
	bulletins.clear()
