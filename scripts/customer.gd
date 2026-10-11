extends CharacterBody3D

@export var move_speed: float = 4.0
@export var wanted_item_group: String = "pickable"

# Set these target positions when spawning/placing in the scene
var target_position: Vector3 = Vector3.ZERO
var exit_position: Vector3 = Vector3.ZERO

enum State { MOVING_TO_COUNTER, WAITING_FOR_ORDER, LEAVING }
var current_state: State = State.MOVING_TO_COUNTER

@onready var order_label: Label3D = $Label3D
@onready var customer_area: Area3D = $CustomerArea

func _ready() -> void:
	customer_area.add_to_group("customer")
	order_label.visible = false

func _physics_process(delta: float) -> void:
	match current_state:
		State.MOVING_TO_COUNTER:
			move_towards_target(target_position)
			# Check if reached counter position (ignoring Y height)
			var dist = Vector2(global_position.x - target_position.x, global_position.z - target_position.z).length()
			if dist < 0.5:
				current_state = State.WAITING_FOR_ORDER
				show_order()

		State.WAITING_FOR_ORDER:
			velocity = Vector3.ZERO

		State.LEAVING:
			move_towards_target(exit_position)
			var dist = Vector2(global_position.x - exit_position.x, global_position.z - exit_position.z).length()
			if dist < 0.5:
				queue_free() # Despawn customer once reached exit

	move_and_slide()

func move_towards_target(target: Vector3) -> void:
	var dir = (target - global_position)
	dir.y = 0
	if dir.length() > 0.1:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0

func show_order() -> void:
	order_label.text = "I want: " + wanted_item_group.capitalize() + "!"
	order_label.visible = true

func receive_item(item: Node3D) -> bool:
	if current_state != State.WAITING_FOR_ORDER:
		return false
		
	# Check if handed item is valid
	if item.is_in_group(wanted_item_group):
		order_label.text = "Thank you!"
		item.queue_free() # Consume/remove the item
		current_state = State.LEAVING
		return true
		
	return false
