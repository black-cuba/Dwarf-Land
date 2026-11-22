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
	var clay_x := random.randi_range(10, 11)
	var mushroom_x := random.randi_range(3, 5)
	var ore_x := random.randi_range(22, 27)
	var coal_x := random.randi_range(28, 33)

	var resources := {
		&"food": ColonyResourceNode.new(&"surface_crops", &"food", 0, Vector2i(11, 0), 24, 48, 0, 4.0, 6),
		&"wood": ColonyResourceNode.new(&"surface_forest", &"wood", 0, Vector2i(wood_x, 0), 18, 36, 3, 5.0, 6),
		&"water": ColonyResourceNode.new(&"shallow_aquifer", &"water", 1, Vector2i(water_x, 1), 32, 64, 8, 3.0, 8),
		&"clay": ColonyResourceNode.new(&"clay_deposit", &"clay", 1, Vector2i(clay_x, 1), 30, 50, 0, 4.0, 5),
		&"mushrooms": ColonyResourceNode.new(&"fungal_grove", &"mushrooms", 1, Vector2i(mushroom_x, 1), 18, 30, 4, 2.5, 4),
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
		],
		"map_diggable_cells": _generate_map_diggable_cells()
	}


func _generate_map_diggable_cells() -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for layer in [1, 2]:
		var cavern_centers: Array[Vector2i] = []
		var cavern_count := 9 if layer == 1 else 6
		for _index in range(cavern_count):
			cavern_centers.append(Vector2i(
				random.randi_range(3, ColonyNavigationGrid.MAP_WIDTH - 4),
				random.randi_range(1, ColonyNavigationGrid.MAP_HEIGHT - 2)
			))
		for y in range(ColonyNavigationGrid.MAP_HEIGHT):
			for x in range(ColonyNavigationGrid.MAP_WIDTH):
				# A clear horizontal service gallery and the lift shaft keep
				# every generated cavern reachable without making the map empty.
				if y == ColonyNavigationGrid.ELEVATOR_ROW or x == ColonyNavigationGrid.ELEVATOR_COLUMN:
					continue
				var cell := Vector2i(x, y)
				var is_cavern := false
				for center in cavern_centers:
					var radius_x := 2.0 if layer == 1 else 1.6
					var radius_y := 1.8 if layer == 1 else 1.4
					var dx := float(x - center.x) / radius_x
					var dy := float(y - center.y) / radius_y
					if dx * dx + dy * dy <= 1.0:
						is_cavern = true
						break
				if is_cavern:
					continue
				# Slight deterministic irregularity avoids a uniform wall edge.
				if random.randf() > (0.08 if layer == 1 else 0.04):
					cells.append(Vector3i(x, y, layer))
	return cells
