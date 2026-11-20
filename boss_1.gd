
extends CharacterBody2D

# ==========================================
# MOVEMENT
# ==========================================

@export var move_speed: float = 120.0
@export var stop_distance: float = 8.0

# ==========================================
# BOSS HEALTH
# ==========================================

@export var max_health: float = 300.0
var is_hurt: bool = false
var health: float = 300.0
var is_dead: bool = false

# ==========================================
# ATTACK SETTINGS
# ==========================================

@export var attack_damage: float = 10.0

@export var attack1_hit_frame: int = 3
@export var attack2_hit_frame: int = 3
@export var attack3_hit_frame: int = 3

# ==========================================
# NODES
# ==========================================
@onready var health_bar: ProgressBar = $HealthBar
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D

# ==========================================
# VARIABLES
# ==========================================

var player_target: Node2D = null
var hitbox_target: Node2D = null

var is_attacking: bool = false
var attack_hit_applied: bool = false


# ==========================================
# READY
# ==========================================

func _ready() -> void:
	
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	anim.animation_finished.connect(_on_animation_finished)
	anim.frame_changed.connect(_on_anim_frame_changed)

	print("Boss health: ", health)


# ==========================================
# BOSS DAMAGE SYSTEM
# ==========================================

func take_damage(amount: float) -> void:

	if is_dead:
		return

	health = clampf(health - amount, 0.0, max_health)
	
	health_bar.value = health

	print("Boss health: ", health, "/", max_health)

	# Flash red when hit
	var tween := create_tween()

	anim.modulate = Color(1.0, 0.25, 0.25)

	tween.tween_property(
		anim,
		"modulate",
		Color.WHITE,
		0.2
	)
	if not is_hurt:
		is_hurt = true
		is_attacking = false
		anim.speed_scale = 1.0
		anim.play("Hurt")
	# Check death
	if health <= 0.0:
		die()


# ==========================================
# BOSS DEATH
# ==========================================

func die() -> void:

	if is_dead:
		return

	is_dead = true

	velocity = Vector2.ZERO

	print("Boss defeated!")

	queue_free()


# ==========================================
# DETECTION AREA
# ==========================================

func _on_area_2d_body_entered(body: Node2D) -> void:

	if body != self and body is CharacterBody2D:
		player_target = body


func _on_area_2d_body_exited(body: Node2D) -> void:

	if body == player_target:
		player_target = null


# ==========================================
# BOSS HITBOX
# ==========================================

func _on_hit_box_body_entered(body: Node2D) -> void:

	if body != self and body is CharacterBody2D:
		hitbox_target = body


func _on_hit_box_body_exited(body: Node2D) -> void:

	if body == hitbox_target:
		hitbox_target = null


# ==========================================
# ATTACK ANIMATIONS
# ==========================================

func start_attack(animation_name: String) -> void:

	attack_hit_applied = false

	anim.play(animation_name)


func _on_animation_finished() -> void:
	if anim.animation == "Hurt":
		is_hurt = false
		anim.speed_scale = 1.0
		return

	if not is_attacking:
		return

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


# ==========================================
# BOSS DAMAGE TO PLAYER
# ==========================================

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


# ==========================================
# PHYSICS PROCESS
# ==========================================

func _physics_process(delta: float) -> void:

	if is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Update detection target
	player_target = null

	for body in detection_area.get_overlapping_bodies():

		if body != self and body is CharacterBody2D:
			player_target = body
			break

	# Clear invalid targets
	if not is_instance_valid(hitbox_target):
		hitbox_target = null

	if is_hurt: 
		velocity.x = 0.0
		move_and_slide()
		return
	# ======================================
	# PRIORITY 1: ATTACK
	# ======================================

	if is_instance_valid(hitbox_target):

		velocity.x = 0.0

		# Face the player
		anim.flip_h = (
			hitbox_target.global_position.x < global_position.x
		)

		if not is_attacking:

			is_attacking = true

			start_attack("Attack-1")

	# ======================================
	# FINISH CURRENT ATTACK
	# ======================================

	elif is_attacking:

		velocity.x = 0.0

	# ======================================
	# PRIORITY 2: CHASE
	# ======================================

	elif is_instance_valid(player_target):

		var difference: float = (
			player_target.global_position.x - global_position.x
		)

		# Player is to the RIGHT
		if difference > stop_distance:

			velocity.x = move_speed
			anim.flip_h = false

			if anim.animation != "RUN":
				anim.play("RUN")

		# Player is to the LEFT
		elif difference < -stop_distance:

			velocity.x = -move_speed
			anim.flip_h = true

			if anim.animation != "RUN":
				anim.play("RUN")

		# Close to player
		else:

			velocity.x = 0.0

			if anim.animation != "IDLE":
				anim.play("IDLE")

	# ======================================
	# PRIORITY 3: IDLE
	# ======================================

	else:

		velocity.x = 0.0

		if anim.animation != "IDLE":
			anim.play("IDLE")

	move_and_slide()
