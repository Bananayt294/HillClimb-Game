extends Area2D

@export var speed := 350.0
@onready var sprite:Sprite2D = $Sprite2D
var target_body: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		print("player entered the area!")
		target_body = body
		
func _physics_process(delta: float) -> void:
	if target_body != null: 
		sprite.global_position = sprite.global_position.move_toward(
			target_body.global_position, 
			speed * delta
		)
