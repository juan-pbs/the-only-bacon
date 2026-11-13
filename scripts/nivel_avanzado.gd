extends Node2D

const TILE_SIZE := 102.0
const FLOOR_ATLAS := preload("res://assets/sprites/pisos-niveles.png")
const PROP_ATLAS := preload("res://assets/sprites/objetos-escenario.png")
const TLACUA_SCENE := preload("res://tlacua.tscn")
const CUACHE_SCENE := preload("res://cuache_enemigo.tscn")
const TILE_EDGES := [0, 105, 209, 314, 418, 523, 627]
const REGIONS := {
	"crate": Rect2(45, 80, 350, 370),
	"eggs": Rect2(480, 65, 355, 390),
	"oil": Rect2(875, 90, 435, 365),
	"stove": Rect2(30, 500, 415, 360),
	"table": Rect2(460, 510, 435, 355),
	"door": Rect2(915, 500, 400, 365),
	"fence": Rect2(1320, 520, 435, 350)
}
const PROP_SCALES := {"crate": 0.5, "eggs": 0.47, "stove": 0.58, "table": 0.68}
const PROP_COLLISIONS := {
	"crate": Vector2(145, 150),
	"eggs": Vector2(145, 155),
	"stove": Vector2(205, 150),
	"table": Vector2(245, 190)
}

@export_range(2, 3) var level_number := 2

var remaining := 160.0
var finished := false
var paused := false
var won := false
var enemies: Array[CharacterBody2D] = []

@onready var player: CharacterBody2D = $Tocino
@onready var timer_label: Label = $HUD/Barra/Fila/Tiempo
@onready var health_bar: ProgressBar = $HUD/Barra/Fila/VidaBarra
@onready var pause_panel: ColorRect = $HUD/PausaPanel
@onready var result: ColorRect = $HUD/Resultado


func _ready() -> void:
	var columns := 24 if level_number == 2 else 30
	var rows := 32 if level_number == 2 else 40
	var width := columns * TILE_SIZE
	var height := rows * TILE_SIZE
	remaining = 190.0 if level_number == 2 else 210.0
	$HUD/Barra/Fila/Titulo.text = "NIVEL 2 · EL BODEGÓN DE HUEVOS" if level_number == 2 else "NIVEL 3 · LA COCINA DEL DESAYUNO"
	player.position = Vector2(width / 2.0, height - 260.0)
	$Salida.position = Vector2(width / 2.0, 235.0)
	$Tocino/Camera2D.limit_left = 0
	$Tocino/Camera2D.limit_top = 0
	$Tocino/Camera2D.limit_right = int(width)
	$Tocino/Camera2D.limit_bottom = int(height)
	_build_floor(columns, rows)
	_build_boundaries(width, height)
	_build_layout()
	_build_enemies()
	player.health_changed.connect(_update_health)
	player.defeated.connect(func() -> void: _finish(false, "¡Te atraparon!"))
	$Salida.body_entered.connect(_on_exit_entered)
	$HUD/Barra/Fila/Pausa.pressed.connect(_toggle_pause)
	$HUD/PausaPanel/Caja/Reanudar.pressed.connect(_toggle_pause)
	$HUD/PausaPanel/Caja/Reiniciar.pressed.connect(_restart)
	$HUD/PausaPanel/Caja/Volver.pressed.connect(_go_to_menu)
	$HUD/Resultado/Caja/Accion.pressed.connect(_result_action)
	$HUD/Resultado/Caja/Volver.pressed.connect(_go_to_menu)
	$Tocino/Camera2D.make_current()
	$Tocino/Camera2D.reset_smoothing()
	_update_health(player.health)
	timer_label.text = "Tiempo: %d" % int(remaining)


func _process(delta: float) -> void:
	if paused or finished:
		return
	remaining = maxf(0.0, remaining - delta)
	timer_label.text = "Tiempo: %d" % ceili(remaining)
	if remaining <= 0.0:
		_finish(false, "Se acabó el tiempo")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _build_floor(columns: int, rows: int) -> void:
	for row in range(rows):
		for column in range(columns):
			var atlas_column: int = (column + row * 2) % 6
			var atlas_row: int = (row + column * 3) % 6
			var source_x := 627 if level_number == 2 else 0
			var source_y := 0 if level_number == 2 else 627
			var region := Rect2(
				source_x + TILE_EDGES[atlas_column], source_y + TILE_EDGES[atlas_row],
				TILE_EDGES[atlas_column + 1] - TILE_EDGES[atlas_column],
				TILE_EDGES[atlas_row + 1] - TILE_EDGES[atlas_row]
			)
			var tile := Sprite2D.new()
			tile.texture = _atlas_region(FLOOR_ATLAS, region)
			tile.position = Vector2((column + 0.5) * TILE_SIZE, (row + 0.5) * TILE_SIZE)
			tile.scale = Vector2(TILE_SIZE / region.size.x, TILE_SIZE / region.size.y)
			$Pisos.add_child(tile)


func _build_boundaries(width: float, height: float) -> void:
	_add_wall("Pared izquierda", Rect2(0, 0, 130, height))
	_add_wall("Pared derecha", Rect2(width - 130, 0, 130, height))
	_add_wall("Pared inferior", Rect2(0, height - 145, width, 145))
	_add_wall("Pared superior izquierda", Rect2(0, 0, width / 2.0 - 135, 125))
	_add_wall("Pared superior derecha", Rect2(width / 2.0 + 135, 0, width / 2.0 - 135, 125))
	for x in range(110, int(width), 210):
		if absf(x - width / 2.0) > 150.0:
			_add_decoration("fence", Vector2(x, 45), 0.55)
		_add_decoration("fence", Vector2(x, height - 45), 0.55)
	for y in range(250, int(height - 80), 210):
		_add_decoration("fence", Vector2(42, y), 0.55, PI / 2.0)
		_add_decoration("fence", Vector2(width - 42, y), 0.55, PI / 2.0)
	_add_decoration("door", Vector2(width / 2.0, 145), 0.62)


func _build_layout() -> void:
	var props: Array = []
	var oil_positions: Array[Vector2] = []
	if level_number == 2:
		props = [
			["crate", 450, 2200], ["eggs", 780, 2200], ["crate", 1230, 2200], ["eggs", 1600, 2200],
			["table", 520, 1940], ["crate", 1020, 1940], ["table", 1520, 1940],
			["eggs", 400, 1690], ["crate", 760, 1680], ["table", 1460, 1690], ["crate", 1790, 1680],
			["crate", 620, 1430], ["crate", 1160, 1430], ["eggs", 1570, 1440],
			["table", 480, 1180], ["eggs", 1010, 1190], ["table", 1550, 1180],
			["eggs", 580, 920], ["crate", 1100, 920], ["eggs", 1620, 920],
			["crate", 400, 670], ["crate", 800, 660], ["crate", 1410, 660], ["crate", 1810, 670],
			["table", 500, 420], ["table", 1550, 420]
		]
		oil_positions = [Vector2(1010, 1770), Vector2(1370, 1040), Vector2(740, 510)]
	else:
		props = [
			["crate", 470, 2670], ["eggs", 860, 2670], ["eggs", 1600, 2670], ["crate", 1990, 2670],
			["table", 350, 2410], ["stove", 1060, 2410], ["table", 1790, 2410], ["crate", 2150, 2410],
			["crate", 650, 2160], ["eggs", 1320, 2160], ["crate", 1930, 2160],
			["stove", 390, 1900], ["table", 920, 1900], ["crate", 1520, 1900], ["stove", 2100, 1900],
			["eggs", 640, 1640], ["stove", 1210, 1640], ["eggs", 1790, 1640],
			["table", 370, 1390], ["crate", 850, 1390], ["table", 1470, 1390], ["crate", 2070, 1390],
			["stove", 650, 1140], ["eggs", 1230, 1140], ["table", 1870, 1140],
			["eggs", 350, 890], ["crate", 900, 890], ["stove", 1570, 890], ["eggs", 2100, 890],
			["table", 570, 640], ["crate", 1200, 640], ["table", 1850, 640],
			["crate", 420, 405], ["eggs", 860, 405], ["eggs", 1590, 405], ["crate", 2050, 405]
		]
		oil_positions = [Vector2(1390, 2750), Vector2(1450, 2280), Vector2(780, 2020), Vector2(1130, 1530), Vector2(1750, 1010)]
	var base_count := props.size()
	if level_number == 2:
		props.append_array([
			["eggs", 260, 2440], ["crate", 1010, 2260], ["crate", 1780, 2440],
			["crate", 240, 2080], ["eggs", 1780, 2080],
			["eggs", 270, 1820], ["crate", 1780, 1830],
			["crate", 280, 1550], ["eggs", 1780, 1550],
			["eggs", 290, 1290], ["crate", 1770, 1280],
			["crate", 270, 1050], ["eggs", 1780, 1040],
			["crate", 260, 790], ["eggs", 1780, 790],
			["eggs", 290, 530], ["crate", 1780, 530], ["crate", 1010, 380]
		])
	else:
		props.append_array([
			["crate", 300, 2780], ["crate", 1220, 2780], ["eggs", 2150, 2780],
			["eggs", 300, 2540], ["crate", 1250, 2540], ["eggs", 2140, 2540],
			["crate", 300, 2280], ["eggs", 1110, 2280], ["crate", 2190, 2280],
			["eggs", 300, 2030], ["stove", 1230, 2030], ["eggs", 2190, 2030],
			["crate", 300, 1770], ["table", 1200, 1770], ["crate", 2180, 1770],
			["eggs", 300, 1510], ["crate", 1200, 1510], ["eggs", 2170, 1510],
			["crate", 310, 1260], ["stove", 1180, 1260], ["crate", 2160, 1260],
			["eggs", 310, 1010], ["crate", 1200, 1010], ["eggs", 2160, 1010],
			["crate", 310, 760], ["table", 1210, 760], ["crate", 2160, 760],
			["eggs", 310, 515], ["crate", 1210, 515], ["eggs", 2160, 515]
		])
	var layout_scale := _layout_scale()
	var occupied: Array[Rect2] = []
	var reserved: Array[Rect2] = [
		Rect2(player.position - Vector2(125, 125), Vector2(250, 250)),
		Rect2($Salida.position - Vector2(150, 150), Vector2(300, 300))
	]
	var enemy_spawns := [Vector2(1300, 1360), Vector2(800, 2050)] if level_number == 2 else [Vector2(1130, 1800), Vector2(1570, 1050)]
	for spawn in enemy_spawns:
		reserved.append(Rect2(spawn * layout_scale - Vector2(85, 85), Vector2(170, 170)))
	var world_size := Vector2(2448, 3264) if level_number == 2 else Vector2(3060, 4080)
	for index in range(props.size()):
		var entry: Array = props[index]
		var position: Vector2 = Vector2(entry[1], entry[2]) * layout_scale
		var collision_size: Vector2 = PROP_COLLISIONS[entry[0]]
		if index >= base_count:
			position = _find_clear_position(position, collision_size, occupied, reserved, world_size)
			if position == Vector2.INF:
				continue
		_add_prop("Obstáculo_%02d" % index, entry[0], position)
		occupied.append(Rect2(position - collision_size / 2.0, collision_size).grow(16.0))
	for oil_position in oil_positions:
		var position := _find_clear_position(oil_position * layout_scale, Vector2(170, 170), occupied, reserved, world_size)
		if position != Vector2.INF:
			_add_oil(position)


func _find_clear_position(target: Vector2, size: Vector2, occupied: Array[Rect2], reserved: Array[Rect2], world_size: Vector2) -> Vector2:
	for ring in range(7):
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var candidate := target + Vector2(dx, dy) * 86.0
				var bounds := Rect2(candidate - size / 2.0, size).grow(16.0)
				if bounds.position.x < 150.0 or bounds.position.y < 165.0 or bounds.end.x > world_size.x - 150.0 or bounds.end.y > world_size.y - 185.0:
					continue
				var blocked := false
				for other in occupied:
					if bounds.intersects(other):
						blocked = true
						break
				if blocked:
					continue
				for other in reserved:
					if bounds.intersects(other):
						blocked = true
						break
				if not blocked:
					return candidate
	return Vector2.INF


func _build_enemies() -> void:
	var layout_scale := _layout_scale()
	if level_number == 2:
		_add_enemy("tlacua", Vector2(1300, 1360) * layout_scale, [Vector2(1300, 1360) * layout_scale, Vector2(1550, 1320) * layout_scale])
		_add_enemy("cuache", Vector2(800, 2050) * layout_scale, [Vector2(800, 2050) * layout_scale, Vector2(760, 1830) * layout_scale])
	else:
		_add_enemy("tlacua", Vector2(1130, 1800) * layout_scale, [Vector2(1130, 1800) * layout_scale, Vector2(1410, 1810) * layout_scale])
		_add_enemy("cuache", Vector2(1570, 1050) * layout_scale, [Vector2(1570, 1050) * layout_scale, Vector2(1780, 780) * layout_scale])


func _layout_scale() -> Vector2:
	return Vector2(1.2, 3264.0 / 2652.0) if level_number == 2 else Vector2(1.25, 4080.0 / 3060.0)


func _add_enemy(kind: String, at: Vector2, route: Array[Vector2]) -> void:
	var enemy: CharacterBody2D = (TLACUA_SCENE if kind == "tlacua" else CUACHE_SCENE).instantiate()
	enemy.position = at
	enemy.patrol_points = route
	enemy.target = player
	add_child(enemy)
	enemies.append(enemy)


func _add_prop(label: String, kind: String, at: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = label
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = at
	var sprite := Sprite2D.new()
	sprite.texture = _atlas_region(PROP_ATLAS, REGIONS[kind])
	sprite.scale = Vector2.ONE * PROP_SCALES[kind]
	body.add_child(sprite)
	if kind == "table":
		_add_box_shape(body, Vector2(240, 90), Vector2(0, -38))
		_add_box_shape(body, Vector2(24, 105), Vector2(-112, 45))
		_add_box_shape(body, Vector2(24, 105), Vector2(112, 45))
	elif kind == "stove":
		_add_box_shape(body, Vector2(205, 150), Vector2(0, -20))
	else:
		_add_box_shape(body, PROP_COLLISIONS[kind], Vector2(0, -6))
	$Escenario.add_child(body)


func _add_box_shape(body: StaticBody2D, size: Vector2, offset: Vector2) -> void:
	var shape := CollisionShape2D.new()
	shape.position = offset
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.add_child(shape)


func _add_oil(at: Vector2) -> void:
	var area := Area2D.new()
	area.name = "Charco de aceite"
	area.collision_layer = 0
	area.collision_mask = 1
	area.position = at
	area.z_index = -1
	var sprite := Sprite2D.new()
	sprite.texture = _atlas_region(PROP_ATLAS, REGIONS["oil"])
	sprite.scale = Vector2.ONE * 0.48
	area.add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 82.0
	shape.shape = circle
	area.add_child(shape)
	area.body_entered.connect(_on_oil_entered)
	area.body_exited.connect(_on_oil_exited)
	$Escenario.add_child(area)


func _add_decoration(kind: String, at: Vector2, size_scale: float, angle: float = 0.0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _atlas_region(PROP_ATLAS, REGIONS[kind])
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


func _on_oil_entered(body: Node2D) -> void:
	if body == player:
		player.enter_oil()


func _on_oil_exited(body: Node2D) -> void:
	if body == player:
		player.exit_oil()


func _on_exit_entered(body: Node2D) -> void:
	if body == player and not finished:
		_finish(true, "¡Saliste del Bodegón!" if level_number == 2 else "¡Escapaste de la Cocina!")


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


func _finish(success: bool, text: String) -> void:
	if finished:
		return
	finished = true
	won = success
	player.controls_enabled = false
	for enemy in enemies:
		enemy.enabled = false
	$HUD/Resultado/Caja/Mensaje.text = text
	$HUD/Resultado/Caja/Accion.text = "Siguiente nivel" if success and level_number == 2 else "Jugar otra vez"
	result.show()
	$HUD/Resultado/Caja/Accion.grab_focus()


func _result_action() -> void:
	if won and level_number == 2:
		get_tree().change_scene_to_file("res://nivel_3.tscn")
	else:
		_restart()


func _restart() -> void:
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
