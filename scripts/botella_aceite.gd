extends Node2D

const BOTTLE_TEXTURE := preload("res://assets/sprites/recogibles/botella-aceite.png")
var destination := Vector2.ZERO
var origin := Vector2.ZERO
var flight := 0.0
var duration := 0.65
var sprite: Sprite2D


func _ready() -> void:
	add_to_group("timed_world")
	origin = global_position
	z_index = 25
	sprite = Sprite2D.new()
	sprite.texture = BOTTLE_TEXTURE
	sprite.scale = Vector2.ONE * 0.09
	add_child(sprite)


func _process(delta: float) -> void:
	flight = minf(duration, flight + delta)
	var progress := flight / duration
	global_position = origin.lerp(destination, progress)
	sprite.position = Vector2(0, -sin(PI * progress) * 32.0)
	sprite.rotation = progress * TAU
	if flight >= duration:
		if get_parent().has_method("spawn_oil"):
			get_parent().spawn_oil(global_position, 3.0)
		queue_free()
