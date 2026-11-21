extends SceneTree

# Verifies that Area2D body_entered actually collects every item in every level.

var elapsed := 0.0


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 20.0:
		push_error("Pickup test timed out")
		quit(1)
	return false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for number in [1, 2, 3]:
		var scene: Node2D = load("res://nivel_%d.tscn" % number).instantiate()
		root.add_child(scene)
		await physics_frame
		await process_frame
		if number == 1:
			scene._close_tutorial()
		scene._set_action_enabled(false)
		var player: CharacterBody2D = scene.player
		var items: Array[Node] = []
		for child in scene.get_node("Escenario").get_children():
			if child.get_script() == preload("res://scripts/recogible.gd"):
				items.append(child)
		for item in items:
			var kind: String = item.kind
			if kind == "butter":
				player.health = 100 if number == 2 else 50
			var old_health: int = player.health
			var old_cans: int = player.cans
			var old_pans: int = player.pans
			var old_time: float = scene.remaining
			player.global_position = item.global_position
			for step in range(3):
				await physics_frame
				await process_frame
			assert(is_instance_valid(item) and item.collected and not item.visible, "%s at %s did not collect in level %d" % [kind, player.position, number])
			assert(item.respawn_seconds == 5.0)
			match kind:
				"can": assert(player.cans == old_cans + 1)
				"pan": assert(player.pans == old_pans + 1)
				"butter": assert(player.health == mini(100, old_health + 25))
				"clock": assert(scene.remaining >= old_time + 9.9)
		player.global_position = Vector2(-1000, -1000)
		items[0].respawn_remaining = 5.0
		items[0]._process(4.9)
		assert(not items[0].visible, "Pickup respawned before five seconds in level %d" % number)
		items[0]._process(0.2)
		await process_frame
		assert(items[0].visible and not items[0].collected, "Pickup did not respawn in level %d" % number)
		print("Level %d: %d pickups collected" % [number, items.size()])
		scene.queue_free()
		await process_frame
	print("PICKUPS OK")
	quit()
