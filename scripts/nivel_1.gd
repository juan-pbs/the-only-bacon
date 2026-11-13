extends Node2D

const LEVEL_TIME := 120.0
const TILE_SIZE := 102.0
const FLOOR_ATLAS := preload("res://assets/sprites/pisos-niveles.png")
const PROP_ATLAS := preload("res://assets/sprites/objetos-escenario.png")
const TLACUA_SCENE := preload("res://tlacua.tscn")
const CUACHE_SCENE := preload("res://cuache_enemigo.tscn")
const TILE_EDGES := [0, 105, 209, 314, 418, 523, 627]
const CRATE := Rect2(45, 80, 350, 370)
const EGGS := Rect2(480, 65, 355, 390)
const FIRE := Rect2(1315, 65, 445, 420)
const TABLE := Rect2(460, 510, 435, 355)
const DOOR := Rect2(915, 500, 400, 365)
const FENCE := Rect2(1320, 520, 435, 350)

var remaining := LEVEL_TIME
var finished := false
var won := false
var paused := false
var fire_glow: Polygon2D
var enemies: Array[CharacterBody2D] = []

@onready var player: CharacterBody2D = $Tocino
@onready var timer_label: Label = $HUD/Barra/Fila/Tiempo
@onready var health_bar: ProgressBar = $HUD/Barra/Fila/VidaBarra
@onready var pause_panel: ColorRect = $HUD/PausaPanel
@onready var result: ColorRect = $HUD/Resultado
@onready var message: Label = $HUD/Resultado/Caja/Mensaje


func _ready() -> void:
	_build_floor()
	_build_boundaries()
	_build_props()
	_build_enemies()
	player.health_changed.connect(_update_health)
	player.defeated.connect(func() -> void: _finish("¡Te atraparon!"))
	$Salida.body_entered.connect(_on_exit_entered)
	$HUD/Barra/Fila/Pausa.pressed.connect(_toggle_pause)
	$HUD/PausaPanel/Caja/Reanudar.pressed.connect(_toggle_pause)
	$HUD/PausaPanel/Caja/Reiniciar.pressed.connect(_restart)
	$HUD/PausaPanel/Caja/Volver.pressed.connect(_go_to_menu)
	$HUD/Resultado/Caja/Reintentar.pressed.connect(_restart)
	$HUD/Resultado/Caja/Volver.pressed.connect(_go_to_menu)
	$Tocino/Camera2D.make_current()
	$Tocino/Camera2D.reset_smoothing()
	_update_health(player.health)


func _process(delta: float) -> void:
	if fire_glow != null:
		fire_glow.modulate.a = 0.75 + 0.2 * sin(Time.get_ticks_msec() * 0.006)
	if paused or finished:
		return
	remaining = maxf(0.0, remaining - delta)
	timer_label.text = "Tiempo: %d" % ceili(remaining)
	if remaining <= 0.0:
		_finish("Se acabó el tiempo")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _build_floor() -> void:
	for row in range(21):
		for column in range(15):
			var source_column: int = (column + row * 2) % 6
			var source_row: int = (row + column * 3) % 6
			var source_y := 627 if abs(column - 7) <= 2 and abs(row - 10) <= 2 else 0
			var region := Rect2(
				TILE_EDGES[source_column], source_y + TILE_EDGES[source_row],
				TILE_EDGES[source_column + 1] - TILE_EDGES[source_column],
				TILE_EDGES[source_row + 1] - TILE_EDGES[source_row]
			)
			var tile := Sprite2D.new()
			tile.name = "Piso_%02d_%02d" % [column, row]
			tile.texture = _atlas_region(FLOOR_ATLAS, region)
			tile.position = Vector2((column + 0.5) * TILE_SIZE, (row + 0.5) * TILE_SIZE)
			tile.scale = Vector2(TILE_SIZE / region.size.x, TILE_SIZE / region.size.y)
			$Pisos.add_child(tile)


func _build_boundaries() -> void:
	_add_wall("Límite izquierdo", Rect2(0, 0, 140, 2130))
	_add_wall("Límite derecho", Rect2(1390, 0, 140, 2130))
	_add_wall("Límite inferior", Rect2(0, 2000, 1530, 130))
	_add_wall("Límite superior izquierdo", Rect2(0, 0, 655, 135))
	_add_wall("Límite superior derecho", Rect2(875, 0, 655, 135))
	for x in [115, 325, 535, 995, 1205, 1415]:
		_add_decoration(FENCE, Vector2(x, 45), 0.55)
	for x in [115, 325, 535, 745, 955, 1165, 1415]:
		_add_decoration(FENCE, Vector2(x, 2090), 0.55)
	for y in [255, 465, 675, 885, 1095, 1305, 1515, 1725, 1935]:
		_add_decoration(FENCE, Vector2(40, y), 0.55, PI / 2.0)
		_add_decoration(FENCE, Vector2(1490, y), 0.55, PI / 2.0)


func _build_props() -> void:
	_add_decoration(DOOR, Vector2(765, 145), 0.62)
	_add_prop("Caja noroeste", CRATE, Vector2(300, 480), 0.5, Vector2(160, 175))
	_add_prop("Caja noreste", CRATE, Vector2(1190, 475), 0.5, Vector2(160, 175))
	_add_prop("Huevos noroeste", EGGS, Vector2(535, 680), 0.46, Vector2(150, 175))
	_add_prop("Huevos noreste", EGGS, Vector2(1025, 690), 0.46, Vector2(150, 175))
	_add_prop("Caja oeste", CRATE, Vector2(260, 865), 0.5, Vector2(160, 175))
	_add_prop("Caja este", CRATE, Vector2(1280, 840), 0.5, Vector2(160, 175))
	_add_prop("Mesa oeste", TABLE, Vector2(290, 1110), 0.68, Vector2(265, 205))
	_add_prop("Mesa este", TABLE, Vector2(1235, 1100), 0.68, Vector2(265, 205))
	_add_prop("Caja suroeste", CRATE, Vector2(325, 1325), 0.5, Vector2(160, 175))
	_add_prop("Caja sureste", CRATE, Vector2(1260, 1360), 0.5, Vector2(160, 175))
	_add_prop("Mesa inferior", TABLE, Vector2(315, 1570), 0.68, Vector2(265, 205))
	_add_prop("Huevos inferiores izquierdos", EGGS, Vector2(570, 1530), 0.46, Vector2(150, 175))
	_add_prop("Huevos inferiores derechos", EGGS, Vector2(980, 1520), 0.46, Vector2(150, 175))
	_add_prop("Caja inferior izquierda", CRATE, Vector2(380, 1840), 0.5, Vector2(160, 175))
	_add_prop("Caja inferior derecha", CRATE, Vector2(1135, 1830), 0.5, Vector2(160, 175))
	fire_glow = Polygon2D.new()
	fire_glow.name = "Resplandor fogata"
	fire_glow.position = Vector2(765, 1050)
	fire_glow.color = Color(1.0, 0.38, 0.05, 0.22)
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * index / 32.0
		points.append(Vector2(cos(angle) * 215.0, sin(angle) * 205.0))
	fire_glow.polygon = points
	$Escenario.add_child(fire_glow)
	_add_prop("Fogata", FIRE, Vector2(765, 1050), 0.78, Vector2(310, 300))


func _build_enemies() -> void:
	_add_enemy(TLACUA_SCENE, Vector2(1080, 890), [Vector2(1080, 890), Vector2(980, 875)])
	_add_enemy(CUACHE_SCENE, Vector2(760, 1530), [Vector2(760, 1530), Vector2(840, 1360)])


func _add_enemy(scene: PackedScene, at: Vector2, route: Array[Vector2]) -> void:
	var enemy: CharacterBody2D = scene.instantiate()
	enemy.position = at
	enemy.patrol_points = route
	enemy.target = player
	add_child(enemy)
	enemies.append(enemy)


func _add_prop(label: String, region: Rect2, at: Vector2, size_scale: float, collision_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = label
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = at
	var sprite := Sprite2D.new()
	sprite.texture = _atlas_region(PROP_ATLAS, region)
	sprite.scale = Vector2.ONE * size_scale
	body.add_child(sprite)
	if region == TABLE:
		_add_box_shape(body, Vector2(240, 90), Vector2(0, -38))
		_add_box_shape(body, Vector2(24, 105), Vector2(-112, 45))
		_add_box_shape(body, Vector2(24, 105), Vector2(112, 45))
	elif region == CRATE:
		_add_box_shape(body, Vector2(145, 150), Vector2(0, -6))
	elif region == EGGS:
		_add_box_shape(body, Vector2(145, 155), Vector2(0, -6))
	else:
		_add_box_shape(body, collision_size, Vector2.ZERO)
	$Escenario.add_child(body)


func _add_box_shape(body: StaticBody2D, size: Vector2, offset: Vector2) -> void:
	var shape := CollisionShape2D.new()
	shape.position = offset
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)


func _add_decoration(region: Rect2, at: Vector2, size_scale: float, angle: float = 0.0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _atlas_region(PROP_ATLAS, region)
	sprite.position = at
	sprite.scale = Vector2.ONE * size_scale
	sprite.rotation = angle
	$Escenario.add_child(sprite)


func _add_wall(label: String, bounds: Rect2) -> void:
	var wall := StaticBody2D.new()
	wall.name = label
	wall.collision_layer = 2
	wall.collision_mask = 0
	wall.position = bounds.get_center()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = bounds.size
	shape.shape = rectangle
	wall.add_child(shape)
	$Limites.add_child(wall)


func _atlas_region(atlas: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = region
	return texture


func _on_exit_entered(body: Node2D) -> void:
	if body == player and not finished:
		won = true
		_finish("¡Tocino llegó a la salida!")


func _update_health(value: int) -> void:
	health_bar.value = value


func _toggle_pause() -> void:
	if finished:
		return
	paused = not paused
	player.controls_enabled = not paused
	player.set_process(not paused)
	for enemy in enemies:
		enemy.enabled = not paused
	for can in get_tree().get_nodes_in_group("projectiles"):
		can.set_physics_process(not paused)
	pause_panel.visible = paused
	if paused:
		$HUD/PausaPanel/Caja/Reanudar.grab_focus()
	else:
		$HUD/Barra/Fila/Pausa.grab_focus()


func _finish(text: String) -> void:
	if finished:
		return
	finished = true
	player.controls_enabled = false
	for enemy in enemies:
		enemy.enabled = false
	message.text = text
	$HUD/Resultado/Caja/Reintentar.text = "Siguiente nivel" if won else "Reintentar"
	result.show()
	$HUD/Resultado/Caja/Reintentar.grab_focus()


func _restart() -> void:
	if won:
		get_tree().change_scene_to_file("res://nivel_2.tscn")
	else:
		get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
