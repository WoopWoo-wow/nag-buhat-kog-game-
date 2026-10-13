extends CharacterBody3D
 
@export var move_speed: float = 7.0
@export var acceleration: float = 12.0
@export var deceleration: float = 16.0
@export var rotation_speed: float = 12.0
@export var gravity: float = 9.8
@export var debug_print: bool = true
 
# --- Camera Reference ---
@export var camera_node: Node3D
 
# --- Dash Properties ---
@export var dash_speed: float = 20.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.8
 
var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector3 = Vector3.ZERO
 
# --- Node References ---
@onready var hold_point: Marker3D = $HoldPoint
@onready var interaction_area: Area3D = $InteractionArea
 
var held_item: Node3D = null
 
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
 
	var input_dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1.0
 
	input_dir.y = -input_dir.y
 
	input_dir = input_dir.normalized()
 
	# Calculate direction relative to Camera orientation
	var direction := Vector3.ZERO
	if camera_node:
		var cam_forward := -camera_node.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
 
		var cam_right := camera_node.global_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
 
		direction = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()
	else:
		direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
 
	var dash_pressed := Input.is_physical_key_pressed(KEY_SPACE) \
		or Input.is_physical_key_pressed(KEY_SHIFT) \
		or Input.is_action_just_pressed("ui_accept")
 
	if dash_pressed and can_dash:
		var d_dir = direction
		if d_dir == Vector3.ZERO:
			# Model faces +Z (see target_rotation below), so dash toward +Z
			d_dir = global_transform.basis.z
		start_dash(d_dir)
 
	if is_dashing:
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
	elif direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta * move_speed)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta * move_speed)
 
		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta * move_speed)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta * move_speed)
 
	move_and_slide()
 
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E or event.physical_keycode == KEY_J:
			if held_item == null:
				try_interact_or_pickup()
			else:
				drop_item()
 
func start_dash(move_dir: Vector3) -> void:
	is_dashing = true
	can_dash = false
	dash_direction = move_dir
 
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
 
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
 
func try_interact_or_pickup() -> void:
	if interaction_area == null:
		print("No InteractionArea found!")
		return
 
	var areas := interaction_area.get_overlapping_areas()
	if debug_print:
		print("E pressed. Nearby areas: ", areas.size())
		for a in areas:
			print(" - ", a.name, " groups: ", a.get_groups())
 
	for area in areas:
		if area.is_in_group("pickable") and area != held_item:
			held_item = area
			var parent = held_item.get_parent()
			if parent:
				parent.remove_child(held_item)
			hold_point.add_child(held_item)
			held_item.position = Vector3.ZERO
			held_item.rotation = Vector3.ZERO
			return
 
	for body in interaction_area.get_overlapping_bodies():
		if body.is_in_group("chef") and body.has_method("give_item_to"):
			body.give_item_to(self)
			return
 
func drop_item() -> void:
	if held_item == null:
		return
 
	var bodies := interaction_area.get_overlapping_bodies()
	if debug_print:
		print("Dropping. Bodies near me: ", bodies)
 
	for body in bodies:
		# Hand item to a waiting customer
		if body.is_in_group("customer") and body.has_method("receive_item"):
			if body.receive_item(held_item):
				held_item.queue_free()
				held_item = null
			return
		# Hand item to chef
		if body.is_in_group("chef"):
			held_item.queue_free()
			held_item = null
			return
 
	# Nobody nearby: drop on the ground
	var current_global_pos := held_item.global_position
	hold_point.remove_child(held_item)
	get_tree().current_scene.add_child(held_item)
	held_item.global_position = current_global_pos
	held_item = null
