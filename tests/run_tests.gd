extends SceneTree


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_inventory()
	_test_seeded_world_generation()
	_test_save_system_backup_recovery()
	_test_simulation_snapshot_restore()
	_test_crop_growth_and_harvest()
	_test_simulation_planting_queue()
	_test_autonomous_bed_assignment()
	_test_storage_construction_and_restore()
	_test_map_construction_and_restore()
	_test_workshop_tool_crafting()
	_test_mining_tool_durability()
	_test_game_modes()
	_test_illness_and_injury()
	_test_resource_node()
	_test_navigation()
	_test_navigation_2d_map()
	_test_map_excavation_work_order()
	_test_seeded_terrain_restore()
	_test_excavation()
	_test_excavation_work_order()
	_test_simulation_rejects_duplicate_excavation()
	_test_colonist()
	_test_work_order_depth()
	_test_scheduler_reassigns_urgent_colonist_work()
	_test_simulation_work_order()
	print("Dwarf Land: todas las pruebas automatizadas han pasado.")
	quit(0)


func _test_inventory() -> void:
	var inventory := ColonyInventory.new()
	var initial_food := inventory.get_amount(&"food")
	assert(initial_food == 36, "El inventario inicial de comida no coincide.")
	assert(inventory.add_resource(&"food", 10) == 10, "No se pudieron añadir recursos.")
	assert(inventory.get_amount(&"food") == 46, "La cantidad de comida es incorrecta.")
	assert(inventory.remove_resource(&"food", 6), "No se pudo retirar comida disponible.")
	assert(not inventory.remove_resource(&"food", 999), "El inventario permitió retirar recursos inexistentes.")
	assert(inventory.get_total_amount() <= inventory.capacity, "El inventario superó su capacidad.")



func _test_seeded_world_generation() -> void:
	var first := ColonyWorldGenerator.new(123456).generate()
	var repeat := ColonyWorldGenerator.new(123456).generate()
	var alternate := ColonyWorldGenerator.new(654321).generate()
	var first_nodes: Dictionary = first["resources"]
	var repeat_nodes: Dictionary = repeat["resources"]
	var alternate_nodes: Dictionary = alternate["resources"]
	assert(first_nodes[&"wood"].cell == repeat_nodes[&"wood"].cell, "La misma semilla no genera el mismo bosque.")
	assert(first_nodes[&"water"].cell == repeat_nodes[&"water"].cell, "La misma semilla no genera el mismo acuífero.")
	assert(first_nodes[&"ore"].cell == repeat_nodes[&"ore"].cell, "La misma semilla no genera la misma veta.")
	var distribution_changed: bool = first_nodes[&"wood"].cell != alternate_nodes[&"wood"].cell or first_nodes[&"water"].cell != alternate_nodes[&"water"].cell or first_nodes[&"clay"].cell != alternate_nodes[&"clay"].cell or first_nodes[&"ore"].cell != alternate_nodes[&"ore"].cell or first_nodes[&"coal"].cell != alternate_nodes[&"coal"].cell
	assert(distribution_changed, "Semillas distintas no variaron la distribución de recursos.")
	assert(first_nodes[&"food"].level == 0 and first_nodes[&"wood"].level == 0, "Los recursos de superficie están mal ubicados.")
	assert(first_nodes[&"water"].level == 1 and first_nodes[&"clay"].level == 1, "Los recursos del subsuelo están mal ubicados.")
	assert(first_nodes[&"stone"].level == 2 and first_nodes[&"ore"].level == 2 and first_nodes[&"coal"].level == 2, "Los recursos profundos están mal ubicados.")
	assert(first["map_diggable_cells"] == repeat["map_diggable_cells"], "La misma semilla no genera el mismo terreno 2D.")
	assert(first["map_diggable_cells"] != alternate["map_diggable_cells"], "Semillas distintas no alteran el terreno 2D.")
	for layer in [1, 2]:
		for map_cell in first["map_diggable_cells"]:
			if map_cell.z == layer:
				assert(map_cell.y != ColonyNavigationGrid.ELEVATOR_ROW and map_cell.x != ColonyNavigationGrid.ELEVATOR_COLUMN, "La generación bloqueó el corredor o el ascensor.")
	for resource_node in first_nodes.values():
		assert(resource_node.map_cell.y == ColonyNavigationGrid.ELEVATOR_ROW, "Una fuente de recursos no quedó situada en su galería 2D.")


func _test_resource_node() -> void:
	var node := ColonyResourceNode.new(&"test_spring", &"water", 0, Vector2i(5, 0), 10, 20, 4, 2.0, 4)
	assert(node.reserve(4), "La fuente rechazó una reserva válida.")
	assert(node.available_units == 6, "La reserva no descontó existencias.")
	assert(not node.reserve(7), "La fuente permitió reservar más recursos de los disponibles.")
	node.regenerate()
	assert(node.available_units == 10, "La regeneración no respetó el límite máximo.")
	assert(node.map_cell == Vector3i(5, ColonyNavigationGrid.ELEVATOR_ROW, 0), "La fuente no tiene una celda de mapa 2D válida.")


func _test_navigation() -> void:
	var navigation := ColonyNavigationGrid.new()
	var path := navigation.find_path(Vector2i(7, 0), Vector2i(12, 1))
	assert(not path.is_empty(), "No se encontró una ruta entre los dos niveles.")
	assert(path.back() == Vector2i(12, 1), "La ruta no termina en el destino solicitado.")
	for cell in path:
		assert(navigation.is_walkable(cell), "La ruta atraviesa una celda no transitable.")
	assert(navigation.is_walkable(Vector2i(5, 2)), "El nivel profundo debe existir.")
	assert(not navigation.is_walkable(Vector2i(5, 3)), "El mapa permite un cuarto nivel.")
	var deep_path := navigation.find_path(Vector2i(7, 0), Vector2i(12, 2))
	assert(not deep_path.is_empty(), "No se puede llegar desde la superficie a la profundidad.")
	navigation.set_blocked(Vector2i(ColonyNavigationGrid.ELEVATOR_COLUMN, 0), true)
	var blocked_path := navigation.find_path(Vector2i(7, 0), Vector2i(12, 2))
	assert(blocked_path.is_empty(), "La ruta atraviesa un ascensor bloqueado.")



func _test_navigation_2d_map() -> void:
	var navigation := ColonyNavigationGrid.new()
	var start := Vector3i(2, 5, 1)
	var goal := Vector3i(8, 5, 1)
	var direct_path := navigation.find_map_path(start, goal)
	assert(direct_path.size() == 6, "La cuadrícula 2D no calcula la ruta horizontal mínima.")
	navigation.set_map_blocked(Vector3i(5, 5, 1), true)
	var detour := navigation.find_map_path(start, goal)
	assert(not detour.is_empty(), "La navegación 2D no encontró una ruta alternativa.")
	assert(not detour.has(Vector3i(5, 5, 1)), "La ruta alternativa atraviesa un obstáculo.")
	for cell in detour:
		assert(navigation.is_map_walkable(cell), "La ruta 2D atraviesa una celda bloqueada.")
	var lift_path := navigation.find_map_path(Vector3i(34, 5, 0), Vector3i(34, 5, 2))
	assert(lift_path.size() == 2, "El ascensor no conecta las tres capas en el mismo punto.")
	navigation.set_map_blocked(Vector3i(34, 5, 1), true)
	assert(navigation.find_map_path(Vector3i(34, 5, 0), Vector3i(34, 5, 2)).is_empty(), "El ascensor bloqueado sigue conectando capas.")
	var wall := Vector3i(6, 6, 2)
	navigation.set_map_diggable(wall)
	assert(navigation.can_dig_map_cell(wall), "La roca 2D no quedó marcada para excavar.")
	assert(not navigation.is_map_walkable(wall), "La roca 2D bloqueada permite el paso.")
	assert(navigation.excavate_map_cell(wall), "No se pudo excavar una celda 2D.")
	assert(navigation.is_map_walkable(wall), "La excavación 2D no abrió el paso.")
	assert(not navigation.can_dig_map_cell(wall), "La roca excavada sigue pendiente.")
	assert(not navigation.is_map_cell_inside(Vector3i(0, ColonyNavigationGrid.MAP_HEIGHT, 0)), "El mapa aceptó una fila fuera de sus límites.")



func _test_map_excavation_work_order() -> void:
	var scheduler := ColonyWorkScheduler.new()
	var navigation := ColonyNavigationGrid.new()
	var target := Vector3i(36, 4, 2)
	navigation.set_map_diggable(target)
	var colonist := DwarfColonist.new(&"map_miner", "Minero", "Minero")
	colonist.current_position = Vector2i(32, 0)
	colonist.sync_map_position_from_legacy()
	var colonists: Array[DwarfColonist] = [colonist]
	var order_id := scheduler.queue_map_excavation(target)
	assert(order_id != &"", "No se pudo crear una orden de excavación en el mapa 2D.")
	var saved_orders := scheduler.get_active_orders_snapshot()
	var restored_scheduler := ColonyWorkScheduler.new()
	assert(restored_scheduler.restore_active_orders(saved_orders), "No se pudo restaurar la orden de excavación 2D.")
	assert(restored_scheduler.orders[0].target_map_cell == target, "El guardado perdió la celda de excavación 2D.")
	scheduler.advance_hour(colonists, navigation)
	scheduler.advance_hour(colonists, navigation)
	assert(colonist.is_map_moving, "El minero no inició la ruta hacia la roca 2D.")
	for _step in range(4):
		if colonist.is_map_moving:
			colonist.advance_map_movement(2.0)
		scheduler.advance_hour(colonists, navigation)
	assert(not navigation.can_dig_map_cell(target), "El minero no completó la excavación en la cuadrícula 2D.")
	assert(navigation.is_map_walkable(target), "La celda excavada no quedó transitable.")


func _test_seeded_terrain_restore() -> void:
	var generated := ColonyWorldGenerator.new(24680).generate()
	var simulation := ColonySimulation.new()
	for cell in generated["map_diggable_cells"]:
		simulation.navigation.set_map_diggable(cell)
	var snapshot := simulation.get_snapshot()
	var restored := ColonySimulation.new()
	assert(restored.restore_snapshot(snapshot), "No se pudo restaurar el terreno 2D.")
	assert(restored.navigation.diggable_map_cells.size() == simulation.navigation.diggable_map_cells.size(), "El guardado perdió bloques excavables del mapa 2D.")
	for cell in simulation.navigation.diggable_map_cells:
		assert(restored.navigation.can_dig_map_cell(cell), "Un bloque excavable no sobrevivió al guardado.")


func _test_excavation() -> void:
	var navigation := ColonyNavigationGrid.new()
	var wall := Vector2i(8, 1)
	navigation.set_diggable(wall)
	assert(not navigation.is_walkable(wall), "La roca sin excavar debe bloquear el paso.")
	assert(navigation.can_dig(wall), "La roca preparada no aparece como excavable.")
	assert(navigation.get_adjacent_work_cell(Vector2i(7, 1), wall) == Vector2i(7, 1), "El colono no puede trabajar desde una celda adyacente.")
	assert(navigation.excavate(wall), "No se pudo excavar la roca.")
	assert(navigation.is_walkable(wall), "La celda excavada no se volvió transitable.")
	assert(not navigation.can_dig(wall), "La roca excavada sigue marcada como pendiente.")





func _test_save_system_backup_recovery() -> void:
	var save_system := ColonySaveSystem.new("user://dwarf_land_test_saves")
	var first_snapshot := {"day": 4, "position": Vector2i(8, 2), "map_position": Vector3i(8, 4, 2), "name": "Primera"}
	var second_snapshot := {"day": 5, "position": Vector2i(9, 2), "name": "Segunda"}
	assert(save_system.save_snapshot(first_snapshot), "No se pudo crear el primer guardado.")
	assert(save_system.save_snapshot(second_snapshot), "No se pudo actualizar el guardado.")
	var loaded := save_system.load_snapshot()
	assert(loaded.success and not loaded.used_backup, "No se leyó el guardado principal.")
	assert(loaded.data.day == 5 and loaded.data.position == Vector2i(9, 2), "El guardado no conservó los datos.")
	assert(loaded.data.map_position == Vector3i(8, 4, 2), "El guardado no serializó una coordenada Vector3i.")
	var target := ProjectSettings.globalize_path("user://dwarf_land_test_saves/colony_save.json")
	var corrupt := FileAccess.open(target, FileAccess.WRITE)
	assert(corrupt != null, "No se pudo preparar la prueba de recuperación.")
	corrupt.store_string("{invalid json")
	corrupt.close()
	var recovered := save_system.load_snapshot()
	assert(recovered.success and recovered.used_backup, "No se recuperó la copia de seguridad.")
	assert(recovered.data.day == 4, "La copia de seguridad recuperada no es la versión anterior.")
	var directory := ProjectSettings.globalize_path("user://dwarf_land_test_saves")
	DirAccess.remove_absolute(target)
	DirAccess.remove_absolute(target + ".bak")
	DirAccess.remove_absolute(directory)



func _test_simulation_snapshot_restore() -> void:
	var original := ColonySimulation.new()
	original.day = 9
	original.hour = 14
	original.active_level = 2
	original.inventory.add_resource(&"ore", 7)
	original.navigation.excavate(Vector2i(20, 2))
	original.queue_work(&"food", 4)
	var snapshot := original.get_snapshot()
	var restored := ColonySimulation.new()
	assert(restored.restore_snapshot(snapshot), "No se pudo restaurar el estado completo de la colonia.")
	assert(restored.day == 9 and restored.hour == 14, "El reloj no se restauró.")
	assert(restored.world_seed == original.world_seed, "La semilla del mundo no se restauró.")
	assert(restored.resource_nodes[&"ore"].cell == original.resource_nodes[&"ore"].cell, "La posición del yacimiento no se restauró.")
	assert(restored.active_level == 2, "No se restauró la capa activa.")
	assert(restored.inventory.get_amount(&"ore") == original.inventory.get_amount(&"ore"), "El inventario no se restauró.")
	assert(restored.navigation.is_walkable(Vector2i(20, 2)), "El terreno excavado no se conservó.")
	assert(restored.scheduler.get_active_orders_snapshot().size() == 1, "La cola de trabajo no se restauró.")
	assert(restored.crop_field.is_ready, "El estado del campo no se restauró.")



func _test_crop_growth_and_harvest() -> void:
	var field := ColonyCropField.new()
	assert(field.is_ready, "El campo inicial debe tener una cosecha lista.")
	assert(field.harvest(12) == 12, "No se pudo cosechar una parte de la producción.")
	assert(field.is_ready and field.harvestable_units == 12, "La cosecha parcial alteró incorrectamente el campo.")
	assert(field.harvest(12) == 12, "No se pudo completar la cosecha.")
	assert(not field.is_planted, "El campo debe quedar libre tras agotar la cosecha.")
	assert(field.plant(), "No se pudo replantar el campo.")
	assert(not field.is_ready, "El campo recién sembrado aparece maduro.")
	for _day in range(4):
		field.advance_day(true)
	assert(field.is_ready and field.harvestable_units == ColonyCropField.HARVEST_PER_CYCLE, "El cultivo no maduró tras cuatro días con agua.")
	var restored_field := ColonyCropField.new()
	assert(restored_field.restore(field.get_snapshot()), "No se pudo restaurar el campo.")
	assert(restored_field.map_cell == field.map_cell, "El guardado perdió la celda 2D del cultivo.")



func _test_simulation_planting_queue() -> void:
	var simulation := ColonySimulation.new()
	simulation.crop_field.harvest(ColonyCropField.HARVEST_PER_CYCLE)
	var seeds_before := simulation.inventory.get_amount(&"seeds")
	assert(simulation.queue_planting(), "No se pudo crear la orden de siembra.")
	assert(not simulation.queue_planting(), "Se permitió duplicar una orden de siembra.")
	assert(simulation.inventory.get_amount(&"seeds") == seeds_before - 1, "La semilla no se reservó al crear la orden.")
	simulation.advance_hour()
	for _hour in range(4):
		simulation.update_frame(2.0)
		simulation.advance_hour()
	assert(simulation.crop_field.is_planted and not simulation.crop_field.is_ready, "La orden completada no sembró el campo.")
	assert(simulation.scheduler.get_active_orders_snapshot().is_empty(), "La orden de siembra sigue activa tras completarse.")
	var water_before := simulation.inventory.get_amount(&"water")
	simulation._on_new_day()
	assert(simulation.inventory.get_amount(&"water") == water_before - 1, "El cultivo en crecimiento no consumió agua disponible.")



func _test_autonomous_bed_assignment() -> void:
	var simulation := ColonySimulation.new()
	var colonist: DwarfColonist = simulation.colonists[0]
	colonist.current_position = Vector2i(7, 1)
	colonist.current_level = 1
	colonist.sync_map_position_from_legacy()
	colonist.fatigue = 80.0
	simulation.hour = 21
	simulation.advance_hour()
	assert(colonist.is_resting and colonist.is_sleeping, "El colono no ocupó una cama durante el descanso nocturno.")
	assert(simulation._bed_assignments.size() == 3, "No se asignó una cama independiente a cada colono.")
	var assigned_beds: Array = simulation._bed_assignments.values()
	assert(assigned_beds[0] != assigned_beds[1] and assigned_beds[1] != assigned_beds[2] and assigned_beds[0] != assigned_beds[2], "Dos colonos comparten la misma cama.")
	assert(colonist.fatigue < 80.0, "El descanso nocturno no redujo la fatiga.")
	var surface_colonist: DwarfColonist = simulation.colonists[1]
	var deep_colonist: DwarfColonist = simulation.colonists[2]
	simulation.hour = 12
	assert(simulation.get_local_temperature(surface_colonist) > simulation.get_local_temperature(deep_colonist), "La profundidad no es más fría que la superficie.")
	assert(simulation.get_local_temperature(colonist) > simulation.ambient_temperature, "El refugio no mejora la temperatura durante el sueño.")
	simulation.hour = 5
	simulation.advance_hour()
	assert(not colonist.is_resting and not colonist.is_sleeping, "El colono siguió descansando después del amanecer.")



func _test_storage_construction_and_restore() -> void:
	var simulation := ColonySimulation.new()
	simulation.active_level = 1
	for colonist in simulation.colonists:
		colonist.current_position = Vector2i(24, 1)
		colonist.current_level = 1
	var wood_before := simulation.inventory.get_amount(&"wood")
	var stone_before := simulation.inventory.get_amount(&"stone")
	assert(simulation.queue_construction(&"storage", Vector2i(25, 1)), "No se pudo ordenar la construcción del almacén.")
	assert(not simulation.queue_construction(&"storage", Vector2i(15, 1)), "Se permitió duplicar la construcción en una celda.")
	assert(simulation.inventory.get_amount(&"wood") == wood_before - 8, "No se reservaron los tablones necesarios.")
	assert(simulation.inventory.get_amount(&"stone") == stone_before - 4, "No se reservaron las piedras necesarias.")
	simulation.advance_hour()
	for _hour in range(4):
		simulation.advance_hour()
	assert(simulation.structures.size() == 1, "La estructura no se creó al completar el trabajo.")
	assert(simulation.inventory.capacity == ColonyInventory.DEFAULT_CAPACITY + 60, "El almacén no aumentó la capacidad.")
	assert(simulation.navigation.is_walkable(Vector2i(25, 1)), "La construcción no debe bloquear la ruta en la cuadrícula actual.")
	var restored := ColonySimulation.new()
	assert(restored.restore_snapshot(simulation.get_snapshot()), "No se pudo restaurar una colonia con estructuras.")
	assert(restored.structures.size() == 1, "La estructura no se conservó en el guardado.")
	assert(restored.inventory.capacity == ColonyInventory.DEFAULT_CAPACITY + 60, "La capacidad del almacén no se conservó.")
	assert(restored.navigation.is_walkable(Vector2i(25, 1)), "La estructura restaurada debe conservar una ruta transitable.")



func _test_map_construction_and_restore() -> void:
	var simulation := ColonySimulation.new()
	simulation.active_level = 1
	for colonist in simulation.colonists:
		colonist.current_position = Vector2i(36, 1)
		colonist.current_level = 1
		colonist.sync_map_position_from_legacy()
	var target := Vector3i(38, ColonyNavigationGrid.ELEVATOR_ROW, 1)
	assert(simulation.queue_map_construction(&"storage", target), "No se pudo ordenar la construcción sobre una celda 2D.")
	assert(not simulation.queue_map_construction(&"storage", target), "Se permitió duplicar una construcción 2D.")
	for _hour in range(7):
		simulation.advance_hour()
		simulation.update_frame(2.0)
	assert(simulation.structures.size() == 1, "La construcción 2D no se completó.")
	assert(simulation.navigation.blocked_map_cells.has(target), "La estructura terminada no bloqueó su celda 2D.")
	var restored := ColonySimulation.new()
	assert(restored.restore_snapshot(simulation.get_snapshot()), "No se restauró una estructura del mapa 2D.")
	assert(restored.navigation.blocked_map_cells.has(target), "El guardado perdió la colisión de la estructura 2D.")
	assert(restored.get_bed_map_cells().size() == 3, "Las camas iniciales no se conservaron tras construir.")
	var new_bed := Vector3i(37, ColonyNavigationGrid.ELEVATOR_ROW, 1)
	assert(restored.queue_map_construction(&"bed", new_bed), "No se pudo ordenar una cama en el mapa 2D.")
	for _hour in range(5):
		restored.advance_hour()
		restored.update_frame(2.0)
	assert(restored.get_bed_map_cells().has(new_bed), "La cama construida no se añadió a la asignación nocturna.")
	assert(restored.navigation.is_map_walkable(new_bed), "La cama construida bloquea el acceso del colono.")


func _test_workshop_tool_crafting() -> void:
	var simulation := ColonySimulation.new()
	simulation.active_level = 1
	assert(not simulation.queue_crafting(&"tool"), "Se permitió fabricar sin un taller.")
	for colonist in simulation.colonists:
		colonist.current_position = Vector2i(24, 1)
		colonist.current_level = 1
	assert(simulation.queue_construction(&"workshop", Vector2i(25, 1)), "No se pudo ordenar la construcción del taller.")
	simulation.advance_hour()
	for _hour in range(5):
		simulation.advance_hour()
	assert(simulation.has_workshop(), "El taller no quedó disponible al completar su construcción.")
	for colonist in simulation.colonists:
		colonist.current_position = Vector2i(25, 1)
		colonist.current_level = 1
	assert(simulation.add_resource(&"ore", 1) == 1, "No se pudo añadir el mineral de prueba.")
	var tools_before := simulation.inventory.get_amount(&"tools")
	assert(simulation.queue_crafting(&"tool"), "No se pudo encolar la fabricación de una herramienta.")
	for _hour in range(4):
		simulation.advance_hour()
	assert(simulation.inventory.get_amount(&"tools") == tools_before + 1, "El taller no produjo la herramienta.")



func _test_mining_tool_durability() -> void:
	var simulation := ColonySimulation.new()
	simulation.active_level = 2
	for colonist in simulation.colonists:
		colonist.current_position = Vector2i(12, 2)
		colonist.current_level = 2
	simulation.tool_durability = 20.0
	var tools_before := simulation.inventory.get_amount(&"tools")
	assert(simulation.queue_work(&"stone"), "No se pudo ordenar la extracción con herramienta.")
	assert(simulation.inventory.get_amount(&"tools") == tools_before - 1, "La herramienta no se reservó al iniciar la extracción.")
	simulation.advance_hour()
	for _hour in range(6):
		simulation.update_frame(1.0)
		simulation.advance_hour()
	assert(simulation.tool_durability == 100.0, "La durabilidad no se reinició al romperse la herramienta.")
	assert(simulation.inventory.get_amount(&"tools") == tools_before - 1, "Una herramienta rota volvió al inventario.")

	var no_tools := ColonySimulation.new()
	no_tools.active_level = 2
	no_tools.inventory.remove_resource(&"tools", no_tools.inventory.get_amount(&"tools"))
	var stone_node: ColonyResourceNode = no_tools.resource_nodes[&"stone"]
	var stone_before := stone_node.available_units
	assert(not no_tools.queue_work(&"stone"), "Se permitió minar sin herramientas.")
	assert(stone_node.available_units == stone_before, "La fuente perdió recursos al rechazar una orden sin herramientas.")



func _test_game_modes() -> void:
	var simulation := ColonySimulation.new()
	assert(simulation.game_mode == &"survival", "El modo inicial no es Supervivencia.")
	var colonist: DwarfColonist = simulation.colonists[0]
	colonist.hunger = 25.0
	colonist.thirst = 30.0
	colonist.fatigue = 40.0
	assert(simulation.set_game_mode(&"sandbox"), "No se pudo activar Sandbox.")
	simulation.advance_hour()
	assert(is_equal_approx(colonist.hunger, 25.0) and is_equal_approx(colonist.thirst, 30.0), "Sandbox alteró las necesidades.")
	assert(is_equal_approx(colonist.fatigue, 40.0), "Sandbox alteró la fatiga.")
	assert(not simulation.set_game_mode(&"invalid"), "Se aceptó un modo inexistente.")

	assert(simulation.set_game_mode(&"campaign"), "No se pudo activar Campaña.")
	assert(not simulation.get_campaign_progress().complete, "La campaña aparece completada sin objetivos.")
	simulation.day = 10
	simulation.structures.append({"id": "test_storage", "type": "storage", "cell": Vector2i(30, 1), "level": 1})
	simulation.structures.append({"id": "test_workshop", "type": "workshop", "cell": Vector2i(31, 1), "level": 1})
	assert(simulation.get_campaign_progress().complete, "Los objetivos de campaña no se reconocieron.")
	var restored := ColonySimulation.new()
	assert(restored.restore_snapshot(simulation.get_snapshot()), "No se pudo restaurar el modo de juego.")
	assert(restored.game_mode == &"campaign", "El modo de juego no se guardó.")



func _test_illness_and_injury() -> void:
	var sick := DwarfColonist.new(&"sick_test", "Enfermo", "Recolector")
	sick.apply_illness(50.0)
	sick.advance_hour(false, 18.0)
	assert(sick.get_condition() == "Enfermo", "La enfermedad no aparece en el estado del colono.")
	assert(sick.health < 100.0, "La enfermedad no afecta la salud.")

	var injured := DwarfColonist.new(&"injured_test", "Herido", "Minero")
	injured.apply_injury(30.0)
	injured.advance_hour(false, 18.0)
	assert(injured.get_condition() == "Herido", "La lesión no aparece en el estado del colono.")
	var injury_before := injured.injury_severity
	injured.is_sleeping = true
	injured.advance_hour(true, 18.0)
	assert(injured.injury_severity < injury_before, "El descanso no ayuda a recuperarse de una lesión.")


func _test_simulation_rejects_duplicate_excavation() -> void:
	var simulation := ColonySimulation.new()
	simulation.active_level = 1
	var target := Vector2i(5, 1)
	assert(simulation.queue_excavation(target), "No se pudo crear la primera orden de excavación.")
	assert(not simulation.queue_excavation(target), "La simulación permitió duplicar una orden de excavación pendiente.")


func _test_excavation_work_order() -> void:
	var navigation := ColonyNavigationGrid.new()
	var scheduler := ColonyWorkScheduler.new()
	var colonist := DwarfColonist.new(&"dig_test", "Excavador", "Minero")
	colonist.current_position = Vector2i(7, 1)
	navigation.set_diggable(Vector2i(8, 1))
	var colonists: Array[DwarfColonist] = [colonist]
	scheduler.queue_order(&"dig", 1, Vector2i(8, 1), 3, 3.0, &"", 0)
	scheduler.advance_hour(colonists, navigation)
	assert(not navigation.is_walkable(Vector2i(8, 1)), "La roca se excavó antes de completar el trabajo.")
	for _hour in range(3):
		scheduler.advance_hour(colonists, navigation)
	assert(navigation.is_walkable(Vector2i(8, 1)), "La orden completada no abrió el paso.")
	assert(scheduler.get_active_orders_snapshot().is_empty(), "La orden de excavación sigue activa tras completarse.")


func _test_colonist() -> void:
	var colonist := DwarfColonist.new(&"test_dwarf", "Prueba", "Minero")
	colonist.advance_hour(false, 18.0)
	assert(colonist.hunger > 15.0, "El hambre no aumenta con el tiempo.")
	assert(colonist.thirst > 12.0, "La sed no aumenta con el tiempo.")
	assert(absf(colonist.body_temperature - 37.0) < 0.01, "La temperatura corporal no se mantiene en ambiente templado.")
	assert(is_equal_approx(colonist.get_work_speed(&"stone"), 1.4), "La profesión minera no aplica su bonificación.")
	assert(is_equal_approx(colonist.get_work_speed(&"food"), 1.0), "La bonificación minera se aplicó a un trabajo no especializado.")
	colonist.start_movement(Vector2i(9, 0))
	assert(colonist.is_moving, "El colono no inició el movimiento.")
	colonist.advance_movement(0.2)
	assert(colonist.visual_position.x > 7.0 and colonist.visual_position.x < 9.0, "El movimiento no interpola posiciones.")
	colonist.advance_movement(1.0)
	assert(not colonist.is_moving and colonist.current_position == Vector2i(9, 0), "El colono no finalizó el movimiento.")
	colonist.sync_map_position_from_legacy()
	colonist.start_map_movement(Vector3i(12, 5, 0))
	assert(colonist.is_map_moving, "El colono no inició el movimiento en el mapa 2D.")
	colonist.advance_map_movement(0.4)
	assert(colonist.map_visual_position.x > 9.0 and colonist.map_visual_position.x < 12.0, "El movimiento espacial 2D no interpola la posición.")
	colonist.advance_map_movement(1.0)
	assert(not colonist.is_map_moving and colonist.map_position == Vector3i(12, 5, 0), "El colono no terminó el movimiento en el mapa 2D.")
	assert(colonist.current_position == Vector2i(12, 0), "La posición de juego heredada no se sincronizó con el mapa 2D.")
	colonist.fatigue = 80.0
	colonist.is_sleeping = true
	colonist.advance_hour(true, 18.0)
	assert(is_equal_approx(colonist.fatigue, 65.0), "Dormir en una cama no recuperó la fatiga esperada.")
	colonist.is_sleeping = false
	colonist.fatigue = 50.0
	colonist.advance_hour(true, 18.0)
	assert(colonist.fatigue > 50.0, "El colono recuperó fatiga sin dormir.")
	var cold_colonist := DwarfColonist.new(&"cold_test", "Frío", "Minero")
	for _hour in range(60):
		cold_colonist.advance_hour(false, 0.0)
	assert(cold_colonist.body_temperature < 37.0, "La temperatura corporal no respondió al frío extremo.")
	assert(cold_colonist.health < 100.0, "El frío extremo no produjo daño a la salud.")


func _test_work_order_depth() -> void:
	var order := ColonyWorkOrder.new(&"deep_test", &"coal", 2, Vector2i(14, 2), 3, 4.0, &"coal", 5)
	assert(order.level == 2, "La orden minera perdió su nivel de profundidad.")
	assert(order.target_cell == Vector2i(14, 2), "La orden minera alteró la coordenada de destino.")


func _test_scheduler_reassigns_urgent_colonist_work() -> void:
	var scheduler := ColonyWorkScheduler.new()
	var navigation := ColonyNavigationGrid.new()
	var first := DwarfColonist.new(&"first", "Primero", "Minero")
	var second := DwarfColonist.new(&"second", "Segundo", "Minero")
	first.current_position = Vector2i(12, 2)
	second.current_position = Vector2i(12, 2)
	var colonists: Array[DwarfColonist] = [first, second]
	var order_id := scheduler.queue_order(&"stone", 2, Vector2i(12, 2), 3, 10.0, &"stone", 4)
	scheduler.advance_hour(colonists, navigation)
	assert(scheduler.get_active_orders_snapshot()[0]["assigned_colonist_id"] == "first", "La primera orden no se asignó al primer colono disponible.")
	first.hunger = 85.0
	scheduler.advance_hour(colonists, navigation)
	var active := scheduler.get_active_orders_snapshot()
	assert(active.size() == 1, "La orden se perdió al liberar al colono.")
	assert(active[0]["id"] == String(order_id), "La orden reasignada no conserva su identificador.")
	assert(active[0]["assigned_colonist_id"] == "second", "La tarea no se reasignó al siguiente colono disponible.")


func _test_scheduler_uses_2d_map_routes() -> void:
	var scheduler := ColonyWorkScheduler.new()
	var navigation := ColonyNavigationGrid.new()
	var colonist := DwarfColonist.new(&"route_test", "Explorador", "Minero")
	colonist.current_position = Vector2i(32, 0)
	colonist.sync_map_position_from_legacy()
	var colonists: Array[DwarfColonist] = [colonist]
	scheduler.queue_order(&"stone", 2, Vector2i(36, 2), 3, 2.0, &"stone", 1)
	scheduler.advance_hour(colonists, navigation)
	scheduler.advance_hour(colonists, navigation)
	assert(colonist.is_map_moving, "El planificador no inició el desplazamiento por la cuadrícula 2D.")
	colonist.advance_map_movement(2.0)
	assert(colonist.map_position == Vector3i(34, ColonyNavigationGrid.ELEVATOR_ROW, 2), "El colono no utilizó el ascensor para cambiar de capa.")
	scheduler.advance_hour(colonists, navigation)
	assert(colonist.is_map_moving, "El colono no reanudó la ruta 2D después de usar el ascensor.")


func _test_simulation_work_order() -> void:
	var simulation := ColonySimulation.new()
	var source: ColonyResourceNode = simulation.resource_nodes[&"food"]
	var initial_source := source.available_units
	assert(source.level == 0, "Los cultivos deben estar en la superficie.")
	var water_source: ColonyResourceNode = simulation.resource_nodes[&"water"]
	var stone_source: ColonyResourceNode = simulation.resource_nodes[&"stone"]
	var ore_source: ColonyResourceNode = simulation.resource_nodes[&"ore"]
	var clay_source: ColonyResourceNode = simulation.resource_nodes[&"clay"]
	var coal_source: ColonyResourceNode = simulation.resource_nodes[&"coal"]
	assert(water_source.level == 1 and clay_source.level == 1, "El acuífero y la arcilla deben estar en el subsuelo.")
	assert(stone_source.level == 2 and ore_source.level == 2 and coal_source.level == 2, "La roca, el carbón y los minerales deben estar en profundidad.")
	var initial_inventory := simulation.inventory.get_amount(&"food")
	assert(simulation.queue_work(&"food", 3), "No se pudo encolar una tarea de comida.")
	assert(source.available_units == initial_source - source.output_per_batch, "La tarea no reservó recursos de la fuente.")
	simulation.advance_hour()
	var active_orders := simulation.scheduler.get_active_orders_snapshot()
	assert(active_orders.size() == 1, "La orden no aparece en la cola activa.")
	assert(active_orders[0]["assigned_colonist_id"] == "dwarf_002", "La tarea agrícola no se asignó a la colona especializada.")
	for _hour in range(5):
		simulation.update_frame(2.0)
		simulation.advance_hour()
	assert(simulation.inventory.get_amount(&"food") == initial_inventory + source.output_per_batch, "La tarea completada no entregó su producción.")
	assert(simulation.scheduler.get_active_orders_snapshot().is_empty(), "La tarea completada sigue activa.")
	var current_hour := simulation.hour
	simulation.set_paused(true)
	simulation.advance_hour()
	assert(simulation.hour == current_hour, "El reloj avanzó mientras la simulación estaba pausada.")
