extends CharacterBody2D

signal health_changed(value: int)
signal defeated
signal inventory_changed
signal time_bonus_requested(seconds: float)
signal item_notice(message: String)

const WALK_SPEED := 260.0
const RUN_SPEED := 390.0
const BASE_SCALE := 0.25
const DIRECTIONS := ["down", "up", "left", "right"]
const CAN_SCENE := preload("res://lata.tscn")
const MATCH_TEXTURE := preload("res://assets/sprites/recogibles/cerillo.png")

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
var cans := 0
var pans := 0
var selected_weapon := "can"
var hide_contacts := 0
var is_hidden := false
var jump_time := 0.0
var dodge_time := 0.0
var dodge_cooldown := 0.0
var jump_cooldown := 0.0
var leap_direction := Vector2.DOWN
var last_safe_position := Vector2.ZERO
var match_sprite: Sprite2D
var spawn_sheltered := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for action in ["idle", "walk", "run", "hurt", "throw", "jump", "dodge", "hide"]:
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
	last_safe_position = global_position
	health_changed.emit(health)
	inventory_changed.emit()


func _process(delta: float) -> void:
	invulnerability = maxf(0.0, invulnerability - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	jump_cooldown = maxf(0.0, jump_cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	if jump_time > 0.0:
		jump_time = maxf(0.0, jump_time - delta)
		if jump_time <= 0.0:
			if _over_low_obstacle():
				global_position = last_safe_position
			collision_mask = 18
			action_state = ""
	if dodge_time > 0.0:
		dodge_time = maxf(0.0, dodge_time - delta)
		if dodge_time <= 0.0:
			action_state = ""
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
	if jump_time > 0.0 or dodge_time > 0.0:
		velocity = leap_direction * (510.0 if jump_time > 0.0 else 680.0)
		move_and_slide()
		if jump_time > 0.0 and not _over_low_obstacle():
			last_safe_position = global_position
		return
	if action_state == "hurt":
		velocity = knockback * (action_timer / 0.45)
		move_and_slide()
		return
	if action_state == "throw":
		velocity = Vector2.ZERO
		return
	if Input.is_action_just_pressed("switch_weapon"):
		selected_weapon = "pan" if selected_weapon == "can" else "can"
		inventory_changed.emit()
	if Input.is_action_pressed("hide") and hide_contacts > 0:
		is_hidden = true
		velocity = Vector2.ZERO
		if sprite.animation != "hide_" + facing:
			sprite.play("hide_" + facing)
		return
	is_hidden = spawn_sheltered
	if Input.is_action_just_pressed("jump") and jump_cooldown <= 0.0:
		_start_leap(true)
		return
	if Input.is_action_just_pressed("dodge") and dodge_cooldown <= 0.0:
		_start_leap(false)
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
	if invulnerability > 0.0 or jump_time > 0.0 or dodge_time > 0.0 or health <= 0:
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


func enter_hide_zone() -> void:
	hide_contacts += 1
	item_notice.emit("Zona oscura: mantén H para ocultarte")


func exit_hide_zone() -> void:
	hide_contacts = maxi(0, hide_contacts - 1)
	is_hidden = false


func equip_match() -> void:
	if match_sprite != null:
		return
	match_sprite = Sprite2D.new()
	match_sprite.name = "CerilloEncendido"
	match_sprite.texture = MATCH_TEXTURE
	match_sprite.scale = Vector2.ONE * 0.07
	match_sprite.z_index = 1
	add_child(match_sprite)
	_update_match()


func match_light_position() -> Vector2:
	return global_position + Vector2(-28.0 if facing == "left" else 28.0, -20.0)


func _update_match() -> void:
	if match_sprite == null:
		return
	match_sprite.position = Vector2(-21.0 if facing == "left" else 21.0, -7.0)
	match_sprite.flip_h = facing == "left"
	match_sprite.rotation = sin(Time.get_ticks_msec() * 0.008) * 0.05


func collect_item(kind: String) -> bool:
	match kind:
		"can":
			cans += 1
			item_notice.emit("Recogiste una lata")
		"pan":
			pans += 1
			item_notice.emit("Recogiste una cacerola")
		"butter":
			var healed := mini(25, 100 - health)
			health += healed
			health_changed.emit(health)
			item_notice.emit("Mantequilla: vida al máximo" if healed == 0 else "Mantequilla: +%d de vida" % healed)
		"clock":
			time_bonus_requested.emit(10.0)
			item_notice.emit("Reloj: +10 segundos")
		_:
			return false
	inventory_changed.emit()
	return true


func _start_leap(jumping: bool) -> void:
	leap_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if leap_direction == Vector2.ZERO:
		leap_direction = _facing_vector()
	is_hidden = false
	if jumping:
		jump_time = 0.55
		jump_cooldown = 1.1
		action_timer = jump_time
		last_safe_position = global_position
		collision_mask = 2
		action_state = "jump"
		sprite.play("jump_" + facing)
	else:
		dodge_time = 0.28
		dodge_cooldown = 1.0
		action_timer = dodge_time
		action_state = "dodge"
		sprite.play("dodge_" + facing)


func _over_low_obstacle() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = Transform2D(0.0, global_position + $CollisionShape2D.position)
	query.collision_mask = 16
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _emit_defeated_after_hurt() -> void:
	await get_tree().create_timer(0.48).timeout
	if is_inside_tree():
		defeated.emit()


func _start_throw() -> void:
	if selected_weapon == "can" and cans <= 0 and pans > 0:
		selected_weapon = "pan"
	elif selected_weapon == "pan" and pans <= 0 and cans > 0:
		selected_weapon = "can"
	if cans + pans <= 0:
		item_notice.emit("Recoge una lata o cacerola para lanzar")
		return
	if selected_weapon == "can":
		cans -= 1
	else:
		pans -= 1
	inventory_changed.emit()
	action_state = "throw"
	action_timer = 0.42
	attack_cooldown = 1.0
	projectile_sent = false
	sprite.play("throw_" + facing)


func _launch_can() -> void:
	projectile_sent = true
	var can: Area2D = CAN_SCENE.instantiate()
	can.damage = 100 if selected_weapon == "can" else 150
	can.stun_duration = 2.0 if selected_weapon == "can" else 2.6
	can.item_kind = selected_weapon
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
		"jump": return 10.0
		"dodge": return 14.0
		"hide": return 9.0
		_: return 8.0


func _update_expression() -> void:
	_update_match()
	var step := sprite.frame
	if action_state == "hurt":
		sprite.position = Vector2((-1.0 if step % 2 == 0 else 1.0) * 7.0, -5.0)
		sprite.rotation = (-0.12 if step % 2 == 0 else 0.12)
		sprite.scale = Vector2(BASE_SCALE * 1.2, BASE_SCALE * 1.06)
	elif action_state == "throw":
		sprite.position = Vector2(0, -5 if step == 2 else 2)
		sprite.rotation = -0.09 if step == 1 else (0.13 if step == 2 else 0.0)
		sprite.scale = Vector2.ONE * BASE_SCALE * (1.13 if step == 2 else 1.0)
	elif action_state == "jump":
		var height := sin(PI * (1.0 - jump_time / 0.55)) * 24.0
		sprite.position = Vector2(0, -height)
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE * BASE_SCALE * 1.08
	elif action_state == "dodge":
		sprite.position = Vector2.ZERO
		sprite.rotation = -0.2 if facing == "left" else 0.2
		sprite.scale = Vector2.ONE * BASE_SCALE
	elif is_hidden:
		sprite.position = Vector2(0, 8)
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE * BASE_SCALE * 0.85
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
