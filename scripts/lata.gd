extends Area2D

const CAN_STRIP := preload("res://assets/sprites/tocino_animado/tiras/can_spin.png")
const PAN_TEXTURE := preload("res://assets/sprites/recogibles/cacerola.png")
const SPEED := 650.0

var direction := Vector2.UP
var lifetime := 0.9
var damage := 100
var stun_duration := 2.0
var item_kind := "can"


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
	if item_kind == "pan":
		$AnimatedSprite2D.visible = false
		var pan_sprite := Sprite2D.new()
		pan_sprite.texture = PAN_TEXTURE
		pan_sprite.scale = Vector2.ONE * 0.06
		add_child(pan_sprite)
	$AnimatedSprite2D.play("spin")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction.normalized() * SPEED * delta
	if item_kind == "pan":
		rotation += delta * 12.0
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit(damage, stun_duration)
	queue_free()
