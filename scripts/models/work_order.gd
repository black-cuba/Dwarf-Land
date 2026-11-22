class_name ColonyWorkOrder
extends RefCounted

enum State {
	AVAILABLE,
	IN_PROGRESS,
	COMPLETED,
	CANCELLED
}

var id: StringName
var work_type: StringName
var level: int
var target_cell: Vector2i
var target_map_cell := Vector3i(-1, -1, -1)
var priority: int
var required_work: float
var progress := 0.0
var output_resource: StringName
var output_amount: int
var state := State.AVAILABLE
var assigned_colonist_id: StringName = &""


func _init(
	p_id: StringName,
	p_work_type: StringName,
	p_level: int,
	p_target_cell: Vector2i,
	p_priority: int,
	p_required_work: float,
	p_output_resource: StringName,
	p_output_amount: int
) -> void:
	id = p_id
	work_type = p_work_type
	level = clampi(p_level, 0, 2)
	target_cell = Vector2i(p_target_cell.x, level)
	priority = clampi(p_priority, 1, 5)
	required_work = maxf(0.1, p_required_work)
	output_resource = p_output_resource
	output_amount = maxi(0, p_output_amount)


func advance(work_amount: float) -> bool:
	if state != State.IN_PROGRESS or work_amount <= 0.0:
		return false

	progress = minf(required_work, progress + work_amount)
	if progress >= required_work:
		state = State.COMPLETED
		return true
	return false


func get_progress_ratio() -> float:
	return clampf(progress / required_work, 0.0, 1.0)


func get_snapshot() -> Dictionary:
	return {
		"id": String(id),
		"type": String(work_type),
		"level": level,
		"target_cell": target_cell,
		"target_map_cell": target_map_cell,
		"priority": priority,
		"required_work": required_work,
		"progress": progress,
		"progress_ratio": get_progress_ratio(),
		"output_resource": String(output_resource),
		"output_amount": output_amount,
		"state": state,
		"assigned_colonist_id": String(assigned_colonist_id)
	}
