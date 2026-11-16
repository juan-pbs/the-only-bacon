extends Node2D

const PICKUP_SCRIPT := preload("res://scripts/recogible.gd")
const OIL_SCRIPT := preload("res://scripts/charco_aceite.gd")
const SHELTER_ATLAS := preload("res://assets/sprites/objetos-escenario.png")
const SHELTER_CRATE := Rect2(45, 80, 350, 370)
const SHELTER_FENCE := Rect2(1320, 520, 435, 350)

var remaining := 120.0
var finished := false
var won := false
var paused := false
var intro_visible := false
var enemies: Array[CharacterBody2D] = []
var notice_timer := 0.0

@onready var player: CharacterBody2D = $Tocino
@onready var timer_label: Label = $HUD/Barra/Fila/Tiempo
@onready var health_bar: ProgressBar = $HUD/Barra/Fila/VidaBarra
@onready var pause_panel: ColorRect = $HUD/PausaPanel
@onready var result: ColorRect = $HUD/Resultado

var inventory_label: Label
var notice_label: Label
var intro_panel: ColorRect


func _ready() -> void:
	player.health_changed.connect(_update_health)
	player.inventory_changed.connect(_update_inventory)
	player.time_bonus_requested.connect(_add_time)
	player.item_notice.connect(_show_notice)
	player.defeated.connect(func() -> void: _finish(false, "¡Te atraparon!"))
	$Salida.body_entered.connect(_on_exit_entered)
	$HUD/Barra/Fila/Pausa.pressed.connect(_toggle_pause)
	$HUD/PausaPanel/Caja/Reanudar.pressed.connect(_toggle_pause)
	$HUD/PausaPanel/Caja/Reiniciar.pressed.connect(_restart)
	$HUD/PausaPanel/Caja/Volver.pressed.connect(_go_to_menu)
	$HUD/Resultado/Caja/Volver.pressed.connect(_go_to_menu)
	_result_button().pressed.connect(_result_action)
	$Tocino/Camera2D.make_current()
	$Tocino/Camera2D.reset_smoothing()
	_create_hud_additions()
	_update_health(player.health)
	_update_inventory()
	_update_timer()
	if _level_number() == 1:
		_show_tutorial()
	elif _level_number() == 2:
		_show_notice("Cuache: ¡Ahora sí estamos los dos!")
	else:
		_show_notice("Tlacua: Esta vez no se nos escapa.")


func _process(delta: float) -> void:
	if paused or intro_visible or finished:
		return
	if notice_timer > 0.0:
		notice_timer -= delta
		if notice_timer <= 0.0:
			notice_label.text = ""
	remaining = maxf(0.0, remaining - delta)
	_update_timer()
	if remaining <= 0.0:
		_finish(false, "Se acabó el tiempo")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if intro_visible:
			_close_tutorial()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()


func _level_number() -> int:
	return 1


func _create_hud_additions() -> void:
	var info_background := ColorRect.new()
	info_background.position = Vector2(10, 74)
	info_background.size = Vector2(520, 65)
	info_background.color = Color(0.05, 0.04, 0.05, 0.7)
	info_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(info_background)
	inventory_label = Label.new()
	inventory_label.position = Vector2(18, 78)
	inventory_label.add_theme_font_size_override("font_size", 19)
	inventory_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72))
	$HUD.add_child(inventory_label)
	notice_label = Label.new()
	notice_label.position = Vector2(18, 108)
	notice_label.add_theme_font_size_override("font_size", 18)
	notice_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	$HUD.add_child(notice_label)
	var objective := Label.new()
	objective.position = Vector2(18, 676)
	objective.text = "Encuentra el hueco y escapa antes de que termine el tiempo"
	objective.add_theme_font_size_override("font_size", 18)
	objective.add_theme_color_override("font_color", Color.WHITE)
	$HUD.add_child(objective)
	$HUD.move_child(info_background, 1)
	$HUD.move_child(inventory_label, 2)
	$HUD.move_child(notice_label, 3)
	$HUD.move_child(objective, 4)


func _update_inventory() -> void:
	var selected := "Lata" if player.selected_weapon == "can" else "Cacerola"
	inventory_label.text = "Latas: %d   Cacerolas: %d   Elegido: %s (Q)" % [player.cans, player.pans, selected]


func _update_health(value: int) -> void:
	health_bar.value = value


func _update_timer() -> void:
	timer_label.text = "Tiempo: %d" % ceili(remaining)


func _add_time(seconds: float) -> void:
	remaining += seconds
	_update_timer()


func _show_notice(message: String) -> void:
	notice_label.text = message
	notice_timer = 2.5


func spawn_pickup(kind: String, at: Vector2) -> void:
	var item: Area2D = PICKUP_SCRIPT.new()
	item.kind = kind
	item.position = at
	$Escenario.add_child(item)


func spawn_oil(at: Vector2, duration: float = 3.0) -> void:
	var pool: Area2D = OIL_SCRIPT.new()
	pool.position = at
	pool.lifetime = duration
	$Escenario.add_child(pool)


func spawn_hide_zone(at: Vector2, radius: float = 95.0) -> void:
	var zone := Area2D.new()
	zone.name = "Escondite"
	zone.add_to_group("hide_zones")
	zone.position = at
	zone.collision_layer = 0
	zone.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	zone.add_child(shape)
	zone.body_entered.connect(func(body: Node2D) -> void:
		if body == player: player.enter_hide_zone()
	)
	zone.body_exited.connect(func(body: Node2D) -> void:
		if body == player: player.exit_hide_zone()
	)
	$Escenario.add_child(zone)


func spawn_start_shelter() -> void:
	var shelter := Area2D.new()
	shelter.name = "RefugioInicial"
	shelter.position = player.position
	shelter.collision_layer = 0
	shelter.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 145.0
	shape.shape = circle
	shelter.add_child(shape)
	var fence := Sprite2D.new()
	fence.texture = _shelter_region(SHELTER_FENCE)
	fence.scale = Vector2(0.48, 0.25)
	fence.position = Vector2(0, 75)
	shelter.add_child(fence)
	for side in [-1, 1]:
		var crate := Sprite2D.new()
		crate.texture = _shelter_region(SHELTER_CRATE)
		crate.scale = Vector2.ONE * 0.30
		crate.position = Vector2(side * 100, 23)
		crate.z_index = 2
		shelter.add_child(crate)
	var label := Label.new()
	label.text = "REFUGIO"
	label.position = Vector2(-66, -101)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.62))
	label.add_theme_color_override("font_outline_color", Color(0.15, 0.09, 0.04))
	label.add_theme_constant_override("outline_size", 4)
	shelter.add_child(label)
	shelter.body_exited.connect(func(body: Node2D) -> void:
		if body == player:
			player.spawn_sheltered = false
			player.is_hidden = false
	)
	$Escenario.add_child(shelter)
	player.spawn_sheltered = true
	player.is_hidden = true


func _shelter_region(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = SHELTER_ATLAS
	texture.region = region
	return texture


func _set_action_enabled(value: bool) -> void:
	player.controls_enabled = value
	player.set_process(value)
	for enemy in enemies:
		enemy.enabled = value
		enemy.set_process(value)
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		projectile.set_physics_process(value)
	for pool in get_tree().get_nodes_in_group("timed_world"):
		pool.set_process(value)


func _toggle_pause() -> void:
	if finished or intro_visible:
		return
	paused = not paused
	_set_action_enabled(not paused)
	pause_panel.visible = paused
	if paused:
		$HUD/PausaPanel/Caja/Reanudar.grab_focus()
	else:
		$HUD/Barra/Fila/Pausa.grab_focus()


func _on_exit_entered(body: Node2D) -> void:
	if body == player and not finished and player.health > 0:
		var message := "¡Tocino escapó!"
		if _level_number() == 2:
			message = "¡Saliste del Bodegón!"
		elif _level_number() == 3:
			message = "¡Escapaste de la Cocina!"
		_finish(true, message)


func _finish(success: bool, message: String) -> void:
	if finished:
		return
	finished = true
	won = success
	_set_action_enabled(false)
	$HUD/Resultado/Caja/Mensaje.text = message
	_result_button().text = "Siguiente nivel" if success and _level_number() < 3 else ("Ver final" if success else "Reintentar")
	result.show()
	_result_button().grab_focus()


func _result_button() -> Button:
	return $HUD/Resultado/Caja/Reintentar if _level_number() == 1 else $HUD/Resultado/Caja/Accion


func _result_action() -> void:
	if won:
		if _level_number() == 3:
			get_tree().change_scene_to_file("res://final.tscn")
		else:
			get_tree().change_scene_to_file("res://nivel_%d.tscn" % (_level_number() + 1))
	else:
		_restart()


func _restart() -> void:
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")


func _show_tutorial() -> void:
	intro_visible = true
	_set_action_enabled(false)
	intro_panel = ColorRect.new()
	intro_panel.color = Color(0.04, 0.04, 0.06, 0.92)
	intro_panel.size = Vector2(960, 720)
	$HUD.add_child(intro_panel)
	var box := VBoxContainer.new()
	box.position = Vector2(160, 130)
	box.size = Vector2(640, 470)
	box.add_theme_constant_override("separation", 20)
	intro_panel.add_child(box)
	var title := Label.new()
	title.text = "LA FOGATA · APRENDE A ESCAPAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var guide := Label.new()
	guide.text = "WASD o flechas: moverse · Shift: correr\nEspacio o J: lanzar objeto recogido · Q: cambiar objeto\nK: saltar obstáculos bajos y aceite · L: esquivar\nH: esconderse en zonas oscuras\nRecoge latas y cacerolas; mantequilla cura y reloj añade tiempo.\nEscapa por el hueco antes de perder toda la vida o el tiempo."
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size", 22)
	box.add_child(guide)
	var start := Button.new()
	start.text = "Empezar"
	start.custom_minimum_size = Vector2(0, 58)
	start.pressed.connect(_close_tutorial)
	box.add_child(start)
	start.grab_focus()


func _close_tutorial() -> void:
	intro_visible = false
	intro_panel.queue_free()
	_set_action_enabled(true)
	_show_notice("Tlacua: ¡Corre, corre! A ver cuánto aguantas.")
	$HUD/Barra/Fila/Pausa.grab_focus()
