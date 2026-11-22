class_name ColonyNavigationGrid
extends RefCounted

const GRID_WIDTH := 40
const LEVEL_COUNT := 3
const ELEVATOR_COLUMN := 34

var blocked_cells: Dictionary = {}


func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GRID_WIDTH:
		return false
	if cell.y < 0 or cell.y >= LEVEL_COUNT:
		return false
	return not blocked_cells.has(cell)


func set_blocked(cell: Vector2i, blocked: bool) -> void:
	if cell.x < 0 or cell.x >= GRID_WIDTH:
		return
	if cell.y < 0 or cell.y >= LEVEL_COUNT:
		return
	if blocked:
		blocked_cells[cell] = true
	else:
		blocked_cells.erase(cell)


func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not is_walkable(start) or not is_walkable(goal):
		return path
	if start == goal:
		return path

	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	var found := false

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal:
			found = true
			break

		for next_cell in _get_neighbors(current):
			if not is_walkable(next_cell) or came_from.has(next_cell):
				continue
			came_from[next_cell] = current
			frontier.append(next_cell)

	if not found:
		return path

	var cursor := goal
	while cursor != start:
		path.push_front(cursor)
		cursor = came_from[cursor]
	return path


func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = [
		Vector2i(cell.x - 1, cell.y),
		Vector2i(cell.x + 1, cell.y)
	]

	# A single elevator connects adjacent layers: surface, shallow subsurface and deep rock.
	if cell.x == ELEVATOR_COLUMN:
		if cell.y > 0:
			result.append(Vector2i(ELEVATOR_COLUMN, cell.y - 1))
		if cell.y < LEVEL_COUNT - 1:
			result.append(Vector2i(ELEVATOR_COLUMN, cell.y + 1))
	return result
