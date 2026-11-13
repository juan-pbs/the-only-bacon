extends CharacterBody2D

signal health_changed(value: int)
signal defeated

const WALK_SPEED := 260.0
const RUN_SPEED := 390.0
const BASE_SCALE := 0.32
const DIRECTIONS := ["down", "up", "left", "right"]
const CAN_SCENE := preload("res://lata.tscn")

var health := 100
var facing := "down"
var controls_enabled := true
var oil_contacts := 0
var invulnerability := 0.0
var action_state := ""
var action_timer := 0.0
var attack_cooldown := 0.0
var projectile_sent := false
var knockback := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for action in ["idle", "walk", "run", "hurt", "throw"]:
		for direction in DIRECTIONS:
			var animation: String = action + "_" + direction
			var texture: Texture2D = load("res://assets/sprites/tocino_animado/tiras/%s.png" % animation)
			frames.add_animation(animation)
			frames.set_animation_speed(animation, _animation_speed(action))
			frames.set_animation_loop(animation, action in ["idle", "walk", "run"])
			var frame_count := 2 if action == "idle" else 4
			for index in range(frame_count):
				var region := AtlasTexture.new()
				region.atlas = texture
				region.region = Rect2(index * 320, 0, 320, 320)
				frames.add_frame(animation, region)
	sprite.sprite_frames = frames
	sprite.play("idle_down")
	health_changed.emit(health)


func _process(delta: float) -> void:
	invulnerability = maxf(0.0, invulnerability - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if action_state != "":
		action_timer = maxf(0.0, action_timer - delta)
		if action_state == "throw" and not projectile_sent and action_timer <= 0.2:
			_launch_can()
		if action_timer <= 0.0:
			action_state = ""
	_update_expression()


func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		return
	if action_state == "hurt":
		velocity = knockback * (action_timer / 0.45)
		move_and_slide()
		return
	if action_state == "throw":
		velocity = Vector2.ZERO
		return
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		_start_throw()
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := Input.is_action_pressed("run")
	var speed := RUN_SPEED if running else WALK_SPEED
	if oil_contacts > 0:
		speed *= 0.55
	velocity = direction * speed
	move_and_slide()
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = "right" if direction.x > 0 else "left"
		else:
			facing = "down" if direction.y > 0 else "up"
	var action := "idle" if direction == Vector2.ZERO else ("run" if running else "walk")
	var animation := action + "_" + facing
	if sprite.animation != animation:
		sprite.play(animation)


func take_damage(amount: int, source: Vector2 = Vector2.ZERO) -> void:
	if invulnerability > 0.0 or health <= 0:
		return
	health = maxi(0, health - amount)
	invulnerability = 1.2
	knockback = (global_position - source).normalized() * 220.0 if source != Vector2.ZERO else -_facing_vector() * 220.0
	action_state = "hurt"
	action_timer = 0.45
	sprite.play("hurt_" + facing)
	health_changed.emit(health)
	if health == 0:
		controls_enabled = false
		_emit_defeated_after_hurt()


func enter_oil() -> void:
	oil_contacts += 1


func exit_oil() -> void:
	oil_contacts = maxi(0, oil_contacts - 1)


func _emit_defeated_after_hurt() -> void:
	await get_tree().create_timer(0.48).timeout
	if is_inside_tree():
		defeated.emit()


func _start_throw() -> void:
	action_state = "throw"
	action_timer = 0.42
	attack_cooldown = 1.0
	projectile_sent = false
	sprite.play("throw_" + facing)


func _launch_can() -> void:
	projectile_sent = true
	var can: Area2D = CAN_SCENE.instantiate()
	can.direction = _facing_vector()
	can.global_position = global_position + can.direction * 46.0
	get_parent().add_child(can)


func _facing_vector() -> Vector2:
	match facing:
		"up": return Vector2.UP
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
		_: return Vector2.DOWN


func _animation_speed(action: String) -> float:
	match action:
		"idle": return 3.0
		"run": return 12.0
		"hurt": return 10.0
		"throw": return 12.0
		_: return 8.0


func _update_expression() -> void:
	var step := sprite.frame
	if action_state == "hurt":
		sprite.position = Vector2((-1.0 if step % 2 == 0 else 1.0) * 7.0, -5.0)
		sprite.rotation = (-0.12 if step % 2 == 0 else 0.12)
		sprite.scale = Vector2(BASE_SCALE * 1.2, BASE_SCALE * 1.06)
	elif action_state == "throw":
		sprite.position = Vector2(0, -5 if step == 2 else 2)
		sprite.rotation = -0.09 if step == 1 else (0.13 if step == 2 else 0.0)
		sprite.scale = Vector2.ONE * BASE_SCALE * (1.13 if step == 2 else 1.0)
	elif sprite.animation.begins_with("walk") or sprite.animation.begins_with("run"):
		var amount := 1.0 if sprite.animation.begins_with("run") else 0.72
		sprite.position = Vector2((-1.0 if step % 2 == 0 else 1.0) * 3.5 * amount, (-5.5 if step % 2 == 0 else 3.0) * amount)
		sprite.rotation = (-0.075 if step in [0, 3] else 0.075) * amount
		sprite.scale = Vector2(BASE_SCALE * (1.0 + 0.075 * amount), BASE_SCALE * (1.0 - 0.06 * amount)) if step % 2 == 0 else Vector2(BASE_SCALE * (1.0 - 0.045 * amount), BASE_SCALE * (1.0 + 0.07 * amount))
	else:
		sprite.position = Vector2(0, -1 if step == 0 else 1)
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE * BASE_SCALE
	var flash_color := Color(1.0, 0.43, 0.43, 1.0) if int(Time.get_ticks_msec() / 90) % 2 == 0 else Color.WHITE
	sprite.modulate = flash_color if invulnerability > 0.0 else Color.WHITE
