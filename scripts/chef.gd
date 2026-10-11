extends CharacterBody3D

@export var item_scene: PackedScene
@onready var order_label: Label3D = $Label3D if has_node("Label3D") else null

func _ready() -> void:
	add_to_group("chef")
	if order_label:
		order_label.text = "Need an ingredient?"

func give_item_to(player) -> bool:
	print("Chef: give_item_to was called!")
	
	if player.held_item != null:
		print("Chef: Player hands are full.")
		if order_label:
			order_label.text = "Your hands are full!"
		return false

	if item_scene != null:
		print("Chef: Spawning item...")
		var new_item = item_scene.instantiate()
		player.hold_point.add_child(new_item)
		new_item.position = Vector3.ZERO
		player.held_item = new_item
		if order_label:
			order_label.text = "Here you go!"
		return true

	print("Chef: Error - item_scene is null in the Inspector!")
	if order_label:
		order_label.text = "I have nothing to give!"
	return false

