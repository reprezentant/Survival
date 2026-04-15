extends Camera3D

@onready var equippable_camera: Camera3D = get_parent().get_node("EquippableCamera")


func _process(_delta: float) -> void:
	if equippable_camera != null and is_instance_valid(equippable_camera):
		equippable_camera.global_transform = global_transform
