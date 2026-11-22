class_name ColonyNavigationGrid
extends RefCounted

const GRID_WIDTH := 40
const LEVEL_COUNT := 3
const ELEVATOR_COLUMN := 34

var blocked_cells: Dictionary = {}
var diggable_cells: Dictionary = {}
var excavated_cells: Dictionary = {}



func clear_terrain() -> void:
	blocked_cells.clear()
	diggable_cells.clear()
	excavated_cells.clear()


func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GRID_WIDTH:
		return false
	if cell.y < 0 or cell.y >= LEVEL_COUNT:
		return false
	return not blocked_cells.has(cell)


func set_blocked(cell: Vector2i, blocked: bool) -> void:
	if not _is_inside(cell):
		return
	if blocked:
		blocked_cells[cell] = true
	else:
		blocked_cells.erase(cell)


func set_diggable(cell: Vector2i, diggable: bool = true) -> void:
	if not _is_inside(cell):
		return
	if diggable:
		diggable_cells[cell] = true
		blocked_cells[cell] = true
	else:
		diggable_cells.erase(cell)
		blocked_cells.erase(cell)


func can_dig(cell: Vector2i) -> bool:
	return _is_inside(cell) and diggable_cells.has(cell)


func excavate(cell: Vector2i) -> bool:
	if not can_dig(cell):
		return false
	diggable_cells.erase(cell)
	blocked_cells.erase(cell)
	excavated_cells[cell] = true
	return true


func get_diggable_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in diggable_cells:
		result.append(cell)
	return result


func get_adjacent_work_cell(start: Vector2i, target: Vector2i) -> Vector2i:
	if not can_dig(target) or not is_walkable(start):
		return Vector2i(-1, -1)

	var candidates: Array[Vector2i] = [
		Vector2i(target.x - 1, target.y),
		Vector2i(target.x + 1, target.y)
	]
	var best_cell := Vector2i(-1, -1)
	var best_distance := 2147483647
	for candidate in candidates:
		if not is_walkable(candidate):
			continue
		var distance := 0
		if candidate != start:
			var path := find_path(start, candidate)
			if path.is_empty():
				continue
			distance = path.size()
		if distance < best_distance:
			best_distance = distance
			best_cell = candidate
	return best_cell



func get_adjacent_build_cell(start: Vector2i, target: Vector2i) -> Vector2i:
	if not is_walkable(start) or not is_walkable(target):
		return Vector2i(-1, -1)
	var candidates: Array[Vector2i] = [
		Vector2i(target.x - 1, target.y),
		Vector2i(target.x + 1, target.y)
	]
	var best_cell := Vector2i(-1, -1)
	var best_distance := 2147483647
	for candidate in candidates:
		if not is_walkable(candidate):
			continue
		var distance := 0
		if candidate != start:
			var path := find_path(start, candidate)
			if path.is_empty():
				continue
			distance = path.size()
		if distance < best_distance:
			best_distance = distance
			best_cell = candidate
	return best_cell


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


func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_WIDTH and cell.y >= 0 and cell.y < LEVEL_COUNT


func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = [
		Vector2i(cell.x - 1, cell.y),
		Vector2i(cell.x + 1, cell.y)
	]

	# A single elevator connects adjacent layers.
	if cell.x == ELEVATOR_COLUMN:
		if cell.y > 0:
			result.append(Vector2i(ELEVATOR_COLUMN, cell.y - 1))
		if cell.y < LEVEL_COUNT - 1:
			result.append(Vector2i(ELEVATOR_COLUMN, cell.y + 1))
	return result
