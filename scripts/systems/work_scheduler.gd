class_name ColonyWorkScheduler
extends RefCounted

signal task_completed(task_id: StringName, resource: StringName, amount: int)
signal task_started(task_id: StringName, colonist_id: StringName)
signal terrain_excavated(cell: Vector2i)
signal map_terrain_excavated(cell: Vector3i)
signal map_structure_built(cell: Vector3i, structure_type: StringName)
signal crop_planted(cell: Vector2i)
signal structure_built(cell: Vector2i, structure_type: StringName)
signal task_cancelled(task_id: StringName)

var orders: Array[ColonyWorkOrder] = []
var _next_order_number := 1
var _assignments: Dictionary = {}


func queue_order(
	work_type: StringName,
	level: int,
	target_cell: Vector2i,
	priority: int,
	required_work: float,
	output_resource: StringName,
	output_amount: int
) -> StringName:
	var order_id := StringName("work_%04d" % _next_order_number)
	_next_order_number += 1

	var order := ColonyWorkOrder.new(
		order_id,
		work_type,
		level,
		target_cell,
		priority,
		required_work,
		output_resource,
		output_amount
	)
	orders.append(order)
	return order_id


func queue_map_excavation(cell: Vector3i, priority: int = 3) -> StringName:
	if not is_map_cell_inside(cell):
		return &""
	for existing in orders:
		if existing.work_type == &"map_dig" and existing.target_map_cell == cell:
			if existing.state == ColonyWorkOrder.State.AVAILABLE or existing.state == ColonyWorkOrder.State.IN_PROGRESS:
				return &""
	var order_id := queue_order(&"map_dig", cell.z, Vector2i(cell.x, cell.z), priority, 3.0, &"", 0)
	for order in orders:
		if order.id == order_id:
			order.target_map_cell = cell
			break
	return order_id


func queue_map_construction(cell: Vector3i, structure_type: StringName, priority: int, required_work: float) -> StringName:
	if not is_map_cell_inside(cell):
		return &""
	for existing in orders:
		if existing.work_type == &"map_build" and existing.target_map_cell == cell:
			if existing.state == ColonyWorkOrder.State.AVAILABLE or existing.state == ColonyWorkOrder.State.IN_PROGRESS:
				return &""
	var order_id := queue_order(&"map_build", cell.z, Vector2i(cell.x, cell.z), priority, required_work, structure_type, 0)
	for order in orders:
		if order.id == order_id:
			order.target_map_cell = cell
			break
	return order_id


func is_map_cell_inside(cell: Vector3i) -> bool:
	return cell.x >= 0 and cell.x < ColonyNavigationGrid.MAP_WIDTH and cell.y >= 0 and cell.y < ColonyNavigationGrid.MAP_HEIGHT and cell.z >= 0 and cell.z < ColonyNavigationGrid.LEVEL_COUNT


func advance_hour(colonists: Array[DwarfColonist], navigation: ColonyNavigationGrid) -> void:
	for colonist in colonists:
		if not colonist.alive:
			colonist.stop_movement()
			_release_assignment(colonist.id)
			continue
		if colonist.is_resting:
			_release_assignment(colonist.id)
			continue
		if colonist.hunger >= 80.0 or colonist.thirst >= 80.0 or colonist.fatigue >= 85.0:
			colonist.stop_movement()
			_release_assignment(colonist.id)
			continue

		var assigned_order := _get_assigned_order(colonist.id)
		if assigned_order != null:
			_progress_order(colonist, assigned_order, navigation)

	_assign_available_orders(colonists, navigation)
	_prune_completed_orders()



func restore_active_orders(snapshots: Array) -> bool:
	orders.clear()
	_assignments.clear()
	_next_order_number = 1
	for item in snapshots:
		if typeof(item) != TYPE_DICTIONARY:
			return false
		var order := ColonyWorkOrder.new(
			StringName(item.get("id", "")),
			StringName(item.get("type", "")),
			int(item.get("level", 0)),
			item.get("target_cell", Vector2i.ZERO),
			int(item.get("priority", 3)),
			float(item.get("required_work", 1.0)),
			StringName(item.get("output_resource", "")),
			int(item.get("output_amount", 0))
		)
		var saved_map_target: Variant = item.get("target_map_cell", Vector3i(-1, -1, -1))
		if typeof(saved_map_target) == TYPE_VECTOR3I:
			order.target_map_cell = saved_map_target
		order.progress = clampf(float(item.get("progress", 0.0)), 0.0, order.required_work)
		order.state = ColonyWorkOrder.State.AVAILABLE
		orders.append(order)
		var suffix := String(order.id).trim_prefix("work_")
		_next_order_number = maxi(_next_order_number, int(suffix) + 1 if suffix.is_valid_int() else 1)
	return true



func release_colonist(colonist_id: StringName) -> void:
	_release_assignment(colonist_id)


func get_active_orders_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for order in orders:
		if order.state == ColonyWorkOrder.State.AVAILABLE or order.state == ColonyWorkOrder.State.IN_PROGRESS:
			result.append(order.get_snapshot())
	return result


func _progress_order(
	colonist: DwarfColonist,
	order: ColonyWorkOrder,
	navigation: ColonyNavigationGrid
) -> void:
	if colonist.is_moving or colonist.is_map_moving:
		return
	if order.work_type == &"map_dig":
		_progress_map_dig_order(colonist, order, navigation)
		return
	if order.work_type == &"map_build":
		_progress_map_build_order(colonist, order, navigation)
		return
	var work_target := _get_work_target(order, colonist.current_position, navigation)
	if work_target.x < 0:
		if order.work_type == &"dig" or order.work_type == &"build":
			order.state = ColonyWorkOrder.State.CANCELLED
			task_cancelled.emit(order.id)
		_release_assignment(colonist.id)
		return

	var map_work_target := Vector3i(work_target.x, ColonyNavigationGrid.ELEVATOR_ROW, work_target.y)
	if colonist.map_position != map_work_target:
		var map_path := navigation.find_map_path(colonist.map_position, map_work_target)
		if map_path.is_empty():
			_release_assignment(colonist.id)
			return
		var movement_steps := mini(4, map_path.size())
		colonist.start_map_movement(map_path[movement_steps - 1])
		return

	if order.advance(colonist.get_work_speed(order.work_type)):
		if order.work_type == &"dig":
			if navigation.excavate(order.target_cell):
				terrain_excavated.emit(order.target_cell)
		elif order.work_type == &"plant":
			crop_planted.emit(order.target_cell)
		elif order.work_type == &"build":
			structure_built.emit(order.target_cell, order.output_resource)
		task_completed.emit(order.id, order.output_resource, order.output_amount)
		_release_assignment(colonist.id)



func _progress_map_dig_order(
	colonist: DwarfColonist,
	order: ColonyWorkOrder,
	navigation: ColonyNavigationGrid
) -> void:
	var work_cell := navigation.get_map_adjacent_work_cell(colonist.map_position, order.target_map_cell)
	if work_cell.x < 0:
		order.state = ColonyWorkOrder.State.CANCELLED
		task_cancelled.emit(order.id)
		_release_assignment(colonist.id)
		return
	if colonist.map_position != work_cell:
		var path := navigation.find_map_path(colonist.map_position, work_cell)
		if path.is_empty():
			_release_assignment(colonist.id)
			return
		var movement_steps := mini(4, path.size())
		colonist.start_map_movement(path[movement_steps - 1])
		return
	if order.advance(colonist.get_work_speed(&"stone")):
		if navigation.excavate_map_cell(order.target_map_cell):
			map_terrain_excavated.emit(order.target_map_cell)
			task_completed.emit(order.id, &"", 0)
		else:
			order.state = ColonyWorkOrder.State.CANCELLED
			task_cancelled.emit(order.id)
		_release_assignment(colonist.id)



func _progress_map_build_order(
	colonist: DwarfColonist,
	order: ColonyWorkOrder,
	navigation: ColonyNavigationGrid
) -> void:
	var work_cell := navigation.get_map_adjacent_cell(colonist.map_position, order.target_map_cell)
	if work_cell.x < 0:
		order.state = ColonyWorkOrder.State.CANCELLED
		task_cancelled.emit(order.id)
		_release_assignment(colonist.id)
		return
	if colonist.map_position != work_cell:
		var path := navigation.find_map_path(colonist.map_position, work_cell)
		if path.is_empty():
			_release_assignment(colonist.id)
			return
		colonist.start_map_movement(path[mini(4, path.size()) - 1])
		return
	if order.advance(colonist.get_work_speed(&"build")):
		if order.output_resource != &"bed":
			navigation.set_map_blocked(order.target_map_cell, true)
		map_structure_built.emit(order.target_map_cell, order.output_resource)
		task_completed.emit(order.id, &"", 0)
		_release_assignment(colonist.id)


func _assign_available_orders(
	colonists: Array[DwarfColonist],
	navigation: ColonyNavigationGrid
) -> void:
	var available_orders: Array[ColonyWorkOrder] = []
	for order in orders:
		if order.state == ColonyWorkOrder.State.AVAILABLE:
			available_orders.append(order)

	available_orders.sort_custom(func(a: ColonyWorkOrder, b: ColonyWorkOrder) -> bool:
		if a.priority == b.priority:
			return String(a.id) < String(b.id)
		return a.priority > b.priority
	)

	for order in available_orders:
		var best_colonist: DwarfColonist
		var best_score := -1000000.0

		for colonist in colonists:
			if not colonist.alive or colonist.is_resting or _assignments.has(colonist.id):
				continue
			if colonist.hunger >= 80.0 or colonist.thirst >= 80.0 or colonist.fatigue >= 85.0:
				continue

			var path_distance := 0
			if order.work_type == &"map_dig" or order.work_type == &"map_build":
				var map_work_target := navigation.get_map_adjacent_work_cell(colonist.map_position, order.target_map_cell) if order.work_type == &"map_dig" else navigation.get_map_adjacent_cell(colonist.map_position, order.target_map_cell)
				if map_work_target.x < 0:
					continue
				var map_path := navigation.find_map_path(colonist.map_position, map_work_target)
				if colonist.map_position != map_work_target and map_path.is_empty():
					continue
				path_distance = map_path.size()
			else:
				var work_target := _get_work_target(order, colonist.current_position, navigation)
				if work_target.x < 0:
					continue
				var path := navigation.find_path(colonist.current_position, work_target)
				if colonist.current_position != work_target and path.is_empty():
					continue
				path_distance = path.size()

			var distance_penalty := float(path_distance) * 0.1
			var work_speed := colonist.get_work_speed(&"stone") if order.work_type == &"map_dig" else colonist.get_work_speed(order.work_type)
			var score := work_speed * 100.0 - distance_penalty
			if score > best_score:
				best_score = score
				best_colonist = colonist

		if best_colonist == null:
			continue

		_assignments[best_colonist.id] = order.id
		order.assigned_colonist_id = best_colonist.id
		order.state = ColonyWorkOrder.State.IN_PROGRESS
		task_started.emit(order.id, best_colonist.id)


func _get_work_target(
	order: ColonyWorkOrder,
	colonist_position: Vector2i,
	navigation: ColonyNavigationGrid
) -> Vector2i:
	if order.work_type == &"dig":
		return navigation.get_adjacent_work_cell(colonist_position, order.target_cell)
	if order.work_type == &"build":
		return navigation.get_adjacent_build_cell(colonist_position, order.target_cell)
	return order.target_cell


func _get_assigned_order(colonist_id: StringName) -> ColonyWorkOrder:
	if not _assignments.has(colonist_id):
		return null

	var assigned_id: StringName = _assignments[colonist_id]
	for order in orders:
		if order.id == assigned_id and order.state == ColonyWorkOrder.State.IN_PROGRESS:
			return order
	return null


func _release_assignment(colonist_id: StringName) -> void:
	if not _assignments.has(colonist_id):
		return

	var assigned_id: StringName = _assignments[colonist_id]
	for order in orders:
		if order.id != assigned_id:
			continue
		if order.state == ColonyWorkOrder.State.IN_PROGRESS:
			order.state = ColonyWorkOrder.State.AVAILABLE
		order.assigned_colonist_id = &""
		break

	_assignments.erase(colonist_id)


func _prune_completed_orders() -> void:
	if orders.size() <= 100:
		return

	var completed_to_remove := orders.size() - 100
	for i in range(orders.size() - 1, -1, -1):
		if completed_to_remove <= 0:
			break
		if orders[i].state == ColonyWorkOrder.State.COMPLETED or orders[i].state == ColonyWorkOrder.State.CANCELLED:
			orders.remove_at(i)
			completed_to_remove -= 1
