extends CharacterBody2D

# Movement & Jump
const SPEED = 180.0
const JUMP_VELOCITY = -340.0
const APEX_THRESHOLD = 45.0

# Climbing & Wall Physics
const WALL_SLIDE_SPEED = 55.0
const WALL_JUMP_VELOCITY = Vector2(240.0, -330.0)
const CLIMB_SPEED = 105.0
const MAX_STAMINA = 100.0
const STAMINA_DRAIN = 28.0 # ~3.5 seconds of continuous climbing

# Health & Damage
const MAX_HEALTH = 100.0
const SAFE_FALL_SPEED = 520.0 # Falling faster than this deals damage on landing
const FALL_DAMAGE_MULTIPLIER = 0.12
const INVULNERABILITY_TIME = 0.8

# Game Feel Timers
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
# Make sure CanvasLayer is a direct child of CharacterBody2D
@onready var health_bar: ProgressBar = $AnimatedSprite2D/CanvasLayer/ProgressBar

var health := MAX_HEALTH
var stamina := MAX_STAMINA
var is_climbing := false
var is_starting_jump := false
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var wall_jump_lock_timer := 0.0
var invuln_timer := 0.0
var max_fall_speed := 0.0

func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	health_bar.max_value = MAX_HEALTH
	health_bar.value = health

func _physics_process(delta: float) -> void:
	var dir_x := Input.get_axis("Walk Backward", "Walk forward")
	var dir_y := Input.get_axis("Jump", "ui_down")

	# 1. Update timers
	if invuln_timer > 0:
		invuln_timer -= delta

	if is_on_floor():
		# Check for fall damage right when landing
		if max_fall_speed > SAFE_FALL_SPEED:
			var fall_dmg := (max_fall_speed - SAFE_FALL_SPEED) * FALL_DAMAGE_MULTIPLIER
			take_damage(fall_dmg, false) # false = fall damage ignores i-frames
		max_fall_speed = 0.0

		coyote_timer = COYOTE_TIME
		stamina = MAX_STAMINA
		is_starting_jump = false
	else:
		coyote_timer -= delta
		# Record peak downward speed while airborne
		if velocity.y > max_fall_speed:
			max_fall_speed = velocity.y

	if Input.is_action_just_pressed("Jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	if wall_jump_lock_timer > 0:
		wall_jump_lock_timer -= delta

	# 2. Wall Grab & Vertical Climb (Hold "climb" while touching a wall)
	var wants_to_climb := Input.is_action_pressed("climb") and is_on_wall_only() and stamina > 0
	if wants_to_climb and wall_jump_lock_timer <= 0:
		is_climbing = true
		max_fall_speed = 0.0 # Grabbing a wall saves you from fall damage
		velocity.x = 0
		velocity.y = dir_y * CLIMB_SPEED
		stamina -= (STAMINA_DRAIN if dir_y != 0 else STAMINA_DRAIN * 0.4) * delta

		var wall_normal := get_wall_normal()
		anim.flip_h = wall_normal.x > 0
	else:
		is_climbing = false

	# 3. Gravity & Wall Slide
	if not is_climbing:
		if not is_on_floor():
			var pushing_wall: bool = is_on_wall_only() and dir_x != 0 and sign(dir_x) == -sign(get_wall_normal().x)
			if pushing_wall and velocity.y > 0:
				velocity.y = min(velocity.y + get_gravity().y * delta, WALL_SLIDE_SPEED)
				max_fall_speed = velocity.y # Wall sliding slows your fall safely
			else:
				velocity += get_gravity() * delta

		# 4. Horizontal movement
		if wall_jump_lock_timer <= 0:
			if dir_x != 0:
				velocity.x = move_toward(velocity.x, dir_x * SPEED, 25.0)
				anim.flip_h = dir_x < 0
			else:
				velocity.x = move_toward(velocity.x, 0, 20.0)

	# 5. Ground Jump & Wall Jump
	if jump_buffer_timer > 0:
		if coyote_timer > 0:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0
			jump_buffer_timer = 0
			is_starting_jump = true
			anim.play("JUMP_START")
		elif is_on_wall_only():
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x * WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y
			anim.flip_h = wall_normal.x < 0
			is_climbing = false
			max_fall_speed = 0.0
			jump_buffer_timer = 0
			wall_jump_lock_timer = 0.14
			stamina -= 15.0

	# Variable jump height
	if Input.is_action_just_released("Jump") and velocity.y < -80.0:
		velocity.y *= 0.55

	move_and_slide()
	update_animations(dir_x, dir_y)

func take_damage(amount: float, use_iframes: bool = true) -> void:
	if use_iframes and invuln_timer > 0:
		return

	health = clamp(health - amount, 0.0, MAX_HEALTH)
	health_bar.value = health
	
	if use_iframes:
		invuln_timer = INVULNERABILITY_TIME

	# Flash sprite red briefly when hit
	var tween := create_tween()
	anim.modulate = Color(1.0, 0.25, 0.25)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.25)

	if health <= 0.0:
		die()

func heal(amount: float) -> void:
	health = clamp(health + amount, 0.0, MAX_HEALTH)
	health_bar.value = health

func die() -> void:
	get_tree().reload_current_scene()

func update_animations(dir_x: float, dir_y: float) -> void:
	if is_climbing:
		if dir_y != 0:
			anim.speed_scale = 0.7
			anim.play("WALK")
		else:
			anim.speed_scale = 1.0
			anim.play("IDLE")
		return

	anim.speed_scale = 1.0

	if is_on_floor():
		anim.play("WALK" if dir_x != 0 else "IDLE")
		return

	if is_starting_jump and anim.animation == "JUMP_START":
		return

	if abs(velocity.y) < APEX_THRESHOLD:
		anim.play("JUMP_TRANSITION")
	elif velocity.y < 0:
		anim.play("JUMP")
	else:
		anim.play("JUMP_FALL")

func _on_animation_finished() -> void:
	if anim.animation == "JUMP_START":
		is_starting_jump = false
