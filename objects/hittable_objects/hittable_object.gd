extends Node3D


@export var attributes : HittableObjectAttributes
@export var residue_static_body : StaticBody3D

@onready var current_health := attributes.max_health


func _ready() -> void:
	if residue_static_body != null:
		remove_child(residue_static_body)


func register_hit(weapon_item_resource:WeaponItemResource) -> void:
	if not attributes.weapon_filter.is_empty() and not weapon_item_resource.item_key in attributes.weapon_filter:
		return
	
	current_health -= weapon_item_resource.damage
	
	if current_health <= 0:
		die()


func die() -> void:
	var scene_to_spawn := ItemConfig.get_pickuppable_item_scene(attributes.drop_item_key)
	
	for marker in $ItemSpawnPoints.get_children():
		EventSystem.SPA_spawn_scene.emit(scene_to_spawn, marker.global_transform)
	
	# If this is a component inside a pickuppable object, destroy the whole pickuppable
	if get_parent().has_method("_on_pickuppable_destroyed"):
		get_parent()._on_pickuppable_destroyed()
		return
	
	# Check if parent is a RigidBody3D (pickuppable object) - destroy it completely
	if get_parent() is RigidBody3D:
		get_parent().queue_free()
		return
	
	if residue_static_body == null:
		queue_free()
		return
	
	for child in get_children():
		child.queue_free()
	
	add_child(residue_static_body)
