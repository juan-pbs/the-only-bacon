extends SceneTree

var elapsed := 0.0


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 5.0:
		push_error("Cuache attack test timed out")
		quit(1)
	return false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var player: CharacterBody2D = load("res://tocino.tscn").instantiate()
	player.position = Vector2(500, 500)
	player.controls_enabled = false
	arena.add_child(player)
	var cuache: CharacterBody2D = load("res://cuache_enemigo.tscn").instantiate()
	cuache.position = Vector2(680, 500)
	cuache.target = player
	arena.add_child(cuache)
	var began_pounce := false
	for step in range(90):
		await physics_frame
		await process_frame
		if cuache.action_state in ["pounce_windup", "pounce"]:
			began_pounce = true
		if player.health < 100:
			break
	assert(began_pounce, "Cuache never began his pounce")
	assert(player.health < 100, "Cuache did not damage Tocino")
	print("CUACHE ATTACK OK: Tocino health %d" % player.health)
	arena.queue_free()
	quit()
