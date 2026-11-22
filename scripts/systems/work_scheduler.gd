class_name ColonyWorkScheduler
extends RefCounted

signal task_completed(task_id: StringName, resource: StringName, amount: int)
signal task_started(task_id: StringName, colonist_id: StringName)

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
			_release_assignment(colonist.id)
			continue
		if colonist.hunger >= 80.0 or colonist.thirst >= 80.0 or colonist.fatigue >= 85.0:
			continue

		var assigned_order := _get_assigned_order(colonist.id)
		if assigned_order != null:
			_progress_order(colonist, assigned_order, navigation)

	_assign_available_orders(colonists, navigation)
	_prune_completed_orders()


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
	if colonist.current_position != order.target_cell:
		var path := navigation.find_path(colonist.current_position, order.target_cell)
		if path.is_empty():
			_release_assignment(colonist.id)
			return

		var movement_steps := mini(4, path.size())
		colonist.current_position = path[movement_steps - 1]
		colonist.current_level = colonist.current_position.y
		return

	if order.advance(colonist.get_work_speed(order.work_type)):
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
			if not colonist.alive or _assignments.has(colonist.id):
				continue
			if colonist.hunger >= 80.0 or colonist.thirst >= 80.0 or colonist.fatigue >= 85.0:
				continue

			var path := navigation.find_path(colonist.current_position, order.target_cell)
			if colonist.current_position != order.target_cell and path.is_empty():
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

	var order := _get_assigned_order(colonist_id)
	if order != null and order.state != ColonyWorkOrder.State.COMPLETED:
		order.state = ColonyWorkOrder.State.AVAILABLE
		order.assigned_colonist_id = &""

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
