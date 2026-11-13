extends Control


func _ready() -> void:
	$Centro/Nivel1.pressed.connect(_play_level_1)
	$Centro/Nivel2.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://nivel_2.tscn"))
	$Centro/Nivel3.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://nivel_3.tscn"))
	$Centro/Salir.pressed.connect(_quit)
	$Centro/Nivel1.grab_focus()


func _play_level_1() -> void:
	get_tree().change_scene_to_file("res://nivel_1.tscn")


func _quit() -> void:
	get_tree().quit()
