extends Node2D

const WORLD_WIDTH := 1280.0
const WORLD_HEIGHT := 720.0
const TICK_SECONDS := 4.0

var simulation := ColonySimulation.new()
var tick_timer := 0.0
var message := "La colonia necesita comida, agua y refugio."

var hud: CanvasLayer
var title_label: Label
var status_label: Label
var message_label: Label
var action_buttons: Array[Button] = []
var selected_extraction_index := 0
var build_mode := false
var selected_building_index := 0


func _ready() -> void:
	simulation.alert_raised.connect(_on_alert_raised)
	simulation.colony_changed.connect(_refresh_interface)
	if simulation.load_game():
		message = "Partida local recuperada correctamente."
	_build_interface()
	_refresh_interface()
	queue_redraw()


func _process(delta: float) -> void:
	if simulation.update_frame(delta):
		queue_redraw()
	if simulation.paused:
		return

	tick_timer += delta
	while tick_timer >= TICK_SECONDS:
		tick_timer -= TICK_SECONDS
		simulation.advance_hour()
		queue_redraw()



func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		simulation.save_game()


func _draw() -> void:
	_draw_cavern()
	_draw_excavation_blocks()
	_draw_structures()
	_draw_resource_nodes()
	_draw_colonists()
	_draw_level_marker()


func _draw_cavern() -> void:
	draw_rect(Rect2(0, 0, WORLD_WIDTH, WORLD_HEIGHT), Color("#111827"))

	# Surface: sky, distant hills, grass and a continuous soil profile.
	draw_rect(Rect2(0, 120, WORLD_WIDTH, 88), Color("#344b55"))
	draw_rect(Rect2(0, 185, WORLD_WIDTH, 28), Color("#5e8b50"))
	draw_rect(Rect2(0, 213, WORLD_WIDTH, 407), Color("#4a382d"))
	draw_rect(Rect2(0, 250, WORLD_WIDTH, 150), Color("#63452f"))
	draw_rect(Rect2(0, 420, WORLD_WIDTH, 200), Color("#34343a"))

	for i in range(18):
		var x := float(i) * 78.0
		draw_rect(Rect2(x, 216 + (i % 3) * 14, 48, 5), Color("#76513a"))
		draw_circle(Vector2(x + 28, 282 + (i % 4) * 20), 3, Color("#9a7958"))
		draw_circle(Vector2(x + 12, 462 + (i % 5) * 20), 4, Color("#59616a"))

	# Three walkable layers: surface, shallow subsurface and deep bedrock.
	var floors := [205.0, 390.0, 585.0]
	var labels := [
		"SUPERFICIE · ÁRBOLES Y SUELO",
		"SUBSUELO · RAÍCES, ARCILLA Y AGUA",
		"PROFUNDIDAD · ROCA Y VETAS MINERALES"
	]
	for layer in range(3):
		var floor_y: float = floors[layer]
		draw_rect(Rect2(45, floor_y, 1190, 16), Color("#7b5a3d") if layer < 2 else Color("#737b83"))
		draw_rect(Rect2(45, floor_y + 16, 1190, 6), Color("#3d3029"))
		draw_string(ThemeDB.fallback_font, Vector2(65, floor_y - 12), labels[layer], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#e8d6b5"))

	# One elevator shaft connects all three layers.
	draw_rect(Rect2(1080, 195, 70, 400), Color("#495565"), false, 5.0)
	draw_line(Vector2(1115, 200), Vector2(1115, 590), Color("#c7a66a"), 3.0)
	var lift_y: float = floors[simulation.active_level]
	draw_circle(Vector2(1115, lift_y), 10.0, Color("#f4c76b"))



func _draw_excavation_blocks() -> void:
	var floors := [205.0, 390.0, 585.0]
	for cell in simulation.navigation.get_diggable_cells():
		if cell.y != simulation.active_level:
			continue
		var px := 65.0 + float(cell.x) * 28.0
		var floor_y: float = floors[cell.y]
		draw_rect(Rect2(px - 13, floor_y - 31, 26, 31), Color("#76563f"))
		draw_rect(Rect2(px - 13, floor_y - 31, 26, 31), Color("#a98761"), false, 2.0)
		draw_line(Vector2(px - 8, floor_y - 22), Vector2(px + 7, floor_y - 10), Color("#4d392d"), 2.0)
		draw_line(Vector2(px + 5, floor_y - 27), Vector2(px - 4, floor_y - 14), Color("#4d392d"), 2.0)

	var active_floor: float = floors[simulation.active_level]
	var grid_color := Color(0.82, 0.86, 0.9, 0.16)
	for column in range(ColonyNavigationGrid.MAP_WIDTH + 1):
		var grid_x := 65.0 + float(column) * 28.0
		draw_line(Vector2(grid_x, active_floor - 66.0), Vector2(grid_x, active_floor + 78.0), grid_color, 1.0)
	for row in range(ColonyNavigationGrid.MAP_HEIGHT + 1):
		var grid_y := active_floor - 66.0 + float(row) * 12.0
		draw_line(Vector2(65.0, grid_y), Vector2(1185.0, grid_y), grid_color, 1.0)

	for cell in simulation.navigation.diggable_map_cells.keys():
		if cell.z != simulation.active_level:
			continue
		var px := 65.0 + float(cell.x) * 28.0 + 14.0
		var py := active_floor + float(cell.y - ColonyNavigationGrid.ELEVATOR_ROW) * 12.0
		draw_rect(Rect2(px - 13.0, py - 5.0, 26.0, 10.0), Color("#625b58"))
		draw_rect(Rect2(px - 13.0, py - 5.0, 26.0, 10.0), Color("#a18e7d"), false, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	var position := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
		position = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
		position = event.position

	if not pressed:
		return

	var floors := [205.0, 390.0, 585.0]
	var floor_y: float = floors[simulation.active_level]
	if position.x < 65.0 or position.x > 1185.0:
		return
	if position.y < floor_y - 66.0 or position.y > floor_y + 78.0:
		return

	var cell_x := clampi(floori((position.x - 65.0) / 28.0), 0, ColonyNavigationGrid.MAP_WIDTH - 1)
	var cell_y := clampi(roundi((position.y - floor_y) / 12.0) + ColonyNavigationGrid.ELEVATOR_ROW, 0, ColonyNavigationGrid.MAP_HEIGHT - 1)
	var map_target := Vector3i(cell_x, cell_y, simulation.active_level)
	var target := Vector2i(cell_x, simulation.active_level)
	if build_mode:
		var building := _get_selected_building()
		if simulation.queue_map_construction(building, map_target):
			message = "Construcción de %s ordenada en la celda (%d, %d)." % [String(building), cell_x, cell_y]
		else:
			message = "No se puede construir ahí: revisa espacio, materiales y capa."
		_refresh_interface()
		queue_redraw()
		return
	if simulation.navigation.can_dig_map_cell(map_target):
		if simulation.queue_map_excavation(map_target):
			message = "Excavación 2D ordenada en la celda (%d, %d)." % [cell_x, cell_y]
		else:
			message = "No se pudo crear la orden de excavación."
		_refresh_interface()
		queue_redraw()
		return
	if cell_y == ColonyNavigationGrid.ELEVATOR_ROW and simulation.navigation.can_dig(target):
		if simulation.queue_excavation(target):
			message = "Excavación ordenada en la celda %d." % cell_x
		else:
			message = "No se pudo crear la orden de excavación."
		_refresh_interface()
		return
	message = "Toca una celda de roca para excavar o activa Construir para colocar una estructura."
	_refresh_interface()


func _draw_structures() -> void:
	# Refugio and warehouse are built into the shallow subsurface layer.
	draw_rect(Rect2(150, 330, 190, 60), Color("#67513f"))
	draw_rect(Rect2(165, 300, 160, 30), Color("#9a7654"))
	draw_rect(Rect2(180, 350, 42, 40), Color("#302b2b"))
	draw_rect(Rect2(245, 350, 42, 40), Color("#302b2b"))
	draw_string(ThemeDB.fallback_font, Vector2(165, 292), "REFUGIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	for bed_x in [7, 8, 9]:
		var bed_px := 65.0 + float(bed_x) * 28.0
		draw_rect(Rect2(bed_px - 11, 366, 22, 15), Color("#a9b4c0"))
		draw_rect(Rect2(bed_px - 9, 368, 18, 5), Color("#e4d6bd"))

	draw_rect(Rect2(410, 350, 135, 40), Color("#80623e"))
	draw_rect(Rect2(425, 330, 105, 20), Color("#b08a50"))
	draw_string(ThemeDB.fallback_font, Vector2(420, 322), "ALMACÉN", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

	# The workshop is located close to deep extraction sites.
	draw_rect(Rect2(180, 535, 145, 50), Color("#59616a"))
	draw_rect(Rect2(195, 515, 115, 20), Color("#8b9298"))
	draw_string(ThemeDB.fallback_font, Vector2(195, 507), "TALLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

	for structure in simulation.structures:
		var cell: Vector3i = structure.get("map_cell", Vector3i(int(structure.get("cell", Vector2i.ZERO).x), ColonyNavigationGrid.ELEVATOR_ROW, int(structure.get("level", 0))))
		if cell.z != simulation.active_level:
			continue
		var px := 65.0 + float(cell.x) * 28.0 + 14.0
		var floor_y: float = [205.0, 390.0, 585.0][cell.z]
		var py := floor_y + float(cell.y - ColonyNavigationGrid.ELEVATOR_ROW) * 12.0
		match StringName(structure.get("type", "")):
			&"bed":
				draw_rect(Rect2(px - 12.0, py - 8.0, 24.0, 14.0), Color("#a9b4c0"))
				draw_rect(Rect2(px - 10.0, py - 6.0, 20.0, 5.0), Color("#e4d6bd"))
			&"storage":
				draw_rect(Rect2(px - 13.0, py - 22.0, 26.0, 22.0), Color("#a77d45"))
				draw_rect(Rect2(px - 13.0, py - 22.0, 26.0, 22.0), Color("#e2bd78"), false, 2.0)
			&"workshop":
				draw_rect(Rect2(px - 14.0, py - 20.0, 28.0, 20.0), Color("#667583"))
				draw_rect(Rect2(px - 14.0, py - 20.0, 28.0, 20.0), Color("#b3c0c9"), false, 2.0)


func _draw_resource_nodes() -> void:
	for resource in simulation.resource_nodes:
		var node: ColonyResourceNode = simulation.resource_nodes[resource]
		if node.level != simulation.active_level:
			continue

		var px := 65.0 + float(node.map_cell.x) * 28.0 + 14.0
		var floor_y: float = [205.0, 390.0, 585.0][node.map_cell.z]
		var py := floor_y + float(node.map_cell.y - ColonyNavigationGrid.ELEVATOR_ROW) * 12.0
		var amount := node.available_units

		match resource:
			&"food":
				if simulation.crop_field.is_planted:
					draw_rect(Rect2(px - 3, py - 24, 6, 22), Color("#d5d0a0"))
					draw_circle(Vector2(px, py - 27), 9, Color("#c47b9b"))
					draw_circle(Vector2(px - 13, py - 20), 7, Color("#d48eaa"))
				else:
					draw_rect(Rect2(px - 18, py - 5, 36, 5), Color("#79573b"))
			&"water":
				draw_circle(Vector2(px, py - 10), 20, Color("#397eaa"))
				draw_arc(Vector2(px, py - 10), 20, 0.0, TAU, 32, Color("#8ed4ed"), 3.0)
			&"wood":
				draw_rect(Rect2(px - 5, py - 42, 10, 42), Color("#76513b"))
				draw_circle(Vector2(px, py - 45), 19, Color("#6e9b78"))
				draw_circle(Vector2(px - 12, py - 35), 12, Color("#86b58a"))
			&"stone":
				draw_colored_polygon(PackedVector2Array([
					Vector2(px - 22, floor_y),
					Vector2(px - 16, py - 24),
					Vector2(px + 2, py - 34),
					Vector2(px + 23, py - 12),
					Vector2(px + 20, floor_y)
				]), Color("#8c969f"))
			&"clay":
				draw_colored_polygon(PackedVector2Array([
					Vector2(px - 21, floor_y),
					Vector2(px - 15, py - 20),
					Vector2(px + 4, py - 25),
					Vector2(px + 22, py - 9),
					Vector2(px + 18, floor_y)
				]), Color("#a87953"))
			&"coal":
				draw_colored_polygon(PackedVector2Array([
					Vector2(px - 21, floor_y),
					Vector2(px - 15, py - 20),
					Vector2(px + 4, py - 25),
					Vector2(px + 22, py - 9),
					Vector2(px + 18, floor_y)
				]), Color("#292d33"))
			&"ore":
				draw_colored_polygon(PackedVector2Array([
					Vector2(px - 22, floor_y),
					Vector2(px - 17, floor_y - 22),
					Vector2(px + 2, py - 31),
					Vector2(px + 22, py - 10),
					Vector2(px + 19, floor_y)
				]), Color("#626d7c"))
				draw_circle(Vector2(px, py - 17), 5, Color("#d5a84f"))

		draw_string(
			ThemeDB.fallback_font,
			Vector2(px - 42, py - 54),
			"%s · %d" % [String(resource).to_upper(), amount],
			HORIZONTAL_ALIGNMENT_CENTER,
			84,
			11,
			Color("#f0dfbf")
		)


func _draw_colonists() -> void:
	var body_colors := [Color("#d6a56e"), Color("#c78d72"), Color("#9eb6c7")]

	for i in range(simulation.colonists.size()):
		var colonist: DwarfColonist = simulation.colonists[i]
		if not colonist.alive:
			continue

		var map_render_position: Vector2 = colonist.get_map_render_position()
		var render_layer := colonist.map_position.z
		if render_layer != simulation.active_level:
			continue
		var px := 65.0 + map_render_position.x * 28.0 + 14.0
		var floors := [205.0, 390.0, 585.0]
		var floor_y: float = floors[render_layer]
		var py := floor_y - 24.0 + (map_render_position.y - float(ColonyNavigationGrid.ELEVATOR_ROW)) * 12.0
		draw_circle(Vector2(px, py - 22), 13, Color("#d9b58b"))
		draw_rect(Rect2(px - 12, py - 12, 24, 27), body_colors[i % body_colors.size()])
		draw_rect(Rect2(px - 10, py + 13, 8, 12), Color("#403b3a"))
		draw_rect(Rect2(px + 2, py + 13, 8, 12), Color("#403b3a"))
		draw_string(ThemeDB.fallback_font, Vector2(px - 42, py - 48), colonist.display_name, HORIZONTAL_ALIGNMENT_CENTER, 84, 13, Color.WHITE)
		var needs_text := "H %02d  S %02d  F %02d" % [roundi(colonist.hunger), roundi(colonist.thirst), roundi(colonist.fatigue)]
		draw_string(ThemeDB.fallback_font, Vector2(px - 48, py - 34), needs_text, HORIZONTAL_ALIGNMENT_CENTER, 96, 10, Color("#f2d9a4"))


func _draw_level_marker() -> void:
	var labels := ["SUPERFICIE ACTIVA", "SUBSUELO ACTIVO", "PROFUNDIDAD ACTIVA"]
	var label: String = labels[simulation.active_level]
	draw_rect(Rect2(930, 150, 260, 38), Color("#17212c"))
	draw_string(ThemeDB.fallback_font, Vector2(950, 176), label, HORIZONTAL_ALIGNMENT_LEFT, 230, 17, Color("#f0c879"))


func _build_interface() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(root)

	var top := PanelContainer.new()
	top.position = Vector2(18, 14)
	top.size = Vector2(1244, 94)
	root.add_child(top)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 7)
	top.add_child(top_box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 23)
	top_box.add_child(title_label)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 16)
	top_box.add_child(status_label)

	var bottom := PanelContainer.new()
	bottom.position = Vector2(18, 666)
	bottom.size = Vector2(1244, 54)
	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = Color("#1f2937")
	bottom_style.set_content_margin_all(0.0)
	bottom.add_theme_stylebox_override("panel", bottom_style)
	root.add_child(bottom)

	var action_scroll := ScrollContainer.new()
	action_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bottom.add_child(action_scroll)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.add_child(row)

	_add_button(row, "Cambiar nivel", _switch_level)
	_add_button(row, "Comida", _gather_food)
	_add_button(row, "Agua", _gather_water)
	_add_button(row, "Extraer", _extract_resource)
	_add_button(row, "Cambiar recurso", _cycle_extraction_resource)
	_add_button(row, "Madera", _gather_wood)
	_add_button(row, "Sembrar", _plant_crops)
	_add_button(row, "Construir", _toggle_build_mode)
	_add_button(row, "Fabricar", _craft_tool)
	_add_button(row, "Guardar", _save_game)
	_add_button(row, "Modo", _cycle_game_mode)
	_add_button(row, "Pausar", _toggle_pause)

	message_label = Label.new()
	message_label.position = Vector2(24, 116)
	message_label.size = Vector2(1200, 20)
	message_label.add_theme_font_size_override("font_size", 17)
	message_label.add_theme_color_override("font_color", Color("#ffe0a1"))
	root.add_child(message_label)


func _add_button(parent: HBoxContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(115, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	action_buttons.append(button)


func _refresh_interface() -> void:
	if status_label == null:
		return

	var food := simulation.inventory.get_amount(&"food")
	var water := simulation.inventory.get_amount(&"water")
	var wood := simulation.inventory.get_amount(&"wood")
	var stone := simulation.inventory.get_amount(&"stone")
	var ore := simulation.inventory.get_amount(&"ore")
	var clay := simulation.inventory.get_amount(&"clay")
	var coal := simulation.inventory.get_amount(&"coal")
	var seeds := simulation.inventory.get_amount(&"seeds")
	var tools := simulation.inventory.get_amount(&"tools")
	var tool_condition := roundi(simulation.tool_durability)
	var active_orders := simulation.scheduler.get_active_orders_snapshot().size()

	title_label.text = "DWARF LAND     ·     %s     ·     DÍA %d     ·     %02d:00" % [simulation.get_game_mode_label().to_upper(), simulation.day, simulation.hour]
	status_label.text = "Comida: %d   Agua: %d   Semillas: %d   Madera: %d   Arcilla: %d   Piedra: %d   Carbón: %d   Mineral: %d   Herramientas: %d (%d%%)   |   Colonos: %d   Trabajos: %d" % [
		food, water, seeds, wood, clay, stone, coal, ore, tools, tool_condition, simulation.get_living_colonist_count(), active_orders
	]
	message_label.text = message
	if simulation.game_mode == &"campaign":
		var progress := simulation.get_campaign_progress()
		message_label.text = "Objetivo: almacén %s · taller %s · día 10 %s" % [
			"✓" if progress.storage_built else "—",
			"✓" if progress.workshop_built else "—",
			"✓" if progress.day_ten_reached else "—"
		]

	if action_buttons.size() > 11:
		action_buttons[3].text = "Extraer " + String(_get_selected_extraction_resource()).capitalize() if not _get_extraction_options().is_empty() else "Extraer"
		action_buttons[7].text = "Plano: " + String(_get_selected_building()).capitalize() if build_mode else "Construir"
		action_buttons[8].disabled = not simulation.has_workshop()
		action_buttons[10].text = "Modo: " + simulation.get_game_mode_label()
		action_buttons[11].text = "Reanudar" if simulation.paused else "Pausar"


func _on_alert_raised(alert_message: String, severity: int) -> void:
	message = alert_message
	if message_label != null:
		message_label.text = message
	if severity == ColonySimulation.ALERT_CRITICAL:
		message_label.add_theme_color_override("font_color", Color("#ff7777"))
	else:
		message_label.add_theme_color_override("font_color", Color("#ffe0a1"))


func _switch_level() -> void:
	simulation.switch_level()
	selected_extraction_index = 0
	selected_building_index = 0
	message = "Ahora estás en: %s." % ["Superficie", "Subsuelo", "Profundidad"][simulation.active_level]
	_refresh_interface()
	queue_redraw()


func _gather_food() -> void:
	if simulation.active_level != 0:
		message = "Los cultivos y la recolección de alimentos están en la superficie."
		_refresh_interface()
		return

	if simulation.queue_work(&"food", 3):
		message = "Trabajo de recolección de comida añadido a la cola."
	else:
		message = "No se pudo crear el trabajo de comida."
	_refresh_interface()


func _gather_water() -> void:
	if simulation.active_level != 1:
		message = "El agua subterránea se obtiene en el subsuelo."
		_refresh_interface()
		return

	if simulation.queue_work(&"water", 3):
		message = "Trabajo de abastecimiento de agua añadido a la cola."
	else:
		message = "No se pudo crear el trabajo de agua."
	_refresh_interface()


func _get_extraction_options() -> Array[StringName]:
	if simulation.active_level == 1:
		return [&"clay"]
	if simulation.active_level == 2:
		return [&"stone", &"ore", &"coal"]
	return []


func _get_selected_extraction_resource() -> StringName:
	var options := _get_extraction_options()
	if options.is_empty():
		return &""
	selected_extraction_index = clampi(selected_extraction_index, 0, options.size() - 1)
	return options[selected_extraction_index]


func _cycle_extraction_resource() -> void:
	var options := _get_extraction_options()
	if options.is_empty():
		message = "Los recursos minerales se extraen en el subsuelo y la profundidad."
	else:
		selected_extraction_index = (selected_extraction_index + 1) % options.size()
		message = "Recurso seleccionado: %s." % String(_get_selected_extraction_resource())
	_refresh_interface()


func _extract_resource() -> void:
	var resource := _get_selected_extraction_resource()
	if resource == &"":
		message = "Selecciona una capa subterránea para extraer recursos."
	elif simulation.queue_work(resource, 3):
		message = "Orden de extracción de %s añadida." % String(resource)
	else:
		message = "No hay reservas disponibles de %s o no se pudo crear el trabajo." % String(resource)
	_refresh_interface()


func _gather_wood() -> void:
	if simulation.active_level != 0:
		message = "La madera se obtiene de los árboles de la superficie."
		_refresh_interface()
		return

	if simulation.queue_work(&"wood", 3):
		message = "Trabajo de obtención de madera añadido a la cola."
	else:
		message = "No se pudo crear el trabajo de madera."
	_refresh_interface()



func _get_building_options() -> Array[StringName]:
	if simulation.active_level == 1:
		return [&"bed", &"storage", &"workshop"]
	return [&"storage", &"workshop"]


func _get_selected_building() -> StringName:
	var options := _get_building_options()
	selected_building_index = clampi(selected_building_index, 0, options.size() - 1)
	return options[selected_building_index]


func _toggle_build_mode() -> void:
	var options := _get_building_options()
	if not build_mode:
		build_mode = true
		selected_building_index = 0
		message = "Modo construcción: %s. Toca una celda libre." % String(_get_selected_building())
	elif selected_building_index < options.size() - 1:
		selected_building_index += 1
		message = "Plano seleccionado: %s. Toca una celda libre." % String(_get_selected_building())
	else:
		build_mode = false
		message = "Modo construcción desactivado."
	_refresh_interface()


func _plant_crops() -> void:
	if simulation.active_level != 0:
		message = "Los cultivos se siembran en la superficie."
	elif simulation.queue_planting():
		message = "Orden de siembra añadida. Se ha reservado una semilla."
	else:
		message = "No se puede sembrar: revisa el estado del campo y las semillas."
	_refresh_interface()





func _cycle_game_mode() -> void:
	var next_mode: StringName
	match simulation.game_mode:
		&"survival":
			next_mode = &"campaign"
		&"campaign":
			next_mode = &"sandbox"
		_:
			next_mode = &"survival"
	simulation.set_game_mode(next_mode)
	message = "Modo cambiado a %s." % simulation.get_game_mode_label()
	_refresh_interface()


func _save_game() -> void:
	if simulation.save_game():
		message = "Partida guardada correctamente en el dispositivo."
	else:
		message = "No se pudo guardar la partida."
	_refresh_interface()


func _craft_tool() -> void:
	if simulation.queue_crafting(&"tool"):
		message = "Fabricación de herramienta añadida al taller."
	else:
		message = "Necesitas un taller, 2 maderas y 1 mineral."
	_refresh_interface()


func _toggle_pause() -> void:
	simulation.set_paused(not simulation.paused)
	message = "Simulación pausada." if simulation.paused else "La colonia vuelve a trabajar."
	_refresh_interface()
