class_name ColonyCropField
extends RefCounted

const DAYS_TO_MATURE := 4
const HARVEST_PER_CYCLE := 24
const MAX_MOISTURE := 100

var cell := Vector2i(11, 0)
var is_planted := true
var is_ready := true
var growth_days := DAYS_TO_MATURE
var moisture := 70
var harvestable_units := HARVEST_PER_CYCLE


func advance_day(watered: bool) -> int:
	if not is_planted or is_ready:
		return 0
	if watered:
		moisture = mini(MAX_MOISTURE, moisture + 25)
	else:
		moisture = maxi(0, moisture - 20)
	if moisture < 20:
		return 0
	growth_days = mini(DAYS_TO_MATURE, growth_days + 1)
	if growth_days >= DAYS_TO_MATURE:
		is_ready = true
		harvestable_units = HARVEST_PER_CYCLE
		return harvestable_units
	return 0


func harvest(quantity: int) -> int:
	if not is_ready or quantity <= 0:
		return 0
	var accepted := mini(quantity, harvestable_units)
	harvestable_units -= accepted
	if harvestable_units <= 0:
		is_planted = false
		is_ready = false
		growth_days = 0
	return accepted


func plant() -> bool:
	if is_planted:
		return false
	is_planted = true
	is_ready = false
	growth_days = 0
	moisture = 70
	harvestable_units = 0
	return true


func get_snapshot() -> Dictionary:
	return {
		"cell": cell,
		"is_planted": is_planted,
		"is_ready": is_ready,
		"growth_days": growth_days,
		"moisture": moisture,
		"harvestable_units": harvestable_units
	}


func restore(snapshot: Dictionary) -> bool:
	var restored_cell: Variant = snapshot.get("cell", cell)
	if typeof(restored_cell) != TYPE_VECTOR2I:
		return false
	cell = restored_cell
	is_planted = bool(snapshot.get("is_planted", false))
	is_ready = bool(snapshot.get("is_ready", false))
	growth_days = clampi(int(snapshot.get("growth_days", 0)), 0, DAYS_TO_MATURE)
	moisture = clampi(int(snapshot.get("moisture", 0)), 0, MAX_MOISTURE)
	harvestable_units = clampi(int(snapshot.get("harvestable_units", 0)), 0, HARVEST_PER_CYCLE)
	if is_ready and (not is_planted or harvestable_units <= 0):
		return false
	return true
