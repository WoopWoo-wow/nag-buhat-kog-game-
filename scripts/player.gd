extends CharacterBody3D

@export var move_speed: float = 7.0
@export var gravity: float = 9.8

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

# WASD Movement Input
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	# Pick Up / Drop / Interact Input (J Key)
	if Input.is_key_pressed(KEY_J):
		if held_item == null:
			try_interact_or_pickup()
		else:
			drop_item()

	# Dash Input (Space / Enter)
	if Input.is_action_just_pressed("ui_accept") and can_dash:
		start_dash(direction)

	# Pick Up / Drop / Interact Input (E key)
	if Input.is_key_pressed(KEY_E):
		if held_item == null:
			try_interact_or_pickup()
		else:
			drop_item()

	# Movement Logic
	if is_dashing:
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
	else:
		if direction != Vector3.ZERO:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			look_at(global_position + direction, Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

func start_dash(move_dir: Vector3) -> void:
	is_dashing = true
	can_dash = false
	
	if move_dir != Vector3.ZERO:
		dash_direction = move_dir
	else:
		dash_direction = -transform.basis.z

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func try_interact_or_pickup() -> void:
	if interaction_area == null:
		return
		
	# 1. Check overlapping bodies (Chefs, Counters, etc.)
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("chef"):
			if body.has_method("give_item_to"):
				body.give_item_to(self)
				return

	# 2. Check overlapping areas (Pickable items)
	var overlapping_areas = interaction_area.get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("pickable"):
			held_item = area
			var parent = held_item.get_parent()
			if parent:
				parent.remove_child(held_item)
			hold_point.add_child(held_item)
			held_item.position = Vector3.ZERO
			return

func drop_item() -> void:
	if held_item == null:
		return
		
	# Check if player is standing in front of a customer to serve them
	var overlaps = interaction_area.get_overlapping_areas()
	for area in overlaps:
		if area.is_in_group("customer"):
			var customer = area.get_parent()
			if customer.has_method("receive_item"):
				var handed_over = customer.receive_item(held_item)
				if handed_over:
					held_item = null
					return

	# If not near a customer, drop item on the floor
	var current_global_pos = held_item.global_position
	hold_point.remove_child(held_item)
	get_tree().current_scene.add_child(held_item)
	held_item.global_position = current_global_pos
	held_item = null
