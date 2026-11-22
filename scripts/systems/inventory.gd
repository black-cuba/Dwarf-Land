class_name ColonyInventory
extends RefCounted

signal inventory_changed(resource: StringName, new_amount: int)

const DEFAULT_CAPACITY := 240

var capacity := DEFAULT_CAPACITY
var _amounts: Dictionary = {}


func _init() -> void:
	_amounts = {
		&"food": 36,
		&"water": 48,
		&"wood": 24,
		&"stone": 16,
		&"ore": 0,
		&"tools": 3,
		&"materials": 0
	}


func get_amount(resource: StringName) -> int:
	return int(_amounts.get(resource, 0))


func has_amount(resource: StringName, quantity: int = 1) -> bool:
	return quantity >= 0 and get_amount(resource) >= quantity


func add_resource(resource: StringName, quantity: int) -> int:
	if quantity <= 0:
		return 0
	if not _amounts.has(resource):
		_amounts[resource] = 0

	var accepted := mini(quantity, get_free_capacity())
	if accepted <= 0:
		return 0

	_amounts[resource] = get_amount(resource) + accepted
	inventory_changed.emit(resource, get_amount(resource))
	return accepted


func remove_resource(resource: StringName, quantity: int) -> bool:
	if quantity < 0 or not has_amount(resource, quantity):
		return false
	if quantity == 0:
		return true

	_amounts[resource] = get_amount(resource) - quantity
	inventory_changed.emit(resource, get_amount(resource))
	return true


func get_total_amount() -> int:
	var total := 0
	for value in _amounts.values():
		total += int(value)
	return total


func get_free_capacity() -> int:
	return maxi(0, capacity - get_total_amount())


func get_snapshot() -> Dictionary:
	return _amounts.duplicate(true)


func restore(snapshot: Dictionary, new_capacity: int = DEFAULT_CAPACITY) -> bool:
	if new_capacity <= 0:
		return false

	var cleaned: Dictionary = {}
	var total := 0
	for key in snapshot:
		var amount := int(snapshot[key])
		if amount < 0:
			return false
		cleaned[StringName(key)] = amount
		total += amount

	if total > new_capacity:
		return false

	capacity = new_capacity
	_amounts = cleaned
	for resource in _amounts:
		inventory_changed.emit(resource, get_amount(resource))
	return true
