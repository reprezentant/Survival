extends CharacterBody3D


@export var normal_speed := 3.0
@export var sprint_speed := 5.0
@export var walking_energy_consumption_per_1m := -0.05
@export var jump_velocity := 4.0
@export var gravity := 9.8
@export var walking_footstep_audio_interval := 0.6
@export var sprinting_footstep_audio_interval := 0.3

@onready var head: Node3D = $Head
var interaction_ray_cast: RayCast3D
var item_holder: ItemHolder
@onready var footstep_audio_timer: Timer = $FootstepAudioTimer

# Third Person Camera references (read-only, camera is controlled by CameraTemplate.gd)
var camera_h: Node3D
var player_mesh: Node3D
var animation_tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var skeleton: Skeleton3D
var hand_bone_idx: int = -1

var direction = Vector3.BACK
var is_grounded := true
var is_sprinting := false


func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventSystem.connect_once("PLA_freeze_player", Callable(self, "set_freeze").bind(true))
	EventSystem.connect_once("PLA_unfreeze_player", Callable(self, "set_freeze").bind(false))


func _ready() -> void:
	init_camera_references()
	EventSystem.HUD_show_hud.emit()


func init_camera_references():
	# Find camera_h for movement direction reference
	var camera = find_child("Camera3D", true, false)
	if camera:
		var v_node = camera.get_parent()
		if v_node and v_node.name == "v":
			camera_h = v_node.get_parent()
		interaction_ray_cast = camera.find_child("InteractionRayCast", true, false)
	
	# Find player mesh and animation
	var player_template = get_node_or_null("PlayerTemplate")
	if player_template:
		player_mesh = player_template.get_node_or_null("mannequiny-0_4_0")
		animation_tree = player_template.get_node_or_null("AnimationTree")
		if animation_tree:
			playback = animation_tree.get("parameters/playback")
		# Find skeleton and hand bone for weapon tracking
		if player_mesh:
			skeleton = player_mesh.find_child("Skeleton3D", true, false)
			if skeleton:
				hand_bone_idx = skeleton.find_bone("hand.r")
	
	item_holder = get_node_or_null("ItemHolder")


func _exit_tree() -> void:
	EventSystem.HUD_hide_hud.emit()


func set_freeze(freeze:bool) -> void:
	set_process(!freeze)
	set_physics_process(!freeze)
	set_process_input(!freeze)


func _process(_delta: float) -> void:
	if interaction_ray_cast != null:
		interaction_ray_cast.check_interaction()
	_update_item_holder()


func _update_item_holder() -> void:
	if skeleton == null or item_holder == null or hand_bone_idx < 0 or camera_h == null:
		return
	if item_holder.current_item_scene is EquippableConstructable:
		# Place ItemHolder in front of player so ItemPlaceRay hits the ground ahead
		item_holder.global_position = global_position + Vector3(0, 1.0, 0)
		item_holder.rotation.y = camera_h.global_rotation.y
		return
	# Convert bone local-space pose to world position
	var bone_pose := skeleton.get_bone_global_pose(hand_bone_idx)
	item_holder.global_position = skeleton.to_global(bone_pose.origin)
	# Orient toward where the camera (and player) is looking
	item_holder.rotation.y = camera_h.global_rotation.y


func _physics_process(delta: float) -> void:
	move(delta)
	check_walking_consumption(delta)
	
	if Input.is_action_just_pressed("use_equipped_item"):
		item_holder.try_to_use_item()


func move(delta: float):
	if is_on_floor():
		is_sprinting = Input.is_action_pressed("sprint")
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		
		if velocity != Vector3.ZERO and footstep_audio_timer.is_stopped():
			EventSystem.SFX_play_dynamic_sfx.emit(SFXConfig.Keys.Footstep, global_position, 0.3)
			footstep_audio_timer.start(walking_footstep_audio_interval if not is_sprinting else sprinting_footstep_audio_interval)
		
		if not is_grounded:
			is_grounded = true
			EventSystem.SFX_play_dynamic_sfx.emit(SFXConfig.Keys.JumpLand, global_position)
	else:
		velocity.y -= gravity
		if is_grounded:
			is_grounded = false
	
	var speed := normal_speed if not is_sprinting else sprint_speed
	var is_moving := false
	
	# Movement direction relative to camera (same as original PlayerTemplate.gd)
	var h_rot = 0.0
	if camera_h != null and is_instance_valid(camera_h):
		h_rot = camera_h.global_transform.basis.get_euler().y
	
	if (Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward") or
		Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
		direction = Vector3(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			0,
			Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward"))
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
		is_moving = true
	
	# Rotate mesh to face movement direction
	if player_mesh and is_moving:
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * 10)
	
	update_animations(is_moving)
	
	var horizontal_velocity = direction * speed if is_moving else Vector3.ZERO
	velocity.z = horizontal_velocity.z
	velocity.x = horizontal_velocity.x
	
	move_and_slide()


func check_walking_consumption(delta:float) -> void:
	if velocity.z or velocity.x:
		EventSystem.PLA_change_energy.emit(
			delta *
			walking_energy_consumption_per_1m *
			Vector2(velocity.z, velocity.x).length()
		)


func update_animations(is_moving: bool):
	if animation_tree and playback:
		animation_tree["parameters/conditions/IsOnFloor"] = is_on_floor()
		animation_tree["parameters/conditions/IsInAir"] = not is_on_floor()
		animation_tree["parameters/conditions/IsWalking"] = is_moving and not is_sprinting
		animation_tree["parameters/conditions/IsNotWalking"] = not is_moving
		animation_tree["parameters/conditions/IsRunning"] = is_moving and is_sprinting
		animation_tree["parameters/conditions/IsNotRunning"] = not is_sprinting


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		print("[DEBUG] ui_cancel pressed -> opening PauseMenu")
		EventSystem.BUL_create_bulletin.emit(BulletinConfig.Keys.PauseMenu)
	
	elif event.is_action_pressed("open_crafting_menu"):
		print("[DEBUG] open_crafting_menu action pressed -> emitting BUL_create_bulletin CraftingMenu")
		EventSystem.BUL_create_bulletin.emit(BulletinConfig.Keys.CraftingMenu)
	
	elif event.is_action_pressed("open_journal_menu"):
		print("[DEBUG] open_journal_menu action pressed -> emitting BUL_create_bulletin JournalMenu")
		EventSystem.BUL_create_bulletin.emit(BulletinConfig.Keys.JournalMenu)
	
	elif event.is_action_pressed("item_hotkey"):
		EventSystem.EQU_hotkey_pressed.emit(int(event.as_text()))
