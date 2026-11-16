extends Area2D

const CAN_STRIP := preload("res://assets/sprites/tocino_animado/tiras/can_spin.png")
const PAN_TEXTURE := preload("res://assets/sprites/recogibles/cacerola.png")
const BUTTER_TEXTURE := preload("res://assets/sprites/recogibles/mantequilla.png")
const CLOCK_TEXTURE := preload("res://assets/sprites/recogibles/reloj.png")
const NAMES := {"can": "LATA", "pan": "CACEROLA", "butter": "+25 VIDA", "clock": "+10 s"}

@export_enum("can", "pan", "butter", "clock") var kind := "can"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	shape.shape = circle
	add_child(shape)
	var sprite := Sprite2D.new()
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
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_item") and body.collect_item(kind):
		queue_free()
