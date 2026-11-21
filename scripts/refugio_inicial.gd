extends Area2D

func _ready() -> void:
	body_exited.connect(_exited)
	var player := get_node("../../Tocino")
	player.spawn_sheltered = true
	player.is_hidden = true

func _exited(body: Node2D) -> void:
	if body == get_node("../../Tocino"):
		body.spawn_sheltered = false
		body.is_hidden = false
