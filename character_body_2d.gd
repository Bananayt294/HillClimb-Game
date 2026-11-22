extends CharacterBody2D

signal parry_succeeded(attacker: Node2D)

const SPEED = 180.0
const JUMP_VELOCITY = -340.0
const APEX_THRESHOLD = 45.0

const WALL_SLIDE_SPEED = 55.0
const WALL_JUMP_VELOCITY = Vector2(240.0, -330.0)
const CLIMB_SPEED = 105.0

const MAX_STAMINA = 100.0
const STAMINA_DRAIN = 28.0

@export var MAX_HEALTH: float = 100.0

const SAFE_FALL_SPEED = 520.0
const FALL_DAMAGE_MULTIPLIER = 0.12
const INVULNERABILITY_TIME = 0.8

const PARRY_WINDOW = 0.20
const PARRY_COOLDOWN = 0.45
const PARRY_IFRAMES = 0.15

@export var attack_damage: float = 25.0
@export var attack_hit_frame: int = 2

@export var attack_range_offset: float = 24.0

const ATTACK_ANIMATION = "Attack"

const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

var is_attacking: bool = false
var attack_hit_applied: bool = false
var attack_target: Node2D = null

var is_parrying: bool = false
var parry_timer: float = 0.0
var parry_cooldown_timer: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $AnimatedSprite2D/CanvasLayer/ProgressBar
@onready var attack_area: Area2D = $Hitbox

var health: float = MAX_HEALTH
var stamina: float = MAX_STAMINA

var is_hurt: bool = false
var is_climbing: bool = false
var is_starting_jump: bool = false
var is_dead: bool = false

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var wall_jump_lock_timer: float = 0.0
var invuln_timer: float = 0.0

var max_fall_speed: float = 0.0


func _ready() -> void:

	anim.animation_finished.connect(_on_animation_finished)
	anim.frame_changed.connect(_on_attack_frame_changed)

	health = MAX_HEALTH

	health_bar.max_value = MAX_HEALTH
	health_bar.value = health

	add_to_group("player")

	attack_area.monitoring = false


func take_damage(
	amount: float,
	use_iframes: bool = true,
	attacker: Node2D = null
) -> void:

	if is_dead:
		return

	if is_parrying and use_iframes:

		successful_parry(attacker)
		return

	if use_iframes and invuln_timer > 0.0:
		return

	health = clampf(health - amount, 0.0, MAX_HEALTH)
	health_bar.value = health

	print("Player health: ", health)

	if use_iframes:
		invuln_timer = INVULNERABILITY_TIME

	is_attacking = false
	attack_area.set_deferred("monitoring", false)
	attack_target = null

	is_hurt = true
	anim.speed_scale = 1.0
	anim.play("Hurt")

	if health <= 0.0:
		die()


func successful_parry(attacker: Node2D = null) -> void:

	if not is_parrying:
		return

	is_parrying = false
	parry_timer = 0.0

	invuln_timer = maxf(invuln_timer, PARRY_IFRAMES)

	print("PARRY SUCCESS!")

	parry_succeeded.emit(attacker)

	if is_instance_valid(attacker):
		if attacker.has_method("on_parried"):
			attacker.call("on_parried")


func heal(amount: float) -> void:

	if is_dead:
		return

	health = clampf(health + amount, 0.0, MAX_HEALTH)
	health_bar.value = health


func die() -> void:

	if is_dead:
		return

	is_dead = true

	print("Player Died!")

	get_tree().reload_current_scene()


func start_melee_attack() -> void:

	if is_attacking or is_hurt or is_dead or is_climbing or is_parrying:
		return

	is_attacking = true
	attack_hit_applied = false
	attack_target = null

	var facing := -1.0 if anim.flip_h else 1.0

	attack_area.position.x = attack_range_offset * facing

	attack_area.monitoring = true

	anim.speed_scale = 1.0
	anim.play(ATTACK_ANIMATION)


func _on_hitbox_body_entered(body: Node2D) -> void:

	if body == self:
		return

	if body is CharacterBody2D and body.has_method("take_damage"):
		attack_target = body


func _on_hitbox_body_exited(body: Node2D) -> void:

	if body == attack_target:
		attack_target = null


func _on_attack_frame_changed() -> void:

	if not is_attacking:
		return

	if is_hurt or attack_hit_applied:
		return

	if anim.animation != ATTACK_ANIMATION:
		return

	if anim.frame != attack_hit_frame:
		return

	attack_hit_applied = true

	if is_instance_valid(attack_target):

		if attack_target.has_method("take_damage"):

			attack_target.take_damage(attack_damage)

			print("Player dealt ", attack_damage, " damage to boss!")


func _physics_process(delta: float) -> void:

	if is_dead:
		return

	if parry_cooldown_timer > 0.0:
		parry_cooldown_timer = maxf(
			parry_cooldown_timer - delta,
			0.0
		)

	if is_parrying:

		parry_timer -= delta

		if parry_timer <= 0.0:

			is_parrying = false
			parry_timer = 0.0

			print("Parry missed!")

	if invuln_timer > 0.0:
		invuln_timer = maxf(invuln_timer - delta, 0.0)

	if Input.is_action_just_pressed("block"):

		if (
			not is_hurt
			and not is_attacking
			and not is_climbing
			and not is_parrying
			and parry_cooldown_timer <= 0.0
		):

			is_parrying = true
			parry_timer = PARRY_WINDOW
			parry_cooldown_timer = PARRY_COOLDOWN

			anim.speed_scale = 1.0
			anim.play("Block")

			print("Parry started!")

	if Input.is_action_just_pressed("attack"):

		if (
			not is_hurt
			and not is_attacking
			and not is_climbing
			and not is_parrying
		):
			start_melee_attack()

	var dir_x := Input.get_axis("Walk Backward", "Walk forward")
	var dir_y := Input.get_axis("Jump", "ui_down")

	if is_on_floor():

		if max_fall_speed > SAFE_FALL_SPEED:

			var fall_dmg := (
				max_fall_speed - SAFE_FALL_SPEED
			) * FALL_DAMAGE_MULTIPLIER

			take_damage(fall_dmg, false)

		max_fall_speed = 0.0

		coyote_timer = COYOTE_TIME
		stamina = MAX_STAMINA
		is_starting_jump = false

	else:

		coyote_timer -= delta

		if velocity.y > max_fall_speed:
			max_fall_speed = velocity.y

	if Input.is_action_just_pressed("Jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

	var wants_to_climb := (
		not is_attacking
		and not is_parrying
		and Input.is_action_pressed("climb")
		and is_on_wall_only()
		and stamina > 0.0
	)

	if wants_to_climb and wall_jump_lock_timer <= 0.0:

		is_climbing = true
		max_fall_speed = 0.0

		velocity.x = 0.0
		velocity.y = dir_y * CLIMB_SPEED

		stamina -= (
			STAMINA_DRAIN if dir_y != 0.0
			else STAMINA_DRAIN * 0.4
		) * delta

		var wall_normal := get_wall_normal()
		anim.flip_h = wall_normal.x > 0

	else:

		is_climbing = false

	if not is_climbing:

		if not is_on_floor():

			var pushing_wall: bool = (
				is_on_wall_only()
				and dir_x != 0.0
				and sign(dir_x) == -sign(get_wall_normal().x)
			)

			if pushing_wall and velocity.y > 0.0:

				velocity.y = min(
					velocity.y + get_gravity().y * delta,
					WALL_SLIDE_SPEED
				)

				max_fall_speed = velocity.y

			else:

				velocity += get_gravity() * delta

		if wall_jump_lock_timer <= 0.0:

			if is_attacking or is_parrying:

				velocity.x = move_toward(
					velocity.x,
					0.0,
					25.0
				)

			elif dir_x != 0.0:

				velocity.x = move_toward(
					velocity.x,
					dir_x * SPEED,
					25.0
				)

				anim.flip_h = dir_x < 0.0

			else:

				velocity.x = move_toward(
					velocity.x,
					0.0,
					20.0
				)

	if jump_buffer_timer > 0.0 and not is_attacking and not is_parrying:

		if coyote_timer > 0.0:

			velocity.y = JUMP_VELOCITY

			coyote_timer = 0.0
			jump_buffer_timer = 0.0

			is_starting_jump = true

			anim.play("JUMP_START")

		elif is_on_wall_only():

			var wall_normal := get_wall_normal()

			velocity.x = (
				wall_normal.x * WALL_JUMP_VELOCITY.x
			)

			velocity.y = WALL_JUMP_VELOCITY.y

			anim.flip_h = wall_normal.x < 0.0

			is_climbing = false
			max_fall_speed = 0.0

			jump_buffer_timer = 0.0
			wall_jump_lock_timer = 0.14

			stamina -= 15.0

	if (
		Input.is_action_just_released("Jump")
		and velocity.y < -80.0
	):

		velocity.y *= 0.55

	move_and_slide()

	update_animations(dir_x, dir_y)


func update_animations(dir_x: float, dir_y: float) -> void:

	if is_hurt:
		return

	if is_parrying:

		anim.speed_scale = 1.0

		if anim.animation != "Block":
			anim.play("Block")

		return

	if is_attacking:
		return

	if is_climbing:

		if dir_y != 0.0:
			anim.speed_scale = 0.7
			anim.play("WALK")
		else:
			anim.speed_scale = 1.0
			anim.play("IDLE")

		return

	anim.speed_scale = 1.0

	if is_on_floor():

		anim.play("WALK" if dir_x != 0.0 else "IDLE")
		return

	if is_starting_jump and anim.animation == "JUMP_START":
		return

	if absf(velocity.y) < APEX_THRESHOLD:
		anim.play("JUMP_TRANSITION")

	elif velocity.y < 0.0:
		anim.play("JUMP")

	else:
		anim.play("JUMP_FALL")


func _on_animation_finished() -> void:

	if anim.animation == "Hurt":

		is_hurt = false
		anim.speed_scale = 1.0

	elif anim.animation == ATTACK_ANIMATION:

		is_attacking = false
		attack_area.set_deferred("monitoring", false)
		attack_target = null

	elif anim.animation == "JUMP_START":

		is_starting_jump = false
