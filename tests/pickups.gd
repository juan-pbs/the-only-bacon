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
			assert(not is_instance_valid(item), "%s at %s did not collect in level %d" % [kind, player.position, number])
			match kind:
				"can": assert(player.cans == old_cans + 1)
				"pan": assert(player.pans == old_pans + 1)
				"butter": assert(player.health == mini(100, old_health + 25))
				"clock": assert(scene.remaining >= old_time + 9.9)
		print("Level %d: %d pickups collected" % [number, items.size()])
		scene.queue_free()
		await process_frame
	print("PICKUPS OK")
	quit()
