extends Area2D

const CAN_STRIP := preload("res://assets/sprites/tocino_animado/tiras/can_spin.png")
const PAN_TEXTURE := preload("res://assets/sprites/recogibles/cacerola.png")
const BUTTER_TEXTURE := preload("res://assets/sprites/recogibles/mantequilla.png")
const CLOCK_TEXTURE := preload("res://assets/sprites/recogibles/reloj.png")
const NAMES := {"can": "LATA", "pan": "CACEROLA", "butter": "+25 VIDA", "clock": "+10 s"}

@export_enum("can", "pan", "butter", "clock") var kind := "can"
@export_range(0.1, 60.0, 0.1) var respawn_seconds := 5.0
@export_range(0.0, 24.0, 0.5) var float_height := 8.0
@export_range(0.1, 10.0, 0.1) var float_speed := 3.0

var collected := false
var respawn_remaining := 0.0
var animation_time := 0.0
var sprite: Sprite2D
var sprite_origin := Vector2.ZERO
var sprite_scale := Vector2.ONE


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	if get_child_count() > 0:
		_setup_animation()
		body_entered.connect(_on_body_entered)
		return
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	shape.shape = circle
	add_child(shape)
	sprite = Sprite2D.new()
	match kind:
		"can":
			var texture := AtlasTexture.new()
			texture.atlas = CAN_STRIP
			texture.region = Rect2(0, 0, 160, 160)
			sprite.texture = texture
			sprite.scale = Vector2.ONE * 0.42
		"pan":
			sprite.texture = PAN_TEXTURE
			sprite.scale = Vector2.ONE * 0.07
		"butter":
			sprite.texture = BUTTER_TEXTURE
			sprite.scale = Vector2.ONE * 0.10
		"clock":
			sprite.texture = CLOCK_TEXTURE
			sprite.scale = Vector2.ONE * 0.075
	add_child(sprite)
	var label := Label.new()
	label.text = NAMES[kind]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var label_style := LabelSettings.new()
	label_style.font_size = 15
	label_style.font_color = Color.WHITE
	label_style.outline_color = Color(0.08, 0.06, 0.04)
	label_style.outline_size = 3
	label.label_settings = label_style
	label.position = Vector2(-55, -58)
	label.size = Vector2(110, 22)
	add_child(label)
	_setup_animation()
	body_entered.connect(_on_body_entered)


func _setup_animation() -> void:
	if sprite == null:
		for child in get_children():
			if child is Sprite2D:
				sprite = child
				break
	if sprite != null:
		sprite_origin = sprite.position
		sprite_scale = sprite.scale
	animation_time = position.x * 0.013 + position.y * 0.007


func _process(delta: float) -> void:
	var level := get_parent().get_parent()
	if level.get("paused") or level.get("finished"):
		return
	if collected:
		respawn_remaining -= delta
		if respawn_remaining <= 0.0:
			collected = false
			show()
			set_deferred("monitoring", true)
		return
	animation_time += delta * float_speed
	if sprite != null:
		sprite.position = sprite_origin + Vector2(0, -float_height * (0.5 + 0.5 * sin(animation_time)))
		sprite.scale = sprite_scale * (1.0 + 0.06 * sin(animation_time * 1.4))


func _on_body_entered(body: Node2D) -> void:
	if not collected and body.has_method("collect_item") and body.collect_item(kind):
		collected = true
		respawn_remaining = respawn_seconds
		hide()
		set_deferred("monitoring", false)
