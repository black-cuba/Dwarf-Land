class_name ColonySimulation
extends RefCounted

signal time_changed(day: int, hour: int)
signal colony_changed
signal alert_raised(message: String, severity: int)

const LEVEL_COUNT := 3
const ALERT_INFO := 0
const ALERT_WARNING := 1
const ALERT_CRITICAL := 2

var day := 1
var hour := 7
var active_level := 0
var paused := false
var ambient_temperature := 18.0

var inventory := ColonyInventory.new()
var scheduler := ColonyWorkScheduler.new()
var navigation := ColonyNavigationGrid.new()
var colonists: Array[DwarfColonist] = []
var resource_nodes: Dictionary = {}
var _pending_outputs: Array[Dictionary] = []
var _last_alert_key := ""


func _init() -> void:
	scheduler.task_completed.connect(_on_task_completed)
	scheduler.terrain_excavated.connect(_on_terrain_excavated)
	# Initial geological obstacles. These cells must be excavated before passage.
	for cell in [Vector2i(5, 1), Vector2i(6, 1), Vector2i(20, 2), Vector2i(21, 2)]:
		navigation.set_diggable(cell)
	resource_nodes = {
		&"food": ColonyResourceNode.new(&"surface_crops", &"food", 0, Vector2i(11, 0), 24, 48, 6, 4.0, 6),
		&"wood": ColonyResourceNode.new(&"surface_forest", &"wood", 0, Vector2i(21, 0), 18, 36, 3, 5.0, 6),
		&"water": ColonyResourceNode.new(&"shallow_aquifer", &"water", 1, Vector2i(18, 1), 32, 64, 8, 3.0, 8),
		&"clay": ColonyResourceNode.new(&"clay_deposit", &"clay", 1, Vector2i(8, 1), 30, 50, 0, 4.0, 5),
		&"stone": ColonyResourceNode.new(&"deep_bedrock", &"stone", 2, Vector2i(13, 2), 60, 100, 0, 5.0, 5),
		&"ore": ColonyResourceNode.new(&"deep_ore_vein", &"ore", 2, Vector2i(27, 2), 24, 40, 0, 6.0, 3),
		&"coal": ColonyResourceNode.new(&"deep_coal_seam", &"coal", 2, Vector2i(33, 2), 30, 50, 0, 5.0, 4)
	}
	var borin := DwarfColonist.new(&"dwarf_001", "Borin", "Recolector")
	borin.current_position = Vector2i(7, 0)
	colonists.append(borin)
	var dora := DwarfColonist.new(&"dwarf_002", "Dora", "Agricultora")
	dora.current_position = Vector2i(16, 0)
	colonists.append(dora)
	var krag := DwarfColonist.new(&"dwarf_003", "Krag", "Minero")
	krag.current_position = Vector2i(25, 2)
	colonists.append(krag)


func advance_hour() -> void:
	if paused:
		return

	hour += 1
	if hour >= 24:
		hour = 0
		day += 1
		_on_new_day()

	var is_rest_period := hour >= 22 or hour < 6
	for colonist in colonists:
		if not colonist.alive:
			continue
		colonist.advance_hour(is_rest_period, ambient_temperature)
		_satisfy_needs(colonist)

	scheduler.advance_hour(colonists, navigation)
	_deliver_pending_outputs()
	time_changed.emit(day, hour)
	colony_changed.emit()
	_check_colony_alerts()


func set_paused(value: bool) -> void:
	paused = value
	colony_changed.emit()


func switch_level() -> void:
	active_level = (active_level + 1) % LEVEL_COUNT
	colony_changed.emit()


func add_resource(resource: StringName, quantity: int) -> int:
	var accepted := inventory.add_resource(resource, quantity)
	if accepted < quantity:
		alert_raised.emit("El almacén no tiene capacidad suficiente.", ALERT_WARNING)
	colony_changed.emit()
	return accepted


func queue_work(work_type: StringName, priority: int = 3) -> bool:
	if not resource_nodes.has(work_type):
		return false

	var node: ColonyResourceNode = resource_nodes[work_type]
	if not node.reserve(node.output_per_batch):
		alert_raised.emit("No quedan recursos disponibles en esta fuente.", ALERT_WARNING)
		return false

	scheduler.queue_order(work_type, node.level, node.cell, priority, node.work_hours_per_batch, node.resource, node.output_per_batch)
	colony_changed.emit()
	return true


func queue_excavation(cell: Vector2i, priority: int = 3) -> bool:
	if cell.y != active_level or not navigation.can_dig(cell):
		return false
	for order in scheduler.orders:
		if order.work_type == &"dig" and order.target_cell == cell:
			if order.state == ColonyWorkOrder.State.AVAILABLE or order.state == ColonyWorkOrder.State.IN_PROGRESS:
				return false
	scheduler.queue_order(&"dig", cell.y, cell, priority, 3.0, &"", 0)
	colony_changed.emit()
	return true


func get_resource_nodes_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for resource in resource_nodes:
		var node: ColonyResourceNode = resource_nodes[resource]
		result[String(resource)] = node.get_snapshot()
	return result


func get_living_colonist_count() -> int:
	var count := 0
	for colonist in colonists:
		if colonist.alive:
			count += 1
	return count


func get_snapshot() -> Dictionary:
	var people: Array[Dictionary] = []
	for colonist in colonists:
		people.append(colonist.get_snapshot())

	return {
		"day": day,
		"hour": hour,
		"active_level": active_level,
		"paused": paused,
		"ambient_temperature": ambient_temperature,
		"inventory": inventory.get_snapshot(),
		"resource_nodes": get_resource_nodes_snapshot(),
		"colonists": people,
		"active_work_orders": scheduler.get_active_orders_snapshot(),
		"pending_outputs": _pending_outputs.duplicate(true),
		"diggable_cells": navigation.get_diggable_cells()
	}


func _satisfy_needs(colonist: DwarfColonist) -> void:
	if colonist.thirst >= 55.0 and inventory.remove_resource(&"water", 1):
		colonist.drink()
	if colonist.hunger >= 55.0 and inventory.remove_resource(&"food", 1):
		colonist.eat()


func _on_new_day() -> void:
	for node in resource_nodes.values():
		node.regenerate()
	alert_raised.emit("Ha comenzado el día %d. Las fuentes renovables se han recuperado." % day, ALERT_INFO)


func _on_task_completed(_task_id: StringName, resource: StringName, amount: int) -> void:
	if resource == &"" or amount <= 0:
		colony_changed.emit()
		return
	var accepted := inventory.add_resource(resource, amount)
	if accepted < amount:
		_pending_outputs.append({
			"resource": resource,
			"amount": amount - accepted
		})
		alert_raised.emit("Almacén lleno: hay producción pendiente de almacenar.", ALERT_WARNING)
	colony_changed.emit()


func _on_terrain_excavated(_cell: Vector2i) -> void:
	colony_changed.emit()


func _deliver_pending_outputs() -> void:
	for i in range(_pending_outputs.size() - 1, -1, -1):
		var pending: Dictionary = _pending_outputs[i]
		var accepted := inventory.add_resource(pending["resource"], int(pending["amount"]))
		pending["amount"] = int(pending["amount"]) - accepted
		if int(pending["amount"]) <= 0:
			_pending_outputs.remove_at(i)
		else:
			_pending_outputs[i] = pending


func _check_colony_alerts() -> void:
	var living := get_living_colonist_count()
	var food := inventory.get_amount(&"food")
	var water := inventory.get_amount(&"water")
	var alert_key := ""
	var alert_message := ""
	var severity := ALERT_INFO

	if living == 0:
		alert_key = "colony_lost"
		alert_message = "La colonia ha perdido a todos sus habitantes."
		severity = ALERT_CRITICAL
	elif food <= living * 2:
		alert_key = "food_critical"
		alert_message = "Reservas de comida críticas: quedan %d unidades." % food
		severity = ALERT_CRITICAL
	elif water <= living * 2:
		alert_key = "water_critical"
		alert_message = "Reservas de agua críticas: quedan %d unidades." % water
		severity = ALERT_CRITICAL

	if alert_key != _last_alert_key:
		_last_alert_key = alert_key
		if not alert_key.is_empty():
			alert_raised.emit(alert_message, severity)
