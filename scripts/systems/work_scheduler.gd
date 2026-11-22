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
		priority,
		required_work,
		output_resource,
		output_amount
	)
	orders.append(order)
	return order_id


func advance_hour(colonists: Array[DwarfColonist]) -> void:
	for colonist in colonists:
		if not colonist.alive:
			_release_assignment(colonist.id)
			continue
		if colonist.hunger >= 80.0 or colonist.thirst >= 80.0 or colonist.fatigue >= 85.0:
			continue

		var order := _get_assigned_order(colonist.id)
		if order == null:
			order = _select_order(colonist)
			if order == null:
				continue
			_assignments[colonist.id] = order.id
			order.assigned_colonist_id = colonist.id
			order.state = ColonyWorkOrder.State.IN_PROGRESS
			task_started.emit(order.id, colonist.id)

		if colonist.current_level != order.level:
			colonist.current_level = order.level
			continue

		if order.advance(colonist.get_work_speed(order.work_type)):
			task_completed.emit(order.id, order.output_resource, order.output_amount)
			_release_assignment(colonist.id)

	_prune_completed_orders()


func get_active_orders_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for order in orders:
		if order.state == ColonyWorkOrder.State.AVAILABLE or order.state == ColonyWorkOrder.State.IN_PROGRESS:
			result.append(order.get_snapshot())
	return result


func _select_order(_colonist: DwarfColonist) -> ColonyWorkOrder:
	var candidates: Array[ColonyWorkOrder] = []
	for order in orders:
		if order.state == ColonyWorkOrder.State.AVAILABLE:
			candidates.append(order)

	if candidates.is_empty():
		return null

	candidates.sort_custom(func(a: ColonyWorkOrder, b: ColonyWorkOrder) -> bool:
		if a.priority == b.priority:
			return String(a.id) < String(b.id)
		return a.priority > b.priority
	)
	return candidates[0]


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
