extends Area2D

func _ready() -> void:
	add_to_group("hide_zones")
	body_entered.connect(_entered)
	body_exited.connect(_exited)

func _entered(body: Node2D) -> void:
	if body.has_method("enter_hide_zone"):
		body.enter_hide_zone()

func _exited(body: Node2D) -> void:
	if body.has_method("exit_hide_zone"):
		body.exit_hide_zone()
