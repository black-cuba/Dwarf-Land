extends SceneTree


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_inventory()
	_test_resource_node()
	_test_navigation()
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


func _test_resource_node() -> void:
	var node := ColonyResourceNode.new(
		&"test_spring",
		&"water",
		0,
		Vector2i(5, 0),
		10,
		20,
		4,
		2.0,
		4
	)
	assert(node.reserve(4), "La fuente rechazó una reserva válida.")
	assert(node.available_units == 6, "La reserva no descontó existencias.")
	assert(not node.reserve(7), "La fuente permitió reservar más recursos de los disponibles.")
	node.regenerate()
	assert(node.available_units == 10, "La regeneración no respetó el límite máximo.")


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


func _test_colonist() -> void:
	var colonist := DwarfColonist.new(&"test_dwarf", "Prueba", "Minero")
	colonist.advance_hour(false, 18.0)
	assert(colonist.hunger > 15.0, "El hambre no aumenta con el tiempo.")
	assert(colonist.thirst > 12.0, "La sed no aumenta con el tiempo.")
	assert(absf(colonist.body_temperature - 37.0) < 0.01, "La temperatura corporal no se mantiene en ambiente templado.")
	assert(is_equal_approx(colonist.get_work_speed(&"stone"), 1.4), "La profesión minera no aplica su bonificación.")
	assert(is_equal_approx(colonist.get_work_speed(&"food"), 1.0), "La bonificación minera se aplicó a un trabajo no especializado.")


func _test_work_order_depth() -> void:
	var order := ColonyWorkOrder.new(
		&"deep_test",
		&"coal",
		2,
		Vector2i(14, 2),
		3,
		4.0,
		&"coal",
		5
	)
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
	assert(first.id != active[0]["assigned_colonist_id"], "El colono en estado crítico conservó el trabajo.")


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
		simulation.advance_hour()

	assert(simulation.inventory.get_amount(&"food") == initial_inventory + source.output_per_batch, "La tarea completada no entregó su producción.")
	assert(simulation.scheduler.get_active_orders_snapshot().is_empty(), "La tarea completada sigue activa.")

	var current_hour := simulation.hour
	simulation.set_paused(true)
	simulation.advance_hour()
	assert(simulation.hour == current_hour, "El reloj avanzó mientras la simulación estaba pausada.")
