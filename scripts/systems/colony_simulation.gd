class_name ColonySimulation
extends RefCounted

signal time_changed(day: int, hour: int)
signal colony_changed
signal alert_raised(message: String, severity: int)

const LEVEL_COUNT := 3
const ALERT_INFO := 0
const ALERT_WARNING := 1
const ALERT_CRITICAL := 2

var world_seed := 20261122
var game_mode: StringName = &"survival"
var day := 1
var hour := 7
var active_level := 0
var paused := false
var ambient_temperature := 18.0

var inventory := ColonyInventory.new()
var scheduler := ColonyWorkScheduler.new()
var save_system := ColonySaveSystem.new()
var event_random := RandomNumberGenerator.new()
var crop_field := ColonyCropField.new()
var navigation := ColonyNavigationGrid.new()
var colonists: Array[DwarfColonist] = []
var resource_nodes: Dictionary = {}
var structures: Array[Dictionary] = []
var tool_durability := 100.0
var _reserved_tool_orders: Dictionary = {}
var _pending_outputs: Array[Dictionary] = []
var _last_alert_key := ""
var _bed_assignments: Dictionary = {}


func _init() -> void:
	scheduler.task_completed.connect(_on_task_completed)
	scheduler.terrain_excavated.connect(_on_terrain_excavated)
	scheduler.map_terrain_excavated.connect(_on_map_terrain_excavated)
	scheduler.map_structure_built.connect(_on_map_structure_built)
	scheduler.crop_planted.connect(_on_crop_planted)
	scheduler.structure_built.connect(_on_structure_built)
	scheduler.task_cancelled.connect(_on_task_cancelled)
	world_seed = int(Time.get_ticks_usec())
	var generated_world := ColonyWorldGenerator.new(world_seed).generate()
	event_random.seed = world_seed + 9103
	resource_nodes = generated_world["resources"]
	for cell in generated_world["diggable_cells"]:
		navigation.set_diggable(cell)
	for map_cell in generated_world.get("map_diggable_cells", []):
		navigation.set_map_diggable(map_cell)
	var borin := DwarfColonist.new(&"dwarf_001", "Borin", "Recolector")
	borin.current_position = Vector2i(7, 0)
	colonists.append(borin)
	var dora := DwarfColonist.new(&"dwarf_002", "Dora", "Agricultora")
	dora.current_position = Vector2i(16, 0)
	colonists.append(dora)
	var krag := DwarfColonist.new(&"dwarf_003", "Krag", "Minero")
	krag.current_position = Vector2i(25, 2)
	colonists.append(krag)
	for colonist in colonists:
		colonist.sync_map_position_from_legacy()



func update_frame(delta: float) -> bool:
	if paused or delta <= 0.0:
		return false
	var moved := false
	for colonist in colonists:
		if colonist.alive:
			if colonist.is_map_moving:
				if colonist.advance_map_movement(delta):
					moved = true
			elif colonist.advance_movement(delta):
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

	var is_rest_period := game_mode != &"sandbox" and (hour >= 22 or hour < 6)
	for colonist in colonists:
		if not colonist.alive:
			_bed_assignments.erase(colonist.id)
			continue
		if game_mode == &"sandbox":
			colonist.is_resting = false
			colonist.is_sleeping = false
		else:
			_update_rest(colonist, is_rest_period)
		colonist.advance_hour(is_rest_period, get_local_temperature(colonist), game_mode == &"sandbox")
		if game_mode != &"sandbox":
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
	var uses_tool := work_type == &"stone" or work_type == &"ore" or work_type == &"coal" or work_type == &"clay"
	if uses_tool and not inventory.has_amount(&"tools", 1):
		alert_raised.emit("No hay herramientas disponibles para la extracción.", ALERT_WARNING)
		return false
	if not node.reserve(node.output_per_batch):
		alert_raised.emit("No quedan recursos disponibles en esta fuente.", ALERT_WARNING)
		return false
	if uses_tool:
		inventory.remove_resource(&"tools", 1)

	var order_id := scheduler.queue_order(work_type, node.level, node.cell, priority, node.work_hours_per_batch, node.resource, node.output_per_batch)
	if uses_tool:
		_reserved_tool_orders[order_id] = _get_tool_wear(work_type)
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



func queue_map_excavation(cell: Vector3i, priority: int = 3) -> bool:
	if cell.z != active_level or not navigation.can_dig_map_cell(cell):
		return false
	for order in scheduler.orders:
		if order.work_type == &"map_dig" and order.target_map_cell == cell:
			if order.state == ColonyWorkOrder.State.AVAILABLE or order.state == ColonyWorkOrder.State.IN_PROGRESS:
				return false
	var order_id := scheduler.queue_map_excavation(cell, priority)
	if order_id == &"":
		return false
	colony_changed.emit()
	return true


func queue_map_construction(structure_type: StringName, cell: Vector3i, priority: int = 3) -> bool:
	if not navigation.is_map_cell_inside(cell) or cell.z != active_level or not navigation.is_map_walkable(cell):
		return false
	if cell == crop_field.map_cell:
		return false
	if get_bed_map_cells().has(cell):
		return false
	for node in resource_nodes.values():
		var node_cell: Vector3i = node.map_cell
		if node_cell == cell:
			return false
	for structure in structures:
		var existing: Vector3i = structure.get("map_cell", Vector3i(int(structure.get("cell", Vector2i.ZERO).x), ColonyNavigationGrid.ELEVATOR_ROW, int(structure.get("level", 0))))
		if existing == cell:
			return false
	for order in scheduler.orders:
		if order.work_type == &"map_build" and order.target_map_cell == cell and (order.state == ColonyWorkOrder.State.AVAILABLE or order.state == ColonyWorkOrder.State.IN_PROGRESS):
			return false

	var wood_cost := 0
	var stone_cost := 0
	var required_work := 1.0
	match structure_type:
		&"bed":
			wood_cost = 3
			required_work = 2.0
			if cell.z != 1:
				return false
		&"storage":
			wood_cost = 8
			stone_cost = 4
			required_work = 4.0
		&"workshop":
			wood_cost = 6
			stone_cost = 6
			required_work = 5.0
		_:
			return false
	if not inventory.has_amount(&"wood", wood_cost) or not inventory.has_amount(&"stone", stone_cost):
		return false
	inventory.remove_resource(&"wood", wood_cost)
	inventory.remove_resource(&"stone", stone_cost)
	if scheduler.queue_map_construction(cell, structure_type, priority, required_work) == &"":
		inventory.add_resource(&"wood", wood_cost)
		inventory.add_resource(&"stone", stone_cost)
		return false
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



func queue_construction(structure_type: StringName, cell: Vector2i, priority: int = 3) -> bool:
	if cell.y != active_level or not navigation.is_walkable(cell):
		return false
	if crop_field.cell == cell:
		return false
	for node in resource_nodes.values():
		if node.cell == cell:
			return false
	if structure_type == &"bed" and get_bed_cells().has(cell):
		return false
	var wood_cost := 0
	var stone_cost := 0
	var required_work := 1.0
	match structure_type:
		&"bed":
			wood_cost = 3
			required_work = 2.0
			if cell.y != 1:
				return false
		&"storage":
			wood_cost = 8
			stone_cost = 4
			required_work = 4.0
		&"workshop":
			wood_cost = 6
			stone_cost = 6
			required_work = 5.0
		_:
			return false

	for structure in structures:
		if structure.get("cell", Vector2i(-1, -1)) == cell:
			return false
	for order in scheduler.orders:
		if order.work_type == &"build" and order.target_cell == cell:
			if order.state == ColonyWorkOrder.State.AVAILABLE or order.state == ColonyWorkOrder.State.IN_PROGRESS:
				return false
	if not inventory.has_amount(&"wood", wood_cost) or not inventory.has_amount(&"stone", stone_cost):
		return false
	inventory.remove_resource(&"wood", wood_cost)
	inventory.remove_resource(&"stone", stone_cost)
	scheduler.queue_order(&"build", cell.y, cell, priority, required_work, structure_type, 0)
	colony_changed.emit()
	return true




func set_game_mode(mode: StringName) -> bool:
	if not [&"campaign", &"survival", &"sandbox"].has(mode):
		return false
	game_mode = mode
	if game_mode == &"sandbox":
		for colonist in colonists:
			colonist.is_resting = false
			colonist.is_sleeping = false
	colony_changed.emit()
	return true


func get_game_mode_label() -> String:
	match game_mode:
		&"campaign":
			return "Campaña"
		&"sandbox":
			return "Sandbox"
	return "Supervivencia"


func get_campaign_progress() -> Dictionary:
	var has_storage := false
	for structure in structures:
		if StringName(structure.get("type", "")) == &"storage":
			has_storage = true
	var workshop_ready := has_workshop()
	var survived_ten_days := day >= 10
	return {
		"storage_built": has_storage,
		"workshop_built": workshop_ready,
		"day_ten_reached": survived_ten_days,
		"complete": has_storage and workshop_ready and survived_ten_days
	}


func has_workshop() -> bool:
	for structure in structures:
		if StringName(structure.get("type", "")) == &"workshop":
			return true
	return false


func queue_crafting(recipe: StringName, priority: int = 3) -> bool:
	if not has_workshop() or recipe != &"tool":
		return false
	var workshop_cell := Vector2i(-1, -1)
	for structure in structures:
		if StringName(structure.get("type", "")) == &"workshop":
			workshop_cell = structure.get("cell", Vector2i(-1, -1))
			break
	if workshop_cell.x < 0:
		return false
	if not inventory.has_amount(&"wood", 2) or not inventory.has_amount(&"ore", 1):
		return false
	inventory.remove_resource(&"wood", 2)
	inventory.remove_resource(&"ore", 1)
	scheduler.queue_order(&"craft", workshop_cell.y, workshop_cell, priority, 3.0, &"tools", 1)
	colony_changed.emit()
	return true


func get_bed_map_cells() -> Array[Vector3i]:
	var result: Array[Vector3i] = [
		Vector3i(7, ColonyNavigationGrid.ELEVATOR_ROW, 1),
		Vector3i(8, ColonyNavigationGrid.ELEVATOR_ROW, 1),
		Vector3i(9, ColonyNavigationGrid.ELEVATOR_ROW, 1)
	]
	for structure in structures:
		if StringName(structure.get("type", "")) != &"bed":
			continue
		var map_cell: Vector3i = structure.get("map_cell", Vector3i(int(structure.get("cell", Vector2i.ZERO).x), ColonyNavigationGrid.ELEVATOR_ROW, int(structure.get("level", 1))))
		if not result.has(map_cell):
			result.append(map_cell)
	return result


func get_bed_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = [Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1)]
	for structure in structures:
		if StringName(structure.get("type", "")) == &"bed":
			var cell: Vector2i = structure.get("cell", Vector2i(-1, -1))
			if not result.has(cell):
				result.append(cell)
	return result


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
		"world_seed": world_seed,
		"game_mode": String(game_mode),
		"event_random_state": event_random.state,
		"day": day,
		"hour": hour,
		"active_level": active_level,
		"paused": paused,
		"ambient_temperature": ambient_temperature,
		"inventory": {"capacity": inventory.capacity, "amounts": inventory.get_snapshot()},
		"resource_nodes": get_resource_nodes_snapshot(),
		"crop_field": crop_field.get_snapshot(),
		"structures": structures.duplicate(true),
		"tool_durability": tool_durability,
		"reserved_tool_orders": _reserved_tool_orders.duplicate(true),
		"colonists": people,
		"active_work_orders": scheduler.get_active_orders_snapshot(),
		"pending_outputs": _pending_outputs.duplicate(true),
		"diggable_cells": navigation.get_diggable_cells(),
		"map_diggable_cells": navigation.diggable_map_cells.keys()
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

	world_seed = int(snapshot.get("world_seed", world_seed))
	game_mode = StringName(snapshot.get("game_mode", "survival"))
	event_random.state = int(snapshot.get("event_random_state", world_seed + 9103))
	if not [StringName("campaign"), StringName("survival"), StringName("sandbox")].has(game_mode):
		game_mode = &"survival"
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
		colonist.illness_severity = clampf(float(item.get("illness_severity", 0.0)), 0.0, 100.0)
		colonist.injury_severity = clampf(float(item.get("injury_severity", 0.0)), 0.0, 100.0)
		colonist.body_temperature = float(item.get("body_temperature", 37.0))
		colonist.alive = bool(item.get("alive", true))
		var position: Variant = item.get("current_position", Vector2i(7, 0))
		if typeof(position) != TYPE_VECTOR2I:
			return false
		colonist.current_position = Vector2i(position.x, clampi(position.y, 0, LEVEL_COUNT - 1))
		colonist.current_level = colonist.current_position.y
		colonist.visual_position = Vector2(colonist.current_position)
		colonist.movement_target = colonist.current_position
		var saved_map_position: Variant = item.get("map_position", Vector3i(colonist.current_position.x, ColonyNavigationGrid.ELEVATOR_ROW, colonist.current_position.y))
		if typeof(saved_map_position) == TYPE_VECTOR3I and navigation.is_map_cell_inside(saved_map_position):
			colonist.map_position = saved_map_position
		else:
			colonist.sync_map_position_from_legacy()
		colonist.map_visual_position = Vector2(colonist.map_position.x, colonist.map_position.y)
		colonist.map_movement_target = colonist.map_position
		colonist.is_map_moving = false
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
		node.level = clampi(int(resource_data[key].get("level", node.level)), 0, LEVEL_COUNT - 1)
		var saved_cell: Variant = resource_data[key].get("cell", node.cell)
		if typeof(saved_cell) == TYPE_VECTOR2I:
			node.cell = saved_cell
		var saved_map_cell: Variant = resource_data[key].get("map_cell", node.map_cell)
		if typeof(saved_map_cell) == TYPE_VECTOR3I and navigation.is_map_cell_inside(saved_map_cell):
			node.map_cell = saved_map_cell

	navigation.clear_terrain()
	structures.clear()
	var structure_data: Variant = snapshot.get("structures", [])
	if typeof(structure_data) != TYPE_ARRAY:
		return false
	for item in structure_data:
		if typeof(item) != TYPE_DICTIONARY or typeof(item.get("cell")) != TYPE_VECTOR2I:
			return false
		var restored_structure := item.duplicate(true)
		structures.append(restored_structure)

	var terrain_data: Variant = snapshot.get("diggable_cells", [])
	if typeof(terrain_data) != TYPE_ARRAY:
		return false
	for cell in terrain_data:
		if typeof(cell) == TYPE_VECTOR2I:
			navigation.set_diggable(cell)
	var map_terrain_data: Variant = snapshot.get("map_diggable_cells", [])
	if typeof(map_terrain_data) != TYPE_ARRAY:
		return false
	for map_cell in map_terrain_data:
		if typeof(map_cell) == TYPE_VECTOR3I:
			navigation.set_map_diggable(map_cell)
	for structure in structures:
		if StringName(structure.get("type", "")) == &"bed":
			continue
		var map_cell: Vector3i = structure.get("map_cell", Vector3i(int(structure.get("cell", Vector2i.ZERO).x), ColonyNavigationGrid.ELEVATOR_ROW, int(structure.get("level", 0))))
		navigation.set_map_blocked(map_cell, true)

	var orders_data: Variant = snapshot.get("active_work_orders", [])
	if typeof(orders_data) != TYPE_ARRAY or not scheduler.restore_active_orders(orders_data):
		return false
	tool_durability = clampf(float(snapshot.get("tool_durability", 100.0)), 0.0, 100.0)
	var reserved_tools: Variant = snapshot.get("reserved_tool_orders", {})
	if typeof(reserved_tools) != TYPE_DICTIONARY:
		return false
	_reserved_tool_orders.clear()
	for order_id in reserved_tools:
		_reserved_tool_orders[StringName(order_id)] = float(reserved_tools[order_id])
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




func get_local_temperature(colonist: DwarfColonist) -> float:
	var layer_offsets := [4.0, 0.0, -7.0]
	var level := clampi(colonist.current_position.y, 0, LEVEL_COUNT - 1)
	var daylight_offset := 3.0 if hour >= 9 and hour < 18 else -2.0
	var shelter_bonus := 4.0 if colonist.is_sleeping else 0.0
	return ambient_temperature + layer_offsets[level] + daylight_offset + shelter_bonus


func _update_rest(colonist: DwarfColonist, rest_period: bool) -> void:
	if not rest_period:
		if colonist.is_resting and (colonist.is_moving or colonist.is_map_moving):
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

	var bed: Vector3i = _bed_assignments[colonist.id]
	var bed_map_cell := bed
	if colonist.map_position == bed_map_cell and not colonist.is_map_moving:
		colonist.is_sleeping = true
		return

	colonist.is_sleeping = false
	if colonist.is_map_moving:
		return
	var path := navigation.find_map_path(colonist.map_position, bed_map_cell)
	if not path.is_empty():
		colonist.start_map_movement(path[mini(4, path.size()) - 1])


func _assign_bed(colonist: DwarfColonist) -> void:
	var beds := get_bed_map_cells()
	var occupied: Array = _bed_assignments.values()
	var best_bed := Vector3i(-1, -1, -1)
	var best_distance := 2147483647
	for bed in beds:
		if occupied.has(bed) or not navigation.is_map_walkable(bed):
			continue
		var distance := 0
		if colonist.map_position != bed:
			var path := navigation.find_map_path(colonist.map_position, bed)
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
	if game_mode != &"sandbox" and not colonists.is_empty() and event_random.randf() < 0.03:
		var affected_index := event_random.randi_range(0, colonists.size() - 1)
		var affected: DwarfColonist = colonists[affected_index]
		if affected.alive:
			affected.apply_illness(20.0)
			alert_raised.emit("%s ha contraído una enfermedad. Necesita descanso y condiciones estables." % affected.display_name, ALERT_WARNING)
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



func _get_tool_wear(work_type: StringName) -> float:
	match work_type:
		&"stone":
			return 20.0
		&"ore":
			return 25.0
		&"coal":
			return 15.0
		&"clay":
			return 10.0
	return 0.0


func _complete_reserved_tool(task_id: StringName) -> void:
	if not _reserved_tool_orders.has(task_id):
		return
	tool_durability -= float(_reserved_tool_orders[task_id])
	_reserved_tool_orders.erase(task_id)
	if tool_durability <= 0.0:
		tool_durability = 100.0
		alert_raised.emit("Una herramienta se ha roto durante la extracción.", ALERT_WARNING)
		if game_mode != &"sandbox" and event_random.randf() < 0.15:
			for colonist in colonists:
				if colonist.alive and colonist.profession == "Minero":
					colonist.apply_injury(30.0)
					alert_raised.emit("%s sufrió un accidente durante la extracción." % colonist.display_name, ALERT_WARNING)
					break
	else:
		inventory.add_resource(&"tools", 1)


func _on_task_cancelled(task_id: StringName) -> void:
	if _reserved_tool_orders.has(task_id):
		_reserved_tool_orders.erase(task_id)
		inventory.add_resource(&"tools", 1)
	colony_changed.emit()


func _on_task_completed(task_id: StringName, resource: StringName, amount: int) -> void:
	_complete_reserved_tool(task_id)
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


func _on_map_terrain_excavated(_cell: Vector3i) -> void:
	colony_changed.emit()


func _on_map_structure_built(cell: Vector3i, structure_type: StringName) -> void:
	var structure_id := "structure_%04d" % (structures.size() + 1)
	structures.append({
		"id": structure_id,
		"type": String(structure_type),
		"cell": Vector2i(cell.x, cell.z),
		"map_cell": cell,
		"level": cell.z
	})
	if structure_type == &"storage":
		inventory.capacity += 60
	colony_changed.emit()


func _on_crop_planted(_cell: Vector2i) -> void:
	crop_field.plant()
	colony_changed.emit()



func _on_structure_built(cell: Vector2i, structure_type: StringName) -> void:
	var structure_id := "structure_%04d" % (structures.size() + 1)
	structures.append({
		"id": structure_id,
		"type": String(structure_type),
		"cell": cell,
		"level": cell.y
	})
	if structure_type == &"storage":
		inventory.capacity += 60
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
	if game_mode == &"sandbox":
		_last_alert_key = ""
		return
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
	else:
		for colonist in colonists:
			if not colonist.alive:
				continue
			if colonist.body_temperature < 35.5:
				alert_key = "cold_exposure"
				alert_message = "%s está sufriendo hipotermia." % colonist.display_name
				severity = ALERT_WARNING
				break
			if colonist.body_temperature > 38.5:
				alert_key = "heat_exposure"
				alert_message = "%s está sufriendo estrés térmico." % colonist.display_name
				severity = ALERT_WARNING
				break
			if colonist.illness_severity >= 40.0:
				alert_key = "illness"
				alert_message = "%s está enfermo y necesita recuperarse." % colonist.display_name
				severity = ALERT_WARNING
				break
			if colonist.injury_severity >= 30.0:
				alert_key = "injury"
				alert_message = "%s está herido y necesita descanso." % colonist.display_name
				severity = ALERT_WARNING
				break

	if alert_key != _last_alert_key:
		_last_alert_key = alert_key
		if not alert_key.is_empty():
			alert_raised.emit(alert_message, severity)
