class_name ColonySimulation
extends RefCounted

signal time_changed(day: int, hour: int)
signal colony_changed
signal alert_raised(message: String, severity: int)

const LEVEL_COUNT := 2
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
var colonists: Array[DwarfColonist] = []
var _pending_outputs: Array[Dictionary] = []
var _last_alert_key := ""


func _init() -> void:
	scheduler.task_completed.connect(_on_task_completed)
	colonists.append(DwarfColonist.new(&"dwarf_001", "Borin", "Recolector"))
	colonists.append(DwarfColonist.new(&"dwarf_002", "Dora", "Agricultora"))
	colonists.append(DwarfColonist.new(&"dwarf_003", "Krag", "Minero"))


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

	scheduler.advance_hour(colonists)
	_deliver_pending_outputs()
	time_changed.emit(day, hour)
	colony_changed.emit()
	_check_colony_alerts()


func set_paused(value: bool) -> void:
	paused = value
	colony_changed.emit()


func switch_level() -> void:
	active_level = 1 - active_level
	colony_changed.emit()


func add_resource(resource: StringName, quantity: int) -> int:
	var accepted := inventory.add_resource(resource, quantity)
	if accepted < quantity:
		alert_raised.emit("El almacén no tiene capacidad suficiente.", ALERT_WARNING)
	colony_changed.emit()
	return accepted


func queue_work(work_type: StringName, priority: int = 3) -> bool:
	var order_data: Dictionary
	match work_type:
		&"food":
			order_data = {"level": 0, "hours": 4.0, "resource": &"food", "amount": 6}
		&"water":
			order_data = {"level": 0, "hours": 3.0, "resource": &"water", "amount": 8}
		&"wood":
			order_data = {"level": 0, "hours": 5.0, "resource": &"wood", "amount": 6}
		&"stone":
			order_data = {"level": 1, "hours": 5.0, "resource": &"stone", "amount": 5}
		&"ore":
			order_data = {"level": 1, "hours": 6.0, "resource": &"ore", "amount": 3}
		_:
			return false

	scheduler.queue_order(
		work_type,
		int(order_data["level"]),
		priority,
		float(order_data["hours"]),
		order_data["resource"],
		int(order_data["amount"])
	)
	colony_changed.emit()
	return true


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
		"colonists": people,
		"active_work_orders": scheduler.get_active_orders_snapshot(),
		"pending_outputs": _pending_outputs.duplicate(true)
	}


func _satisfy_needs(colonist: DwarfColonist) -> void:
	if colonist.thirst >= 55.0 and inventory.remove_resource(&"water", 1):
		colonist.drink()
	if colonist.hunger >= 55.0 and inventory.remove_resource(&"food", 1):
		colonist.eat()


func _on_new_day() -> void:
	alert_raised.emit("Ha comenzado el día %d." % day, ALERT_INFO)


func _on_task_completed(_task_id: StringName, resource: StringName, amount: int) -> void:
	var accepted := inventory.add_resource(resource, amount)
	if accepted < amount:
		_pending_outputs.append({
			"resource": resource,
			"amount": amount - accepted
		})
		alert_raised.emit("Almacén lleno: hay producción pendiente de almacenar.", ALERT_WARNING)
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
