extends CharacterBody2D

const TLACUA_ATLAS := preload("res://assets/sprites/acciones/tlacua-direcciones.png")
const CUACHE_ATLAS := preload("res://assets/sprites/acciones/cuache-direcciones.png")
const TLACUA_ACTIONS := preload("res://assets/sprites/acciones/tlacua-acciones.png")
const CUACHE_ACTIONS := preload("res://assets/sprites/acciones/cuache-acciones.png")
const DIRECTIONS := ["down", "left", "right", "up"]
const MAX_HEALTH := 400
const CAN_DAMAGE := 100

@export_enum("tlacua", "cuache") var kind := "tlacua"
var target: CharacterBody2D
var patrol_points: Array[Vector2] = []
var patrol_index := 0
var facing := "down"
var enabled := true
var defeated := false
var health := MAX_HEALTH
var stun_time := 0.0
var attack_cooldown := 0.0
var action_state := ""
var action_timer := 0.0
var pending_damage := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	var atlas: Texture2D = TLACUA_ATLAS if kind == "tlacua" else CUACHE_ATLAS
	var actions: Texture2D = TLACUA_ACTIONS if kind == "tlacua" else CUACHE_ACTIONS
	var bounds := [0, 458, 886, 1317, 1774] if kind == "tlacua" else [0, 428, 890, 1351, 1774]
	var row_split := 448 if kind == "tlacua" else 450
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for index in range(4):
		var direction: String = DIRECTIONS[index]
		var width: int = bounds[index + 1] - bounds[index]
		var idle := _region(atlas, Rect2(bounds[index], 0, width, row_split))
		var step := _region(atlas, Rect2(bounds[index], row_split, width, 887 - row_split))
		frames.add_animation("idle_" + direction)
		frames.add_frame("idle_" + direction, idle)
		frames.add_animation("walk_" + direction)
		frames.set_animation_speed("walk_" + direction, 8.0)
		frames.add_frame("walk_" + direction, idle)
		frames.add_frame("walk_" + direction, step)
	frames.add_animation("attack")
	frames.set_animation_speed("attack", 8.0)
	frames.set_animation_loop("attack", false)
	for pose in [3, 4, 3, 4]:
		frames.add_frame("attack", _action_region(actions, pose))
	frames.add_animation("hurt")
	frames.set_animation_speed("hurt", 7.0)
	frames.set_animation_loop("hurt", false)
	frames.add_frame("hurt", _action_region(actions, 7))
	frames.add_frame("hurt", _action_region(actions, 8))
	frames.add_animation("stunned")
	frames.add_frame("stunned", _action_region(actions, 8))
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * _base_scale()
	sprite.play("idle_down")
	$Nombre.text = "TLACUA" if kind == "tlacua" else "CUACHE"
	$VidaBarra.max_value = MAX_HEALTH
	$VidaBarra.value = health
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.86, 0.32, 0.24) if kind == "tlacua" else Color(0.96, 0.66, 0.23)
	fill.set_corner_radius_all(3)
	$VidaBarra.add_theme_stylebox_override("fill", fill)


func _process(delta: float) -> void:
	if not enabled and not defeated:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if action_state != "":
		action_timer = maxf(0.0, action_timer - delta)
		if action_state == "attack" and pending_damage and action_timer <= 0.28:
			pending_damage = false
			if is_instance_valid(target) and global_position.distance_to(target.global_position) < 90.0:
				target.take_damage(18 if kind == "tlacua" else 13, global_position)
		if action_timer <= 0.0:
			var was_hurt := action_state == "hurt"
			action_state = ""
			if was_hurt and (stun_time > 0.0 or defeated):
				sprite.play("stunned")
	_update_pose()


func _physics_process(delta: float) -> void:
	if not enabled or defeated:
		velocity = Vector2.ZERO
		return
	if stun_time > 0.0:
		stun_time = maxf(0.0, stun_time - delta)
		velocity = Vector2.ZERO
		if stun_time <= 0.0 and action_state == "":
			sprite.play("idle_" + facing)
		return
	if action_state != "":
		velocity = Vector2.ZERO
		return
	if target != null and global_position.distance_to(target.global_position) < 83.0 and attack_cooldown <= 0.0:
		_start_attack()
		return
	var destination := global_position
	var chasing := target != null and global_position.distance_to(target.global_position) < 490.0 and _can_see_target()
	if chasing:
		destination = target.global_position
	elif not patrol_points.is_empty():
		destination = patrol_points[patrol_index]
		if global_position.distance_to(destination) < 25.0:
			patrol_index = (patrol_index + 1) % patrol_points.size()
			destination = patrol_points[patrol_index]
	var direction := global_position.direction_to(destination) if global_position.distance_to(destination) > 8.0 else Vector2.ZERO
	velocity = direction * (220.0 if chasing else 145.0)
	move_and_slide()
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = "right" if direction.x > 0 else "left"
		else:
			facing = "down" if direction.y > 0 else "up"
	var animation := ("walk_" if direction != Vector2.ZERO else "idle_") + facing
	if sprite.animation != animation:
		sprite.play(animation)


func take_hit() -> void:
	if defeated:
		return
	health = maxi(0, health - CAN_DAMAGE)
	$VidaBarra.value = health
	stun_time = 2.0
	action_state = "hurt"
	action_timer = 0.55
	pending_damage = false
	velocity = Vector2.ZERO
	sprite.flip_h = facing == "left"
	sprite.play("hurt")
	if health <= 0:
		defeated = true


func _start_attack() -> void:
	action_state = "attack"
	action_timer = 0.5
	attack_cooldown = 1.35 if kind == "tlacua" else 1.6
	pending_damage = true
	velocity = Vector2.ZERO
	sprite.flip_h = facing == "left"
	sprite.play("attack")


func _can_see_target() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 2)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _base_scale() -> float:
	return 0.4 if kind == "tlacua" else 0.38


func _update_pose() -> void:
	var step := sprite.frame
	var base := _base_scale()
	if action_state == "attack":
		sprite.position = Vector2(8 if facing == "right" else (-8 if facing == "left" else 0), -8 if step in [1, 2] else 0)
		sprite.rotation = (-0.12 if step in [0, 1] else 0.14) * (-1 if facing == "left" else 1)
		sprite.scale = Vector2(base * 1.12, base * 0.95) if step in [1, 2] else Vector2.ONE * base
	elif action_state == "hurt" or sprite.animation == "stunned":
		sprite.position = Vector2(-5 if step == 0 else 5, 4)
		sprite.rotation = -0.17 if step == 0 else 0.17
		sprite.scale = Vector2(base * 1.08, base * 0.92)
	elif sprite.animation.begins_with("walk"):
		sprite.flip_h = false
		sprite.position = Vector2(0, -5 if step == 0 else 4)
		sprite.rotation = -0.065 if step == 0 else 0.065
		sprite.scale = Vector2(base * 1.06, base * 0.95) if step == 0 else Vector2(base * 0.95, base * 1.06)
	else:
		sprite.flip_h = false
		sprite.position = Vector2.ZERO
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE * base
	sprite.modulate = Color(1.0, 0.65, 0.65, 1.0) if action_state == "hurt" else Color.WHITE


func _region(atlas: Texture2D, rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = rect
	return texture


func _action_region(atlas: Texture2D, index: int) -> AtlasTexture:
	return _region(atlas, Rect2((index % 3) * 512, (index / 3) * 341, 512, 341))
