extends Control


func _ready() -> void:
	$Centro/JugarOtraVez.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://nivel_1.tscn"))
	$Centro/Menu.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://menu.tscn"))
	$Centro/Menu.grab_focus()
