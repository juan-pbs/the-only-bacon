extends "res://scripts/nivel_base.gd"

const TILE_SIZE := 102.0
const PROP_ATLAS := preload("res://assets/sprites/objetos-escenario.png")
const EXPLORATION_FOG := preload("res://shaders/exploration_fog.gdshader")
const MATCH_DARKNESS := preload("res://shaders/match_darkness.gdshader")
const TLACUA_SCENE := preload("res://tlacua.tscn")
const CUACHE_SCENE := preload("res://cuache_enemigo.tscn")
const FOG_PIXEL_SIZE := 16.0
const FOG_REVEAL_RADIUS := 310.0
const REGIONS := {
	"crate": Rect2(45, 80, 350, 370),
	"eggs": Rect2(480, 65, 355, 390),
	"oil": Rect2(875, 90, 435, 365),
	"stove": Rect2(30, 500, 415, 360),
	"table": Rect2(460, 510, 435, 355),
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

var fog_overlay: ColorRect
var fog_image: Image
var fog_texture: ImageTexture
var last_reveal_position := Vector2.INF

func _ready() -> void:
	var columns := 24 if level_number == 2 else 30
	var rows := 32 if level_number == 2 else 40
	var width := columns * TILE_SIZE
	var height := rows * TILE_SIZE
	remaining = 190.0 if level_number == 2 else 180.0
	$HUD/Barra/Fila/Titulo.text = "NIVEL 2 · EL BODEGÓN DE HUEVOS" if level_number == 2 else "NIVEL 3 · LA COCINA DEL DESAYUNO"
	player.position = Vector2(width / 2.0, height - 260.0)
	$Salida.position = Vector2(width - 70.0, 565.0) if level_number == 2 else Vector2(70.0, 565.0)
	$Tocino/Camera2D.limit_left = 0
	$Tocino/Camera2D.limit_top = 0
	$Tocino/Camera2D.limit_right = int(width)
	$Tocino/Camera2D.limit_bottom = int(height)
	_build_floor(columns, rows)
	_build_boundaries(width, height)
	_build_layout()
	_build_enemies()
	spawn_start_shelter()
	if level_number == 2:
		_setup_exploration_fog(Vector2(width, height))
	else:
		_setup_match_darkness(Vector2(width, height))
	super._ready()


func _level_number() -> int:
	return level_number


func _process(delta: float) -> void:
	if fog_overlay != null and not paused and not finished:
		if level_number == 2:
			_update_exploration_fog()
		else:
			fog_overlay.material.set_shader_parameter("flame_position", player.match_light_position())
	super._process(delta)


func _setup_exploration_fog(world_size: Vector2) -> void:
	fog_image = Image.create(ceili(world_size.x / FOG_PIXEL_SIZE), ceili(world_size.y / FOG_PIXEL_SIZE), false, Image.FORMAT_R8)
	fog_image.fill(Color.BLACK)
	fog_texture = ImageTexture.create_from_image(fog_image)
	fog_overlay = ColorRect.new()
	fog_overlay.name = "OscuridadExplorable"
	fog_overlay.size = world_size
	fog_overlay.z_index = 100
	fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = EXPLORATION_FOG
	material.set_shader_parameter("explored_map", fog_texture)
	material.set_shader_parameter("world_size", world_size)
	fog_overlay.material = material
	add_child(fog_overlay)
	_update_exploration_fog()


func _setup_match_darkness(world_size: Vector2) -> void:
	player.equip_match()
	fog_overlay = ColorRect.new()
	fog_overlay.name = "OscuridadDelCerillo"
	fog_overlay.size = world_size
	fog_overlay.z_index = 100
	fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = MATCH_DARKNESS
	material.set_shader_parameter("world_size", world_size)
	material.set_shader_parameter("flame_position", player.match_light_position())
	fog_overlay.material = material
	add_child(fog_overlay)


func _update_exploration_fog() -> void:
	fog_overlay.material.set_shader_parameter("explorer_position", player.global_position)
	if player.global_position.distance_to(last_reveal_position) < FOG_PIXEL_SIZE:
		return
	last_reveal_position = player.global_position
	var first_x := maxi(0, floori((player.global_position.x - FOG_REVEAL_RADIUS) / FOG_PIXEL_SIZE))
	var last_x := mini(fog_image.get_width() - 1, ceili((player.global_position.x + FOG_REVEAL_RADIUS) / FOG_PIXEL_SIZE))
	var first_y := maxi(0, floori((player.global_position.y - FOG_REVEAL_RADIUS) / FOG_PIXEL_SIZE))
	var last_y := mini(fog_image.get_height() - 1, ceili((player.global_position.y + FOG_REVEAL_RADIUS) / FOG_PIXEL_SIZE))
	for map_y in range(first_y, last_y + 1):
		for map_x in range(first_x, last_x + 1):
			var map_position := Vector2(map_x + 0.5, map_y + 0.5) * FOG_PIXEL_SIZE
			var distance := map_position.distance_to(player.global_position)
			if distance > FOG_REVEAL_RADIUS:
				continue
			var reveal := 1.0 - smoothstep(FOG_REVEAL_RADIUS * 0.72, FOG_REVEAL_RADIUS, distance)
			if reveal > fog_image.get_pixel(map_x, map_y).r:
				fog_image.set_pixel(map_x, map_y, Color(reveal, 0.0, 0.0))
	fog_texture.update(fog_image)


func _build_floor(columns: int, rows: int) -> void:
	$Pisos.configure(columns, rows, level_number)


func _build_boundaries(width: float, height: float) -> void:
	var gap_y: float = $Salida.position.y + $Tocino/CollisionShape2D.position.y
	if level_number == 2:
		_add_wall("Pared izquierda", Rect2(0, 0, 130, height))
		_add_wall("Pared derecha superior", Rect2(width - 130, 0, 130, gap_y - 25.0))
		_add_wall("Pared derecha inferior", Rect2(width - 130, gap_y + 25.0, 130, height - gap_y - 25.0))
	else:
		_add_wall("Pared izquierda superior", Rect2(0, 0, 130, gap_y - 25.0))
		_add_wall("Pared izquierda inferior", Rect2(0, gap_y + 25.0, 130, height - gap_y - 25.0))
		_add_wall("Pared derecha", Rect2(width - 130, 0, 130, height))
	_add_wall("Pared inferior", Rect2(0, height - 145, width, 145))
	_add_wall("Pared superior", Rect2(0, 0, width, 125))
	for x in range(110, int(width), 210):
		_add_decoration("fence", Vector2(x, 45), 0.55)
		_add_decoration("fence", Vector2(x, height - 45), 0.55)
	_decorate_side(42.0, height, gap_y if level_number == 3 else -1.0)
	_decorate_side(width - 42.0, height, gap_y if level_number == 2 else -1.0)


func _decorate_side(x: float, height: float, gap_y: float) -> void:
	# The fence art has transparent padding, so extend it to match the narrow collision gap.
	var segments := [Vector2(0.0, height)] if gap_y < 0.0 else [Vector2(0.0, gap_y), Vector2(gap_y, height)]
	for segment in segments:
		var segment_length: float = segment.y - segment.x
		var pieces := ceili(segment_length / 230.0)
		var piece_length := segment_length / pieces
		for index in range(pieces):
			_add_decoration("fence", Vector2(x, segment.x + (index + 0.5) * piece_length), piece_length / 435.0, PI / 2.0)


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
	var enemy_spawns := [player.position + Vector2(0, -330), $Salida.position + Vector2(-125, 0)] if level_number == 2 else [player.position + Vector2(0, -330), $Salida.position + Vector2(125, 0)]
	for spawn in enemy_spawns:
		reserved.append(Rect2(spawn - Vector2(85, 85), Vector2(170, 170)))
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
	var items := [
		["can", Vector2(1020, 2250)], ["pan", Vector2(620, 1660)],
		["can", Vector2(1450, 1090)], ["butter", Vector2(430, 1240)],
		["clock", Vector2(1210, 580)]
	] if level_number == 2 else [
		["can", Vector2(1150, 2810)], ["pan", Vector2(1650, 2270)],
		["can", Vector2(640, 1840)], ["butter", Vector2(1690, 1210)],
		["clock", Vector2(1050, 790)]
	]
	for entry in items:
		var position := _find_clear_position(entry[1] * layout_scale, Vector2(80, 80), occupied, reserved, world_size)
		if position != Vector2.INF:
			spawn_pickup(entry[0], position)
	for hide_position in [Vector2(460, 2070), Vector2(1530, 1560), Vector2(570, 740)]:
		var position := _find_clear_position(hide_position * layout_scale, Vector2(130, 130), occupied, reserved, world_size)
		if position != Vector2.INF:
			spawn_hide_zone(position)


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
	var tlacua_start := player.position + Vector2(0, -330)
	_add_enemy("tlacua", tlacua_start, [tlacua_start, tlacua_start + Vector2(80, -70)])
	var side := -1.0 if level_number == 2 else 1.0
	var guard_start: Vector2 = $Salida.position + Vector2(side * 125.0, 0)
	_add_enemy("cuache", guard_start, [guard_start, guard_start + Vector2(side * 40.0, -95.0)])


func _layout_scale() -> Vector2:
	return Vector2(1.2, 3264.0 / 2652.0) if level_number == 2 else Vector2(1.25, 4080.0 / 3060.0)


func _add_enemy(kind: String, at: Vector2, route: Array[Vector2]) -> void:
	var enemy: CharacterBody2D = (TLACUA_SCENE if kind == "tlacua" else CUACHE_SCENE).instantiate()
	enemy.position = at
	enemy.patrol_points = route
	enemy.target = player
	if kind == "cuache":
		enemy.guard_post = $Salida.position
	add_child(enemy)
	enemies.append(enemy)


func _add_prop(label: String, kind: String, at: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = label
	body.collision_layer = 16 if kind == "eggs" else 2
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
	spawn_oil(at, 25.0)


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
