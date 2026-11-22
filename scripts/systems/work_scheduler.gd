class_name ColonyWorkScheduler
extends RefCounted

signal task_completed(task_id: StringName, resource: StringName, amount: int)
signal task_started(task_id: StringName, colonist_id: StringName)
signal terrain_excavated(cell: Vector2i)
signal crop_planted(cell: Vector2i)

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
	if colonist.is_moving:
		return
	var work_target := _get_work_target(order, colonist.current_position, navigation)
	if work_target.x < 0:
		if order.work_type == &"dig":
			order.state = ColonyWorkOrder.State.CANCELLED
		_release_assignment(colonist.id)
		return

	if colonist.current_position != work_target:
		var path := navigation.find_path(colonist.current_position, work_target)
		if path.is_empty():
			_release_assignment(colonist.id)
			return

		var movement_steps := mini(4, path.size())
		colonist.start_movement(path[movement_steps - 1])
		return

	if order.advance(colonist.get_work_speed(order.work_type)):
		if order.work_type == &"dig":
			if navigation.excavate(order.target_cell):
				terrain_excavated.emit(order.target_cell)
		elif order.work_type == &"plant":
			crop_planted.emit(order.target_cell)
		task_completed.emit(order.id, order.output_resource, order.output_amount)
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

			var work_target := _get_work_target(order, colonist.current_position, navigation)
			if work_target.x < 0:
				continue
			var path := navigation.find_path(colonist.current_position, work_target)
			if colonist.current_position != work_target and path.is_empty():
				continue

			var distance_penalty := float(path.size()) * 0.1
			var score := colonist.get_work_speed(order.work_type) * 100.0 - distance_penalty
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
