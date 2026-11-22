class_name ColonyWorldGenerator
extends RefCounted

var world_seed: int
var random := RandomNumberGenerator.new()


func _init(p_world_seed: int) -> void:
	world_seed = p_world_seed
	random.seed = world_seed


func generate() -> Dictionary:
	var wood_x := random.randi_range(20, 30)
	var water_x := random.randi_range(18, 24)
	var clay_x := random.randi_range(8, 11)
	var ore_x := random.randi_range(22, 27)
	var coal_x := random.randi_range(28, 33)

	var resources := {
		&"food": ColonyResourceNode.new(&"surface_crops", &"food", 0, Vector2i(11, 0), 24, 48, 0, 4.0, 6),
		&"wood": ColonyResourceNode.new(&"surface_forest", &"wood", 0, Vector2i(wood_x, 0), 18, 36, 3, 5.0, 6),
		&"water": ColonyResourceNode.new(&"shallow_aquifer", &"water", 1, Vector2i(water_x, 1), 32, 64, 8, 3.0, 8),
		&"clay": ColonyResourceNode.new(&"clay_deposit", &"clay", 1, Vector2i(clay_x, 1), 30, 50, 0, 4.0, 5),
		&"stone": ColonyResourceNode.new(&"deep_bedrock", &"stone", 2, Vector2i(13, 2), 60, 100, 0, 5.0, 5),
		&"ore": ColonyResourceNode.new(&"deep_ore_vein", &"ore", 2, Vector2i(ore_x, 2), 24, 40, 0, 6.0, 3),
		&"coal": ColonyResourceNode.new(&"deep_coal_seam", &"coal", 2, Vector2i(coal_x, 2), 30, 50, 0, 5.0, 4)
	}
	return {
		"seed": world_seed,
		"resources": resources,
		"diggable_cells": [
			Vector2i(5, 1),
			Vector2i(6, 1),
			Vector2i(20, 2),
			Vector2i(21, 2)
		]
	}
