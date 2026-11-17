extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const APEX_THRESHOLD = 45.0 # Vertical speed window near the top of the jump

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_starting_jump := false

func _ready() -> void:
	# Automatically switch from JUMP_START into the main JUMP animation once it finishes
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# 1. Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		is_starting_jump = false

	# 2. Handle jump input
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_starting_jump = true
		anim.play("JUMP_START")

	# 3. Handle horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animations(direction)

func update_animations(direction: float) -> void:
	# Grounded animations
	if is_on_floor():
		if direction != 0:
			anim.play("WALK")
		else:
			anim.play("IDLE")
		return

	# Airborne animations (don't interrupt JUMP_START while it's playing)
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
