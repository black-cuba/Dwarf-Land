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
var colonists: Array[DwarfColonist] = []


func _init() -> void:
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
		"colonists": people
	}


func _satisfy_needs(colonist: DwarfColonist) -> void:
	if colonist.thirst >= 55.0 and inventory.remove_resource(&"water", 1):
		colonist.drink()
	if colonist.hunger >= 55.0 and inventory.remove_resource(&"food", 1):
		colonist.eat()


func _on_new_day() -> void:
	alert_raised.emit("Ha comenzado el día %d." % day, ALERT_INFO)


func _check_colony_alerts() -> void:
	var living := get_living_colonist_count()
	if living == 0:
		alert_raised.emit("La colonia ha perdido a todos sus habitantes.", ALERT_CRITICAL)
		return

	var food := inventory.get_amount(&"food")
	var water := inventory.get_amount(&"water")
	if food <= living * 2:
		alert_raised.emit("Reservas de comida críticas: quedan %d unidades." % food, ALERT_CRITICAL)
	elif water <= living * 2:
		alert_raised.emit("Reservas de agua críticas: quedan %d unidades." % water, ALERT_CRITICAL)
