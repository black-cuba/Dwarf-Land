extends SceneTree


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_inventory()
	_test_resource_node()
	_test_navigation()
	_test_colonist()
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
	assert(not navigation.is_walkable(Vector2i(5, 2)), "El mapa permite un tercer nivel.")

	navigation.set_blocked(Vector2i(ColonyNavigationGrid.ELEVATOR_COLUMN, 0), true)
	var blocked_path := navigation.find_path(Vector2i(7, 0), Vector2i(12, 1))
	assert(blocked_path.is_empty(), "La ruta atraviesa un ascensor bloqueado.")


func _test_colonist() -> void:
	var colonist := DwarfColonist.new(&"test_dwarf", "Prueba", "Minero")
	colonist.advance_hour(false, 18.0)
	assert(colonist.hunger > 15.0, "El hambre no aumenta con el tiempo.")
	assert(colonist.thirst > 12.0, "La sed no aumenta con el tiempo.")
	assert(absf(colonist.body_temperature - 37.0) < 0.01, "La temperatura corporal no se mantiene en ambiente templado.")
	assert(is_equal_approx(colonist.get_work_speed(&"stone"), 1.4), "La profesión minera no aplica su bonificación.")
	assert(is_equal_approx(colonist.get_work_speed(&"food"), 1.0), "La bonificación minera se aplicó a un trabajo no especializado.")


func _test_simulation_work_order() -> void:
	var simulation := ColonySimulation.new()
	var source: ColonyResourceNode = simulation.resource_nodes[&"food"]
	var initial_source := source.available_units
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
