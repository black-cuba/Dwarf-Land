class_name DwarfColonist
extends RefCounted

const NEED_MAX := 100.0
const CRITICAL_NEED := 90.0

var id: StringName
var display_name: String
var profession: String
var hunger := 15.0
var thirst := 12.0
var fatigue := 10.0
var health := 100.0
var body_temperature := 37.0
var alive := true
var current_level := 0


func _init(p_id: StringName, p_display_name: String, p_profession: String) -> void:
	id = p_id
	display_name = p_display_name
	profession = p_profession


func advance_hour(is_rest_period: bool, ambient_temperature: float) -> void:
	if not alive:
		return

	hunger = minf(NEED_MAX, hunger + 1.15)
	thirst = minf(NEED_MAX, thirst + 1.65)

	if is_rest_period:
		fatigue = maxf(0.0, fatigue - 7.0)
	elif fatigue >= 85.0:
		fatigue = maxf(0.0, fatigue - 4.0)
	else:
		fatigue = minf(NEED_MAX, fatigue + 1.0)

	_update_temperature(ambient_temperature)
	_update_health()


func get_work_speed(work_type: StringName) -> float:
	match profession:
		"Recolector":
			if work_type == &"food" or work_type == &"water" or work_type == &"wood":
				return 1.25
		"Agricultora":
			if work_type == &"food":
				return 1.4
			if work_type == &"water":
				return 1.1
		"Minero":
			if work_type == &"stone" or work_type == &"ore":
				return 1.4
	return 1.0


func eat() -> void:
	hunger = maxf(0.0, hunger - 42.0)


func drink() -> void:
	thirst = maxf(0.0, thirst - 48.0)


func rest(hours: float = 2.0) -> void:
	fatigue = maxf(0.0, fatigue - 12.0 * hours)


func take_damage(amount: float) -> void:
	if amount <= 0.0 or not alive:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		alive = false


func get_condition() -> String:
	if not alive:
		return "Fallecido"
	if health < 30.0:
		return "Grave"
	if hunger >= CRITICAL_NEED or thirst >= CRITICAL_NEED:
		return "Crítico"
	if fatigue >= 85.0:
		return "Agotado"
	if hunger >= 70.0 or thirst >= 70.0:
		return "Necesita suministros"
	return "Estable"


func get_snapshot() -> Dictionary:
	return {
		"id": String(id),
		"name": display_name,
		"profession": profession,
		"hunger": hunger,
		"thirst": thirst,
		"fatigue": fatigue,
		"health": health,
		"body_temperature": body_temperature,
		"alive": alive,
		"current_level": current_level,
		"condition": get_condition()
	}


func _update_temperature(ambient_temperature: float) -> void:
	# A simple first-pass thermal model. Clothing and room insulation
	# will modify this in the environmental simulation milestone.
	var target_temperature := 37.0
	if ambient_temperature < 16.0:
		target_temperature -= (16.0 - ambient_temperature) * 0.25
	elif ambient_temperature > 26.0:
		target_temperature += (ambient_temperature - 26.0) * 0.18

	body_temperature = move_toward(body_temperature, target_temperature, 0.04)
	if body_temperature < 35.5 or body_temperature > 38.5:
		take_damage(0.15)


func _update_health() -> void:
	if hunger >= CRITICAL_NEED:
		take_damage(0.35)
	if thirst >= CRITICAL_NEED:
		take_damage(0.55)
	if fatigue >= 98.0:
		take_damage(0.1)
