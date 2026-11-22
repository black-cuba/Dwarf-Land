class_name ColonyResourceNode
extends RefCounted

var id: StringName
var resource: StringName
var level: int
var cell: Vector2i
var available_units: int
var maximum_units: int
var daily_regeneration: int
var work_hours_per_batch: float
var output_per_batch: int


func _init(
	p_id: StringName,
	p_resource: StringName,
	p_level: int,
	p_cell: Vector2i,
	p_available_units: int,
	p_maximum_units: int,
	p_daily_regeneration: int,
	p_work_hours_per_batch: float,
	p_output_per_batch: int
) -> void:
	id = p_id
	resource = p_resource
	level = clampi(p_level, 0, 1)
	cell = Vector2i(p_cell.x, level)
	maximum_units = maxi(0, p_maximum_units)
	available_units = clampi(p_available_units, 0, maximum_units)
	daily_regeneration = maxi(0, p_daily_regeneration)
	work_hours_per_batch = maxf(0.1, p_work_hours_per_batch)
	output_per_batch = maxi(1, p_output_per_batch)


func can_supply(quantity: int) -> bool:
	return quantity > 0 and available_units >= quantity


func reserve(quantity: int) -> bool:
	if not can_supply(quantity):
		return false
	available_units -= quantity
	return true


func regenerate() -> void:
	available_units = mini(maximum_units, available_units + daily_regeneration)


func get_snapshot() -> Dictionary:
	return {
		"id": String(id),
		"resource": String(resource),
		"level": level,
		"cell": cell,
		"available_units": available_units,
		"maximum_units": maximum_units,
		"daily_regeneration": daily_regeneration
	}
