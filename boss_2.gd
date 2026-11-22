
extends CharacterBody2D

@export var move_speed: float = 120.0
@export var stop_distance: float = 8.0

@export var max_health: float = 300.0

var health: float = 300.0
var is_hurt: bool = false
var is_dead: bool = false


@export var attack_damage: float = 10.0

@export var attack1_hit_frame: int = 3
@export var attack2_hit_frame: int = 3
@export var attack3_hit_frame: int = 3


@export var hitbox_offset_x: float = 24.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
@onready var hit_box: Area2D = $HitBox


var player_target: Node2D = null
var hitbox_target: Node2D = null

var is_attacking: bool = false
var attack_hit_applied: bool = false


func _ready() -> void:

	health = max_health

	health_bar.max_value = max_health
	health_bar.value = health

	# Enable detection areas
	detection_area.monitoring = true
	hit_box.monitoring = true

	# Connect detection signals
	if not detection_area.body_entered.is_connected(_on_area_2d_body_entered):
		detection_area.body_entered.connect(_on_area_2d_body_entered)

	if not detection_area.body_exited.is_connected(_on_area_2d_body_exited):
		detection_area.body_exited.connect(_on_area_2d_body_exited)

	if not hit_box.body_entered.is_connected(_on_hit_box_body_entered):
		hit_box.body_entered.connect(_on_hit_box_body_entered)

	if not hit_box.body_exited.is_connected(_on_hit_box_body_exited):
		hit_box.body_exited.connect(_on_hit_box_body_exited)

	# Connect animation signals
	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

	if not anim.frame_changed.is_connected(_on_anim_frame_changed):
		anim.frame_changed.connect(_on_anim_frame_changed)

	print("Boss initialized!")
	print("Boss health: ", health)


func face_target(target: Node2D) -> void:

	if not is_instance_valid(target):
		return

	var difference: float = (
		target.global_position.x - global_position.x
	)

	if difference > 0.0:

		# Player is on the RIGHT
		anim.flip_h = false
		hit_box.position.x = absf(hitbox_offset_x)

	elif difference < 0.0:

		# Player is on the LEFT
		anim.flip_h = true
		hit_box.position.x = -absf(hitbox_offset_x)


func take_damage(amount: float) -> void:

	if is_dead:
		return

	health = clampf(health - amount, 0.0, max_health)

	health_bar.value = health

	print("Boss health: ", health, "/", max_health)

	# Check death
	if health <= 0.0:
		die()
		return

	# Flash red
	var tween := create_tween()

	anim.modulate = Color(1.0, 0.25, 0.25)

	tween.tween_property(
		anim,
		"modulate",
		Color.WHITE,
		0.2
	)

	# Play Hurt animation
	if not is_hurt:

		is_hurt = true
		is_attacking = false

		anim.speed_scale = 1.0
		anim.play("Hurt")

func die() -> void:

	if is_dead:
		return

	is_dead = true

	velocity = Vector2.ZERO

	print("Boss defeated!")

	queue_free()



func _on_area_2d_body_entered(body: Node2D) -> void:

	if body != self and body is CharacterBody2D:

		player_target = body

		print("Player entered detection area!")


func _on_area_2d_body_exited(body: Node2D) -> void:

	if body == player_target:

		player_target = null

		print("Player exited detection area!")

func _on_hit_box_body_entered(body: Node2D) -> void:

	if body != self and body is CharacterBody2D:

		hitbox_target = body

		print("Player entered boss HitBox!")


func _on_hit_box_body_exited(body: Node2D) -> void:

	if body == hitbox_target:

		hitbox_target = null

		print("Player exited boss HitBox!")


func find_target(area: Area2D) -> Node2D:

	for body in area.get_overlapping_bodies():

		if body != self and body is CharacterBody2D:

			return body

	return null


func start_attack(animation_name: String) -> void:

	attack_hit_applied = false

	anim.play(animation_name)


func _on_animation_finished() -> void:

	# HURT FINISHED
	if anim.animation == "Hurt":

		is_hurt = false
		anim.speed_scale = 1.0

		return

	if not is_attacking:
		return

	# THREE-STAGE ATTACK COMBO
	match anim.animation:

		"Attack-1":

			if is_instance_valid(hitbox_target):
				start_attack("Attack-2")
			else:
				is_attacking = false

		"Attack-2":

			if is_instance_valid(hitbox_target):
				start_attack("Attack-3")
			else:
				is_attacking = false

		"Attack-3":

			if is_instance_valid(hitbox_target):
				start_attack("Attack-1")
			else:
				is_attacking = false


func _on_anim_frame_changed() -> void:

	if not is_attacking:
		return

	if attack_hit_applied:
		return

	if not is_instance_valid(hitbox_target):
		return

	var hit_frame: int = -1

	match anim.animation:

		"Attack-1":
			hit_frame = attack1_hit_frame

		"Attack-2":
			hit_frame = attack2_hit_frame

		"Attack-3":
			hit_frame = attack3_hit_frame

	if hit_frame >= 0 and anim.frame == hit_frame:

		deal_damage()


func deal_damage() -> void:

	if not is_instance_valid(hitbox_target):
		return

	if hitbox_target.has_method("take_damage"):

		attack_hit_applied = true

		hitbox_target.take_damage(attack_damage)

		print("Boss dealt ", attack_damage, " damage!")

	else:

		push_warning("Target does not have a take_damage() function.")


func _physics_process(delta: float) -> void:

	if is_dead:
		return

	if not is_on_floor():

		velocity += get_gravity() * delta

	player_target = find_target(detection_area)

	hitbox_target = find_target(hit_box)

	
	if is_hurt:

		velocity.x = 0.0

	elif is_instance_valid(hitbox_target):

		velocity.x = 0.0

		face_target(hitbox_target)

		if not is_attacking:

			is_attacking = true

			start_attack("Attack-1")


	elif is_attacking:

		velocity.x = 0.0

	
	elif is_instance_valid(player_target):

		var difference: float = (
			player_target.global_position.x - global_position.x
		)

		# Always face the player
		face_target(player_target)

		# Player is on the RIGHT
		if difference > stop_distance:

			velocity.x = move_speed

			if anim.animation != "RUN":
				anim.play("RUN")

		# Player is on the LEFT
		elif difference < -stop_distance:

			velocity.x = -move_speed

			if anim.animation != "RUN":
				anim.play("RUN")

		# Player is close enough
		else:

			velocity.x = 0.0

			if anim.animation != "IDLE":
				anim.play("IDLE")

	else:

		velocity.x = 0.0

		if anim.animation != "IDLE":
			anim.play("IDLE")

	move_and_slide()
