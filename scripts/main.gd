extends Node3D

@export var customer_scene: PackedScene   # drag customer.tscn here (optional)
@export var max_customers: int = 4
@export var spawn_interval: float = 5.0

@onready var counter: Node = find_child("Counter", true, false)
@onready var spawn_point: Marker3D = get_node_or_null("CustomerSpawn")

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

	if counter == null:
		push_error("Counter not found in Main!")
		return

	# Register any customers already placed in the scene
	for c in get_tree().get_nodes_in_group("customers"):
		c.exit_position = c.global_position
		counter.add_customer_to_queue(c)
		print("Registered existing customer: ", c.name)

	# Spawner is optional
	if customer_scene == null or spawn_point == null:
		print("Spawner off (customer_scene or CustomerSpawn missing)")
		return

	var t := Timer.new()
	t.wait_time = spawn_interval
	t.autostart = true
	t.timeout.connect(spawn_customer)
	add_child(t)

func spawn_customer() -> void:
	if counter.queue.size() >= max_customers:
		return
	var c = customer_scene.instantiate()
	add_child(c)
	c.global_position = spawn_point.global_position
	c.exit_position = spawn_point.global_position
	counter.add_customer_to_queue(c)
	print("Spawned customer")
