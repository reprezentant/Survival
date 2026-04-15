extends Node3D

# Allows to select the player mesh from the inspector
#@export_node_path(Node3D) var PlayerCharacterMesh: NodePath
#@onready var player_mesh = get_node(PlayerCharacterMesh)

var camrot_h = PI
var camrot_v = -0.25
@export var cam_v_max = 60
@export var cam_v_min = -35
@export var joystick_sensitivity = 20
var h_sensitivity = 0.003
var v_sensitivity = 0.003
var h_acceleration = 20
var v_acceleration = 20
var joyview = Vector2()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Initialize h node to match starting rotation so lerp doesn't spin
	$h.rotation.y = camrot_h
	$h/v.rotation.x = camrot_v
	
func _input(event):
	if event is InputEventMouseMotion:
		camrot_h -= event.relative.x * h_sensitivity
		camrot_v -= event.relative.y * v_sensitivity
		# Clamp vertical immediately to prevent overshooting
		camrot_v = clamp(camrot_v, deg_to_rad(cam_v_min), deg_to_rad(cam_v_max))
		
func _joystick_input():
	if (Input.is_action_pressed("ui_up") ||  Input.is_action_pressed("ui_down") ||  Input.is_action_pressed("ui_left") ||  Input.is_action_pressed("ui_right")):
		
		joyview.x = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
		joyview.y = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
		camrot_h += joyview.x * joystick_sensitivity * h_sensitivity
		camrot_v += joyview.y * joystick_sensitivity * v_sensitivity 
		
func _physics_process(delta):
	# JoyPad Controls
	_joystick_input()
		
	camrot_v = clamp(camrot_v, deg_to_rad(cam_v_min), deg_to_rad(cam_v_max))

	$h.rotation.y = lerp_angle($h.rotation.y, camrot_h, delta * h_acceleration)
	$h/v.rotation.x = lerpf($h/v.rotation.x, camrot_v, delta * v_acceleration)
	
