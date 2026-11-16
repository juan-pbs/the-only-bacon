extends SceneTree

# Run with: godot --headless --path . --script res://tests/smoke.gd

var elapsed := 0.0


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 15.0:
		push_error("Smoke test timed out")
		quit(1)
	return false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for number in [1, 2, 3]:
		var scene: Node2D = load("res://nivel_%d.tscn" % number).instantiate()
		root.add_child(scene)
		await process_frame
		await physics_frame
		await process_frame
		assert(scene.get_node("Pisos").get_child_count() == 0)
		assert(scene.enemies.size() == (1 if number == 1 else 2))
		var exit_area: Area2D = scene.get_node("Salida")
		var opening: RectangleShape2D = exit_area.get_node("CollisionShape2D").shape
		assert(opening.size.x <= 45.0 and opening.size.y <= 45.0)
		var exit_query := PhysicsShapeQueryParameters2D.new()
		exit_query.shape = scene.get_node("Tocino/CollisionShape2D").shape
		var body_offset: Vector2 = scene.get_node("Tocino/CollisionShape2D").position
		exit_query.transform = Transform2D(0.0, exit_area.global_position + body_offset)
		exit_query.collision_mask = 18
		assert(scene.get_world_2d().direct_space_state.intersect_shape(exit_query, 1).is_empty(), "Exit blocked in level %d" % number)
		var blocked_side := Vector2(30, 0) if number == 1 else Vector2(0, 30)
		exit_query.transform = Transform2D(0.0, exit_area.global_position + body_offset + blocked_side)
		assert(not scene.get_world_2d().direct_space_state.intersect_shape(exit_query, 1).is_empty(), "Exit gap too wide in level %d" % number)
		for step in range(7):
			var approach: Vector2
			if number == 1:
				approach = exit_area.global_position + Vector2(0, 120.0 - step * 20.0)
			elif number == 2:
				approach = exit_area.global_position + Vector2(-120.0 + step * 20.0, 0)
			else:
				approach = exit_area.global_position + Vector2(120.0 - step * 20.0, 0)
			exit_query.transform = Transform2D(0.0, approach + body_offset)
			assert(scene.get_world_2d().direct_space_state.intersect_shape(exit_query, 1).is_empty(), "Exit approach blocked in level %d at %s" % [number, approach])
		var kinds: Array[String] = []
		for item in scene.get_node("Escenario").get_children():
			if item.get_script() != preload("res://scripts/recogible.gd"):
				continue
			kinds.append(item.kind)
			var art := item.get_children().filter(func(node: Node) -> bool: return node is Sprite2D)
			assert(art.size() == 1 and art[0].texture != null, "Pickup without a sprite in level %d" % number)
			var point := PhysicsPointQueryParameters2D.new()
			point.position = item.global_position
			point.collision_mask = 18
			assert(scene.get_world_2d().direct_space_state.intersect_point(point, 1).is_empty(), "Pickup obstructed in level %d at %s" % [number, item.position])
		for kind in ["can", "pan", "butter", "clock"]:
			assert(kind in kinds, "Missing %s in level %d" % [kind, number])
		for zone in get_nodes_in_group("hide_zones"):
			assert(zone.get_children().all(func(node: Node) -> bool: return not node is Polygon2D))
		var player: CharacterBody2D = scene.get_node("Tocino")
		if number == 1:
			scene._close_tutorial()
		assert(player.collect_item("can"))
		assert(player.cans == 1)
		assert(player.collect_item("pan"))
		assert(player.pans == 1)
		player.health = 70
		assert(player.collect_item("butter"))
		assert(player.health == 95)
		var before: float = scene.remaining
		assert(player.collect_item("clock"))
		assert(scene.remaining >= before + 9.9)
		var first_enemy: CharacterBody2D = scene.enemies[0]
		first_enemy.take_hit(150, 2.6)
		assert(first_enemy.health == 250 and first_enemy.stun_time == 2.6)
		var pools_before: int = scene.get_node("Escenario").get_children().filter(func(node: Node) -> bool: return node.get_script() == preload("res://scripts/charco_aceite.gd")).size()
		first_enemy._throw_oil()
		var bottle := scene.get_children().filter(func(node: Node) -> bool: return node.get_script() == preload("res://scripts/botella_aceite.gd"))
		assert(bottle.size() == 1 and bottle[0].sprite.texture != null)
		await create_timer(0.75).timeout
		var pools_after: int = scene.get_node("Escenario").get_children().filter(func(node: Node) -> bool: return node.get_script() == preload("res://scripts/charco_aceite.gd")).size()
		assert(pools_after > pools_before)
		player._start_leap(true)
		assert(player.collision_mask == 2)
		await create_timer(0.6).timeout
		assert(player.collision_mask == 18)
		player._start_leap(false)
		var before_damage: int = player.health
		player.take_damage(18)
		assert(player.health == before_damage)
		await create_timer(0.32).timeout
		player._start_throw()
		assert(player.cans == 0)
		player._launch_can()
		assert(get_nodes_in_group("projectiles").size() > 0)
		scene._toggle_pause()
		assert(scene.paused and not player.controls_enabled)
		scene._toggle_pause()
		assert(not scene.paused and player.controls_enabled)
		await create_timer(0.45).timeout
		player.enter_hide_zone()
		Input.action_press("hide")
		await physics_frame
		await process_frame
		assert(player.is_hidden)
		assert(not scene.enemies[0]._can_see_target())
		Input.action_release("hide")
		player.exit_hide_zone()
		if number == 2:
			assert(scene.fog_overlay != null)
		if number == 3:
			assert(scene.remaining < 190.0)
			assert(scene.fog_image == null and player.match_sprite != null)
			assert(scene.fog_overlay.material.shader == preload("res://shaders/match_darkness.gdshader"))
			var old_light: Vector2 = scene.fog_overlay.material.get_shader_parameter("flame_position")
			player.global_position += Vector2(100, 0)
			await process_frame
			var new_light: Vector2 = scene.fog_overlay.material.get_shader_parameter("flame_position")
			assert(new_light.distance_to(old_light + Vector2(100, 0)) < 1.0, "Match light did not follow Tocino")
		player.global_position = exit_area.global_position
		for step in range(3):
			await physics_frame
			await process_frame
		assert(scene.finished and scene.won, "Exit did not trigger in level %d; overlaps: %s" % [number, exit_area.get_overlapping_bodies()])
		scene.queue_free()
		await process_frame
	var finale: Control = load("res://final.tscn").instantiate()
	root.add_child(finale)
	await process_frame
	assert(finale.get_node("Centro/Menu") != null)
	finale.queue_free()
	print("SMOKE OK")
	quit()
