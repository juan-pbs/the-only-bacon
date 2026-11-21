extends "res://scripts/nivel_base.gd"

const LEVEL_TIME := 120.0

var fire_glow: Polygon2D


func _ready() -> void:
	remaining = LEVEL_TIME
	fire_glow = $Escenario/ResplandorFogata
	for child in get_children():
		if child is CharacterBody2D and child != player:
			var enemy := child as CharacterBody2D
			var route: Array[Vector2] = [enemy.position, enemy.position + Vector2(65, 60)]
			enemy.set("target", player)
			enemy.set("patrol_points", route)
			enemies.append(enemy)
	super._ready()


func _process(delta: float) -> void:
	if fire_glow != null:
		fire_glow.modulate.a = 0.75 + 0.2 * sin(Time.get_ticks_msec() * 0.006)
	super._process(delta)
