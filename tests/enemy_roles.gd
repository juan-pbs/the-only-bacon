extends SceneTree

var elapsed := 0.0


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 15.0:
		push_error("Enemy roles test timed out")
		quit(1)
	return false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for number in [1, 2, 3]:
		var scene: Node2D = load("res://nivel_%d.tscn" % number).instantiate()
		root.add_child(scene)
		if number == 1:
			scene._close_tutorial()
		var player: CharacterBody2D = scene.player
		player.controls_enabled = false
		var spawn: Vector2 = player.global_position
		var shelter: Area2D = scene.get_node("Escenario/RefugioInicial")
		assert(shelter.get_children().filter(func(node: Node) -> bool: return node is Sprite2D).size() >= 2)
		assert(player.spawn_sheltered and player.is_hidden)
		var tlacua: CharacterBody2D = scene.enemies[0]
		assert(tlacua.kind == "tlacua" and tlacua.global_position.distance_to(spawn) < 400.0)
		var cuache: CharacterBody2D
		if number > 1:
			cuache = scene.enemies[1]
			assert(cuache.kind == "cuache")
			assert(cuache.guard_post == scene.get_node("Salida").global_position)
			assert(cuache.global_position.distance_to(cuache.guard_post) < 200.0)
		for step in range(65):
			await physics_frame
			await process_frame
		assert(player.health == 100, "Tocino was attacked at spawn in level %d" % number)
		assert(not tlacua._can_see_target())
		if cuache != null:
			assert(cuache.global_position.distance_to(cuache.guard_post) <= cuache.guard_radius)
		player.global_position = spawn + Vector2(0, -185)
		for step in range(3):
			await physics_frame
			await process_frame
		assert(not player.spawn_sheltered, "Shelter did not release Tocino in level %d" % number)
		var distance_before: float = tlacua.global_position.distance_to(player.global_position)
		for step in range(20):
			await physics_frame
			await process_frame
		var distance_after: float = tlacua.global_position.distance_to(player.global_position)
		assert(tlacua.pursuit_time > 0.0, "Tlacua did not pursue Tocino in level %d" % number)
		assert(distance_after < distance_before, "Tlacua did not close the distance in level %d" % number)
		if cuache != null:
			player.health = 100
			player.invulnerability = 0.0
			var inside_direction := -1.0 if number == 2 else 1.0
			player.global_position = cuache.global_position + Vector2(inside_direction * 160.0, 0)
			for step in range(70):
				await physics_frame
				await process_frame
			assert(player.health < 100, "Cuache did not defend the exit in level %d" % number)
			assert(cuache.global_position.distance_to(cuache.guard_post) <= cuache.guard_radius)
		print("Level %d: spawn safe; Tlacua pursued%s" % [number, "; Cuache defended exit" if cuache != null else ""])
		scene.queue_free()
		await process_frame
	print("ENEMY ROLES OK")
	quit()
