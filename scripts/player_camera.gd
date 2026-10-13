extends Node3D

@export var target: Node3D
@export var follow_speed: float = 6.0
@export var rotation_smoothing: float = 14.0
@export var mouse_sensitivity: float = 0.003
@export var height_offset: float = 1.0
@export var min_pitch_deg: float = -60.0
@export var max_pitch_deg: float = -5.0

@onready var spring_arm: SpringArm3D = $SpringArm3D

var _yaw: float = 0.0
var _pitch: float = deg_to_rad(-30.0)

func _ready() -> void:
	top_level = true  # ignore parent's transform
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if target:
		global_position = target.global_position + Vector3.UP * height_offset
		if target is CollisionObject3D:
			spring_arm.add_excluded_object(target.get_rid())
	_yaw = rotation.y
	spring_arm.rotation.x = _pitch

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))

func _process(delta: float) -> void:
	if not target:
		return
	# Frame-rate independent smoothing (the "floaty" feel)
	var follow_w := 1.0 - exp(-follow_speed * delta)
	var rot_w := 1.0 - exp(-rotation_smoothing * delta)

	var goal := target.global_position + Vector3.UP * height_offset
	global_position = global_position.lerp(goal, follow_w)

	rotation.y = lerp_angle(rotation.y, _yaw, rot_w)
	spring_arm.rotation.x = lerp_angle(spring_arm.rotation.x, _pitch, rot_w)
