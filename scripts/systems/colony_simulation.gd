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
var save_system := ColonySaveSystem.new()
var crop_field := ColonyCropField.new()
var navigation := ColonyNavigationGrid.new()
var colonists: Array[DwarfColonist] = []
var resource_nodes: Dictionary = {}
var _pending_outputs: Array[Dictionary] = []
var _last_alert_key := ""
var _bed_assignments: Dictionary = {}


func _init() -> void:
	scheduler.task_completed.connect(_on_task_completed)
	scheduler.terrain_excavated.connect(_on_terrain_excavated)
	scheduler.crop_planted.connect(_on_crop_planted)
	# Initial geological obstacles. These cells must be excavated before passage.
	for cell in [Vector2i(5, 1), Vector2i(6, 1), Vector2i(20, 2), Vector2i(21, 2)]:
		navigation.set_diggable(cell)
	resource_nodes = {
		&"food": ColonyResourceNode.new(&"surface_crops", &"food", 0, Vector2i(11, 0), 24, 48, 0, 4.0, 6),
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



func update_frame(delta: float) -> bool:
	if paused or delta <= 0.0:
		return false
	var moved := false
	for colonist in colonists:
		if colonist.alive and colonist.advance_movement(delta):
			moved = true
	return moved


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
			_bed_assignments.erase(colonist.id)
			continue
		_update_rest(colonist, is_rest_period)
		colonist.advance_hour(is_rest_period, ambient_temperature)
		_satisfy_needs(colonist)

	scheduler.advance_hour(colonists, navigation)
	_deliver_pending_outputs()
	time_changed.emit(day, hour)
	colony_changed.emit()
	_check_colony_alerts()
	if hour % 6 == 0 and not save_game():
		alert_raised.emit("No se pudo guardar automáticamente la partida.", ALERT_WARNING)


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
	if work_type == &"food" and not crop_field.is_ready:
		return false
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



func queue_planting(priority: int = 3) -> bool:
	if active_level != 0 or crop_field.is_planted:
		return false
	for order in scheduler.orders:
		if order.work_type == &"plant" and (order.state == ColonyWorkOrder.State.AVAILABLE or order.state == ColonyWorkOrder.State.IN_PROGRESS):
			return false
	if not inventory.remove_resource(&"seeds", 1):
		return false
	scheduler.queue_order(&"plant", 0, crop_field.cell, priority, 2.0, &"", 0)
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
		"inventory": {"capacity": inventory.capacity, "amounts": inventory.get_snapshot()},
		"resource_nodes": get_resource_nodes_snapshot(),
		"crop_field": crop_field.get_snapshot(),
		"colonists": people,
		"active_work_orders": scheduler.get_active_orders_snapshot(),
		"pending_outputs": _pending_outputs.duplicate(true),
		"diggable_cells": navigation.get_diggable_cells()
	}



func save_game() -> bool:
	return save_system.save_snapshot(get_snapshot())


func load_game() -> bool:
	var result := save_system.load_snapshot()
	if not bool(result.get("success", false)):
		return false
	return restore_snapshot(result.get("data", {}))


func restore_snapshot(snapshot: Dictionary) -> bool:
	if not snapshot.has("day") or not snapshot.has("hour") or typeof(snapshot.get("inventory")) != TYPE_DICTIONARY:
		return false
	var inventory_data: Dictionary = snapshot["inventory"]
	if typeof(inventory_data.get("amounts")) != TYPE_DICTIONARY:
		return false
	if not inventory.restore(inventory_data["amounts"], int(inventory_data.get("capacity", ColonyInventory.DEFAULT_CAPACITY))):
		return false

	day = maxi(1, int(snapshot.get("day", 1)))
	hour = clampi(int(snapshot.get("hour", 7)), 0, 23)
	active_level = clampi(int(snapshot.get("active_level", 0)), 0, LEVEL_COUNT - 1)
	ambient_temperature = float(snapshot.get("ambient_temperature", 18.0))
	paused = false

	var restored_colonists: Array[DwarfColonist] = []
	var colonist_data: Variant = snapshot.get("colonists", [])
	if typeof(colonist_data) != TYPE_ARRAY:
		return false
	for item in colonist_data:
		if typeof(item) != TYPE_DICTIONARY:
			return false
		var colonist := DwarfColonist.new(
			StringName(item.get("id", "")),
			String(item.get("name", "Colono")),
			String(item.get("profession", "Generalista"))
		)
		colonist.hunger = clampf(float(item.get("hunger", 0.0)), 0.0, DwarfColonist.NEED_MAX)
		colonist.thirst = clampf(float(item.get("thirst", 0.0)), 0.0, DwarfColonist.NEED_MAX)
		colonist.fatigue = clampf(float(item.get("fatigue", 0.0)), 0.0, DwarfColonist.NEED_MAX)
		colonist.health = clampf(float(item.get("health", 100.0)), 0.0, 100.0)
		colonist.body_temperature = float(item.get("body_temperature", 37.0))
		colonist.alive = bool(item.get("alive", true))
		var position: Variant = item.get("current_position", Vector2i(7, 0))
		if typeof(position) != TYPE_VECTOR2I:
			return false
		colonist.current_position = Vector2i(position.x, clampi(position.y, 0, LEVEL_COUNT - 1))
		colonist.current_level = colonist.current_position.y
		colonist.visual_position = Vector2(colonist.current_position)
		colonist.movement_target = colonist.current_position
		colonist.is_resting = false
		colonist.is_sleeping = false
		restored_colonists.append(colonist)
	colonists = restored_colonists

	var crop_data: Variant = snapshot.get("crop_field", {})
	if typeof(crop_data) != TYPE_DICTIONARY or not crop_field.restore(crop_data):
		return false

	var resource_data: Variant = snapshot.get("resource_nodes", {})
	if typeof(resource_data) != TYPE_DICTIONARY:
		return false
	for key in resource_data:
		var resource_key := StringName(key)
		if not resource_nodes.has(resource_key) or typeof(resource_data[key]) != TYPE_DICTIONARY:
			continue
		var node: ColonyResourceNode = resource_nodes[resource_key]
		node.available_units = clampi(int(resource_data[key].get("available_units", node.available_units)), 0, node.maximum_units)

	navigation.clear_terrain()
	var terrain_data: Variant = snapshot.get("diggable_cells", [])
	if typeof(terrain_data) != TYPE_ARRAY:
		return false
	for cell in terrain_data:
		if typeof(cell) == TYPE_VECTOR2I:
			navigation.set_diggable(cell)

	var orders_data: Variant = snapshot.get("active_work_orders", [])
	if typeof(orders_data) != TYPE_ARRAY or not scheduler.restore_active_orders(orders_data):
		return false
	var pending_data: Variant = snapshot.get("pending_outputs", [])
	if typeof(pending_data) != TYPE_ARRAY:
		return false
	_pending_outputs.clear()
	for pending in pending_data:
		if typeof(pending) == TYPE_DICTIONARY:
			_pending_outputs.append(pending)
	_last_alert_key = ""
	colony_changed.emit()
	return true



func _update_rest(colonist: DwarfColonist, rest_period: bool) -> void:
	if not rest_period:
		if colonist.is_resting and colonist.is_moving:
			colonist.stop_movement()
		colonist.is_resting = false
		colonist.is_sleeping = false
		_bed_assignments.erase(colonist.id)
		return

	if not colonist.is_resting:
		colonist.stop_movement()
		scheduler.release_colonist(colonist.id)
	colonist.is_resting = true

	if not _bed_assignments.has(colonist.id):
		_assign_bed(colonist)
	if not _bed_assignments.has(colonist.id):
		colonist.is_sleeping = false
		return

	var bed: Vector2i = _bed_assignments[colonist.id]
	if colonist.current_position == bed and not colonist.is_moving:
		colonist.is_sleeping = true
		return

	colonist.is_sleeping = false
	if colonist.is_moving:
		return
	var path := navigation.find_path(colonist.current_position, bed)
	if not path.is_empty():
		colonist.start_movement(path[mini(4, path.size()) - 1])


func _assign_bed(colonist: DwarfColonist) -> void:
	var beds: Array[Vector2i] = [Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1)]
	var occupied: Array = _bed_assignments.values()
	var best_bed := Vector2i(-1, -1)
	var best_distance := 2147483647
	for bed in beds:
		if occupied.has(bed) or not navigation.is_walkable(bed):
			continue
		var distance := 0
		if colonist.current_position != bed:
			var path := navigation.find_path(colonist.current_position, bed)
			if path.is_empty():
				continue
			distance = path.size()
		if distance < best_distance:
			best_distance = distance
			best_bed = bed
	if best_bed.x >= 0:
		_bed_assignments[colonist.id] = best_bed


func _satisfy_needs(colonist: DwarfColonist) -> void:
	if colonist.thirst >= 55.0 and inventory.remove_resource(&"water", 1):
		colonist.drink()
	if colonist.hunger >= 55.0 and inventory.remove_resource(&"food", 1):
		colonist.eat()


func _on_new_day() -> void:
	for node in resource_nodes.values():
		node.regenerate()
	var watered := false
	if crop_field.is_planted and not crop_field.is_ready:
		watered = inventory.remove_resource(&"water", 1)
	var new_food := crop_field.advance_day(watered)
	if new_food > 0:
		var food_node: ColonyResourceNode = resource_nodes[&"food"]
		food_node.available_units = mini(food_node.maximum_units, food_node.available_units + new_food)
	alert_raised.emit("Ha comenzado el día %d. Los cultivos han avanzado su ciclo." % day, ALERT_INFO)


func _on_task_completed(_task_id: StringName, resource: StringName, amount: int) -> void:
	if resource == &"" or amount <= 0:
		colony_changed.emit()
		return
	if resource == &"food":
		crop_field.harvest(amount)
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


func _on_crop_planted(_cell: Vector2i) -> void:
	crop_field.plant()
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
