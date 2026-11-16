extends SceneTree

const STEP := 40.0
const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var elapsed := 0.0


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 15.0:
		push_error("Route check timed out")
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
		var routes := _find_routes(scene)
		assert(routes.has("exit"), "No route found to exit in level %d" % number)
		var steps: int = routes["exit"]
		for item in scene.get_node("Escenario").get_children():
			if item.get_script() == preload("res://scripts/recogible.gd"):
				assert(routes.has(item.get_instance_id()), "No route to %s at %s in level %d" % [item.kind, item.position, number])
		print("Level %d: exit route %.0f units; %d pickups reachable" % [number, steps * STEP, routes.size() - 1])
		scene.queue_free()
		await process_frame
	quit()


func _find_routes(scene: Node2D) -> Dictionary:
	# Shift the sampling grid slightly so it includes the narrow side openings.
	var start: Vector2 = scene.player.global_position + Vector2(0, -8)
	var goals := {"exit": scene.get_node("Salida").global_position}
	for item in scene.get_node("Escenario").get_children():
		if item.get_script() == preload("res://scripts/recogible.gd"):
			goals[item.get_instance_id()] = item.global_position
	var routes := {}
	var width: float = scene.get_node("Pisos").columns * 102.0
	var height: float = scene.get_node("Pisos").rows * 102.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = scene.player.get_node("CollisionShape2D").shape
	query.collision_mask = 18
	query.exclude = [scene.player.get_rid()]
	var frontier: Array[Vector2i] = [Vector2i.ZERO]
	var visited := {Vector2i.ZERO: true}
	var distance := {Vector2i.ZERO: 0}
	var index := 0
	while index < frontier.size():
		var cell: Vector2i = frontier[index]
		index += 1
		var position := start + Vector2(cell) * STEP
		for key in goals:
			if routes.has(key):
				continue
			var radius := 70.0 if typeof(key) == TYPE_STRING else 43.0
			if position.distance_to(goals[key]) <= radius:
				routes[key] = distance[cell]
		if routes.size() == goals.size():
			return routes
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if visited.has(next):
				continue
			var candidate := start + Vector2(next) * STEP
			if candidate.x < 0.0 or candidate.y < 0.0 or candidate.x > width or candidate.y > height:
				continue
			query.transform = Transform2D(0.0, candidate + scene.player.get_node("CollisionShape2D").position)
			if not scene.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
				continue
			visited[next] = true
			distance[next] = distance[cell] + 1
			frontier.append(next)
	return routes
