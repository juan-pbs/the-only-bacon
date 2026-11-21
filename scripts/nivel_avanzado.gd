extends "res://scripts/nivel_base.gd"

const EXPLORATION_FOG := preload("res://shaders/exploration_fog.gdshader")
const MATCH_DARKNESS := preload("res://shaders/match_darkness.gdshader")
const FOG_PIXEL_SIZE := 16.0
const FOG_REVEAL_RADIUS := 310.0

@export_range(2, 3) var level_number := 2

var fog_overlay: ColorRect
var fog_image: Image
var fog_texture: ImageTexture
var last_reveal_position := Vector2.INF

func _ready() -> void:
	var width: float = $Pisos.columns * 102.0
	var height: float = $Pisos.rows * 102.0
	remaining = 190.0 if level_number == 2 else 180.0
	$HUD/Barra/Fila/Titulo.text = "NIVEL 2 · EL BODEGÓN DE HUEVOS" if level_number == 2 else "NIVEL 3 · LA COCINA DEL DESAYUNO"
	for child in get_children():
		if child is CharacterBody2D and child != player:
			var enemy := child as CharacterBody2D
			var route: Array[Vector2] = [enemy.position, enemy.position + Vector2(80, -70)]
			enemy.set("target", player)
			enemy.set("patrol_points", route)
			if enemy.get("kind") == "cuache":
				enemy.set("guard_post", $Salida.position)
			enemies.append(enemy)
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
