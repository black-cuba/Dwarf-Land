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


func _ready() -> void:
	simulation.alert_raised.connect(_on_alert_raised)
	simulation.colony_changed.connect(_refresh_interface)
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
	if position.y < floor_y - 58.0 or position.y > floor_y + 18.0:
		return

	var cell_x := clampi(roundi((position.x - 65.0) / 28.0), 0, ColonyNavigationGrid.GRID_WIDTH - 1)
	var target := Vector2i(cell_x, simulation.active_level)
	if simulation.navigation.can_dig(target):
		if simulation.queue_excavation(target):
			message = "Excavación ordenada en la celda %d." % cell_x
		else:
			message = "No se pudo crear la orden de excavación."
		_refresh_interface()
		return
	message = "Selecciona un bloque de roca marcado para excavar."
	_refresh_interface()


func _draw_structures() -> void:
	# Refugio and warehouse are built into the shallow subsurface layer.
	draw_rect(Rect2(150, 330, 190, 60), Color("#67513f"))
	draw_rect(Rect2(165, 300, 160, 30), Color("#9a7654"))
	draw_rect(Rect2(180, 350, 42, 40), Color("#302b2b"))
	draw_rect(Rect2(245, 350, 42, 40), Color("#302b2b"))
	draw_string(ThemeDB.fallback_font, Vector2(165, 292), "REFUGIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

	draw_rect(Rect2(410, 350, 135, 40), Color("#80623e"))
	draw_rect(Rect2(425, 330, 105, 20), Color("#b08a50"))
	draw_string(ThemeDB.fallback_font, Vector2(420, 322), "ALMACÉN", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

	# The workshop is located close to deep extraction sites.
	draw_rect(Rect2(180, 535, 145, 50), Color("#59616a"))
	draw_rect(Rect2(195, 515, 115, 20), Color("#8b9298"))
	draw_string(ThemeDB.fallback_font, Vector2(195, 507), "TALLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)


func _draw_resource_nodes() -> void:
	for resource in simulation.resource_nodes:
		var node: ColonyResourceNode = simulation.resource_nodes[resource]
		if node.level != simulation.active_level:
			continue

		var px := 65.0 + float(node.cell.x) * 28.0
		var floor_y: float = [205.0, 390.0, 585.0][node.level]
		var amount := node.available_units

		match resource:
			&"food":
				draw_rect(Rect2(px - 3, floor_y - 24, 6, 22), Color("#d5d0a0"))
				draw_circle(Vector2(px, floor_y - 27), 9, Color("#c47b9b"))
				draw_circle(Vector2(px - 13, floor_y - 20), 7, Color("#d48eaa"))
			&"water":
				draw_circle(Vector2(px, floor_y - 10), 20, Color("#397eaa"))
				draw_arc(Vector2(px, floor_y - 10), 20, 0.0, TAU, 32, Color("#8ed4ed"), 3.0)
			&"wood":
				draw_rect(Rect2(px - 5, floor_y - 42, 10, 42), Color("#76513b"))
				draw_circle(Vector2(px, floor_y - 45), 19, Color("#6e9b78"))
				draw_circle(Vector2(px - 12, floor_y - 35), 12, Color("#86b58a"))
			&"stone":
				draw_colored_polygon(PackedVector2Array([
					Vector2(px - 22, floor_y),
					Vector2(px - 16, floor_y - 24),
					Vector2(px + 2, floor_y - 34),
					Vector2(px + 23, floor_y - 12),
					Vector2(px + 20, floor_y)
				]), Color("#8c969f"))
			&"clay":
				draw_colored_polygon(PackedVector2Array([
					Vector2(px - 21, floor_y),
					Vector2(px - 15, floor_y - 20),
					Vector2(px + 4, floor_y - 25),
					Vector2(px + 22, floor_y - 9),
					Vector2(px + 18, floor_y)
				]), Color("#a87953"))
			&"coal":
				draw_colored_polygon(PackedVector2Array([
					Vector2(px - 21, floor_y),
					Vector2(px - 15, floor_y - 20),
					Vector2(px + 4, floor_y - 25),
					Vector2(px + 22, floor_y - 9),
					Vector2(px + 18, floor_y)
				]), Color("#292d33"))
			&"ore":
				draw_colored_polygon(PackedVector2Array([
					Vector2(px - 22, floor_y),
					Vector2(px - 17, floor_y - 22),
					Vector2(px + 2, floor_y - 31),
					Vector2(px + 22, floor_y - 10),
					Vector2(px + 19, floor_y)
				]), Color("#626d7c"))
				draw_circle(Vector2(px, floor_y - 17), 5, Color("#d5a84f"))

		draw_string(
			ThemeDB.fallback_font,
			Vector2(px - 42, floor_y - 54),
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

		var render_position := colonist.get_render_position()
		if roundi(render_position.y) != simulation.active_level:
			continue
		var px := 65.0 + render_position.x * 28.0
		var floors := [205.0, 390.0, 585.0]
		var lower_level := clampi(floori(render_position.y), 0, 1)
		var floor_y := lerpf(floors[lower_level], floors[lower_level + 1], render_position.y - float(lower_level))
		var py := floor_y - 24.0
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
	top.size = Vector2(1244, 102)
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
	bottom.position = Vector2(18, 620)
	bottom.size = Vector2(1244, 82)
	root.add_child(bottom)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bottom.add_child(row)

	_add_button(row, "Cambiar nivel", _switch_level)
	_add_button(row, "Recolectar comida", _gather_food)
	_add_button(row, "Recoger agua", _gather_water)
	_add_button(row, "Extraer piedra", _mine_stone)
	_add_button(row, "Cortar madera", _gather_wood)
	_add_button(row, "Pausar", _toggle_pause)

	message_label = Label.new()
	message_label.position = Vector2(24, 575)
	message_label.size = Vector2(900, 32)
	message_label.add_theme_font_size_override("font_size", 17)
	message_label.add_theme_color_override("font_color", Color("#ffe0a1"))
	root.add_child(message_label)


func _add_button(parent: HBoxContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(185, 54)
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
	var active_orders := simulation.scheduler.get_active_orders_snapshot().size()

	title_label.text = "DWARF LAND     ·     DÍA %d     ·     %02d:00" % [simulation.day, simulation.hour]
	status_label.text = "Comida: %d   Agua: %d   Madera: %d   Arcilla: %d   Piedra: %d   Carbón: %d   Mineral: %d   |   Colonos: %d   Trabajos: %d" % [
		food, water, wood, clay, stone, coal, ore, simulation.get_living_colonist_count(), active_orders
	]
	message_label.text = message

	if action_buttons.size() > 5:
		action_buttons[5].text = "Reanudar" if simulation.paused else "Pausar"


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


func _mine_stone() -> void:
	if simulation.active_level != 2:
		message = "La piedra se extrae en la zona profunda."
		_refresh_interface()
		return

	if simulation.queue_work(&"stone", 3):
		message = "Trabajo de extracción de piedra añadido a la cola."
	else:
		message = "No se pudo crear el trabajo de piedra."
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


func _toggle_pause() -> void:
	simulation.set_paused(not simulation.paused)
	message = "Simulación pausada." if simulation.paused else "La colonia vuelve a trabajar."
	_refresh_interface()
