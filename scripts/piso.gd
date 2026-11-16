extends Node2D

const ATLAS := preload("res://assets/sprites/pisos-niveles.png")
const TILE_SIZE := 102.0
const EDGES := [0, 105, 209, 314, 418, 523, 627]

var columns := 0
var rows := 0
var level_number := 1


func configure(new_columns: int, new_rows: int, new_level: int) -> void:
	columns = new_columns
	rows = new_rows
	level_number = new_level
	queue_redraw()


func _draw() -> void:
	for row in range(rows):
		for column in range(columns):
			var source_column: int = (column + row * 2) % 6
			var source_row: int = (row + column * 3) % 6
			var source_x := 627 if level_number == 2 else 0
			var source_y := 627 if level_number == 3 or (level_number == 1 and abs(column - 7) <= 2 and abs(row - 10) <= 2) else 0
			var region := Rect2(
				source_x + EDGES[source_column], source_y + EDGES[source_row],
				EDGES[source_column + 1] - EDGES[source_column],
				EDGES[source_row + 1] - EDGES[source_row]
			)
			draw_texture_rect_region(ATLAS, Rect2(column * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE), region)
