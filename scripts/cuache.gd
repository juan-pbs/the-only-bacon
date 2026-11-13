extends CharacterBody2D

const WALK_SPEED := 245.0
const RUN_SPEED := 375.0
const ATLAS := preload("res://assets/sprites/acciones/cuache-direcciones.png")
const X_BOUNDS := [0, 428, 890, 1351, 1774]
const DIRECTIONS := ["down", "left", "right", "up"]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var facing := "down"


func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for index in range(4):
		var direction: String = DIRECTIONS[index]
		var width: int = X_BOUNDS[index + 1] - X_BOUNDS[index]
		var idle := _atlas_region(Rect2(X_BOUNDS[index], 0, width, 450))
		var step := _atlas_region(Rect2(X_BOUNDS[index], 450, width, 437))
		frames.add_animation("idle_" + direction)
		frames.add_frame("idle_" + direction, idle)
		frames.add_animation("walk_" + direction)
		frames.set_animation_speed("walk_" + direction, 8.0)
		frames.add_frame("walk_" + direction, idle)
		frames.add_frame("walk_" + direction, step)
	sprite.sprite_frames = frames
	sprite.play("idle_down")


func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * (RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED)
	move_and_slide()
	if input_direction != Vector2.ZERO:
		if absf(input_direction.x) > absf(input_direction.y):
			facing = "right" if input_direction.x > 0 else "left"
		else:
			facing = "down" if input_direction.y > 0 else "up"
		var animation := "walk_" + facing
		if sprite.animation != animation:
			sprite.play(animation)
		sprite.speed_scale = 1.5 if Input.is_action_pressed("run") else 1.0
	else:
		var animation := "idle_" + facing
		if sprite.animation != animation:
			sprite.play(animation)


func _atlas_region(rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = rect
	return texture
