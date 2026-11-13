extends Control


func _ready() -> void:
	$Centro/Nivel1.pressed.connect(_play_level_1)
	$Centro/Nivel2.pressed.connect(func() -> void: _show_unavailable(2))
	$Centro/Nivel3.pressed.connect(func() -> void: _show_unavailable(3))
	$Centro/Salir.pressed.connect(_quit)
	$Centro/Nivel1.grab_focus()


func _play_level_1() -> void:
	get_tree().change_scene_to_file("res://nivel_1.tscn")


func _show_unavailable(number: int) -> void:
	$Aviso.dialog_text = "El nivel %d todavía está en desarrollo." % number
	$Aviso.popup_centered()


func _quit() -> void:
	get_tree().quit()
