extends CharacterBody3D
## Customer: walks to a spot, asks for a random item,
## accepts ANY item you hand over, says thanks, walks back and disappears.
##
## Expected scene tree:
##   Customer (CharacterBody3D)  <- this script
##   ├── MeshInstance3D
##   ├── CollisionShape3D
##   └── Label3D
 
signal served
 
@export var items: Array[String] = ["Flour", "Eggs", "Sugar", "Butter"]
@export var walk_speed: float = 3.0
## Optional: a Marker3D where the customer waits. If empty, they wait where they spawn.
@export var wait_marker: Node3D
 
enum State { WALKING_IN, WAITING, LEAVING }
 
@onready var label: Label3D = $Label3D
 
var state: State = State.WALKING_IN
var wanted_item: String = ""
var start_pos: Vector3
var wait_pos: Vector3
 
func _ready() -> void:
	add_to_group("customer")
	start_pos = global_position
	wait_pos = wait_marker.global_position if wait_marker else global_position
	wanted_item = items.pick_random()
	label.text = ""
 
func _physics_process(delta: float) -> void:
	match state:
		State.WALKING_IN:
			if _move_to(wait_pos, delta):
				state = State.WAITING
				label.text = "I need: %s" % wanted_item
		State.LEAVING:
			if _move_to(start_pos, delta):
				queue_free()
 
func _move_to(target: Vector3, delta: float) -> bool:
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.05:
		return true
	var dir := to_target.normalized()
	global_position += dir * walk_speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 10.0 * delta)
	return false
 
## Called by the player when handing over an item.
## Returns true if accepted (the player then removes the item).
func receive_item(item: Node3D) -> bool:
	if state != State.WAITING:
		return false
	print("Customer got: ", item.name, " (wanted: ", wanted_item, ")")
	label.text = "Thanks!"
	state = State.LEAVING
	served.emit()
	return true
