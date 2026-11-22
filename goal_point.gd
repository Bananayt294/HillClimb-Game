
extends Area2D

@export var win_screen_scene: PackedScene

var triggered: bool = false


func _ready() -> void:

	monitoring = true

	body_entered.connect(_on_body_entered)

	print("GoalPoint initialized!")
	print("Monitoring: ", monitoring)
	print("Collision mask: ", collision_mask)


func _on_body_entered(body: Node2D) -> void:

	print("BODY DETECTED: ", body.name)
	print("Groups: ", body.get_groups())

	if triggered:
		return

	# Check if this is the player
	if not body.is_in_group("player"):
		print("This body is not in the player group!")
		return

	if win_screen_scene == null:
		push_error("WinScreen scene has not been assigned!")
		return

	triggered = true

	print("LEVEL COMPLETED!")

	var win_screen = win_screen_scene.instantiate()

	get_tree().current_scene.add_child(win_screen)
