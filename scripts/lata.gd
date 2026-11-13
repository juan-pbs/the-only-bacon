extends Area2D

const CAN_STRIP := preload("res://assets/sprites/tocino_animado/tiras/can_spin.png")
const SPEED := 650.0

var direction := Vector2.UP
var lifetime := 0.9


func _ready() -> void:
	add_to_group("projectiles")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 12.0)
	for index in range(4):
		var texture := AtlasTexture.new()
		texture.atlas = CAN_STRIP
		texture.region = Rect2(index * 160, 0, 160, 160)
		frames.add_frame("spin", texture)
	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("spin")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction.normalized() * SPEED * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()
	queue_free()
