extends Area2D

const ATLAS := preload("res://assets/sprites/objetos-escenario.png")
var lifetime := 3.0


func _ready() -> void:
	add_to_group("timed_world")
	collision_layer = 0
	collision_mask = 1
	z_index = -1
	var sprite := Sprite2D.new()
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = Rect2(875, 90, 435, 365)
	sprite.texture = texture
	sprite.scale = Vector2.ONE * 0.48
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 82.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	tree_exiting.connect(_on_tree_exiting)


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_oil"):
		body.enter_oil()


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_oil"):
		body.exit_oil()


func _on_tree_exiting() -> void:
	for body in get_overlapping_bodies():
		_on_body_exited(body)
