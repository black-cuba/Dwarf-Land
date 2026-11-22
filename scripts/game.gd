extends Node2D

const WORLD_WIDTH := 1280.0
const WORLD_HEIGHT := 720.0
const TICK_SECONDS := 4.0

var simulation := ColonySimulation.new()
var tick_timer := 0.0
var message := "La colonia necesita comida, agua y refugio."
var worker_positions: Array[float] = [250.0, 500.0, 760.0]

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
	if simulation.paused:
		return

	tick_timer += delta
	while tick_timer >= TICK_SECONDS:
		tick_timer -= TICK_SECONDS
		simulation.advance_hour()
		queue_redraw()


func _draw() -> void:
	_draw_cavern()
	_draw_structures()
	_draw_colonists()
	_draw_level_marker()


func _draw_cavern() -> void:
	draw_rect(Rect2(0, 0, WORLD_WIDTH, WORLD_HEIGHT), Color("#111827"))
	draw_rect(Rect2(0, 130, WORLD_WIDTH, 480), Color("#202a36"))

	for i in range(16):
		var x := float(i) * 88.0
		draw_rect(Rect2(x, 155 + (i % 3) * 12, 56, 9), Color("#344252"))
		draw_rect(Rect2(x + 24, 570 + (i % 4) * 8, 70, 7), Color("#303d4b"))

	# Dos plataformas jugables y un único eje de conexión.
	draw_rect(Rect2(45, 330, 1190, 18), Color("#8b6548"))
	draw_rect(Rect2(45, 570, 1190, 18), Color("#8b6548"))
	draw_rect(Rect2(45, 348, 1190, 7), Color("#513d32"))
	draw_rect(Rect2(45, 588, 1190, 7), Color("#513d32"))
	draw_string(ThemeDB.fallback_font, Vector2(65, 305), "NIVEL 1 · REFUGIO Y PRODUCCIÓN", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8d6b5"))
	draw_string(ThemeDB.fallback_font, Vector2(65, 545), "NIVEL 2 · EXTRACCIÓN Y MATERIALES", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8d6b5"))

	draw_rect(Rect2(1080, 260, 70, 330), Color("#495565"), false, 5.0)
	draw_line(Vector2(1115, 265), Vector2(1115, 575), Color("#c7a66a"), 3.0)
	var lift_y := 330.0 if simulation.active_level == 0 else 570.0
	draw_circle(Vector2(1115, lift_y), 10.0, Color("#f4c76b"))


func _draw_structures() -> void:
	# Nivel 1: refugio y almacén. Las instalaciones funcionales se implementarán
	# mediante el sistema de construcción, no con estas formas de presentación.
	draw_rect(Rect2(150, 270, 190, 60), Color("#67513f"))
	draw_rect(Rect2(165, 240, 160, 30), Color("#9a7654"))
	draw_rect(Rect2(180, 290, 42, 40), Color("#302b2b"))
	draw_rect(Rect2(245, 290, 42, 40), Color("#302b2b"))
	draw_string(ThemeDB.fallback_font, Vector2(165, 230), "REFUGIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

	draw_rect(Rect2(410, 290, 135, 40), Color("#80623e"))
	draw_rect(Rect2(425, 270, 105, 20), Color("#b08a50"))
	draw_string(ThemeDB.fallback_font, Vector2(420, 258), "ALMACÉN", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

	# Nivel 2: taller y representación geológica.
	draw_rect(Rect2(180, 520, 145, 50), Color("#59616a"))
	draw_rect(Rect2(195, 500, 115, 20), Color("#8b9298"))
	draw_string(ThemeDB.fallback_font, Vector2(195, 490), "TALLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	for i in range(5):
		var rock_position := Vector2(450 + i * 35, 555 - (i % 2) * 16)
		draw_circle(rock_position, 13, Color("#77818b"))
		draw_circle(rock_position, 6, Color("#a9b0b7"))


func _draw_colonists() -> void:
	var floor_y := 330.0 if simulation.active_level == 0 else 570.0
	var body_colors := [Color("#d6a56e"), Color("#c78d72"), Color("#9eb6c7")]

	for i in range(simulation.colonists.size()):
		var colonist: DwarfColonist = simulation.colonists[i]
		if not colonist.alive:
			continue

		var colonist_floor_y := 330.0 if colonist.current_level == 0 else 570.0
		if colonist.current_level != simulation.active_level:
			continue
		var px := worker_positions[i % worker_positions.size()]
		var py := colonist_floor_y - 24.0
		draw_circle(Vector2(px, py - 22), 13, Color("#d9b58b"))
		draw_rect(Rect2(px - 12, py - 12, 24, 27), body_colors[i % body_colors.size()])
		draw_rect(Rect2(px - 10, py + 13, 8, 12), Color("#403b3a"))
		draw_rect(Rect2(px + 2, py + 13, 8, 12), Color("#403b3a"))
		draw_string(ThemeDB.fallback_font, Vector2(px - 42, py - 42), colonist.display_name, HORIZONTAL_ALIGNMENT_CENTER, 84, 13, Color.WHITE)


func _draw_level_marker() -> void:
	var label := "REFUGIO ACTIVO" if simulation.active_level == 0 else "MINA ACTIVA"
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
	var active_orders := simulation.scheduler.get_active_orders_snapshot().size()

	title_label.text = "DWARF LAND     ·     DÍA %d     ·     %02d:00" % [simulation.day, simulation.hour]
	status_label.text = "Comida: %d   Agua: %d   Madera: %d   Piedra: %d   Mineral: %d   |   Colonos: %d   Trabajos: %d" % [
		food, water, wood, stone, ore, simulation.get_living_colonist_count(), active_orders
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
	message = "Ahora estás en el nivel %d de 2." % (simulation.active_level + 1)
	_refresh_interface()
	queue_redraw()


func _gather_food() -> void:
	if simulation.active_level != 0:
		message = "La producción de alimentos se gestiona en el nivel 1."
		_refresh_interface()
		return

	if simulation.queue_work(&"food", 3):
		message = "Trabajo de recolección de comida añadido a la cola."
	else:
		message = "No se pudo crear el trabajo de comida."
	_refresh_interface()


func _gather_water() -> void:
	if simulation.active_level != 0:
		message = "El abastecimiento de agua se gestiona en el nivel 1."
		_refresh_interface()
		return

	if simulation.queue_work(&"water", 3):
		message = "Trabajo de abastecimiento de agua añadido a la cola."
	else:
		message = "No se pudo crear el trabajo de agua."
	_refresh_interface()


func _mine_stone() -> void:
	if simulation.active_level != 1:
		message = "La extracción de piedra se realiza en el nivel 2."
		_refresh_interface()
		return

	if simulation.queue_work(&"stone", 3):
		message = "Trabajo de extracción de piedra añadido a la cola."
	else:
		message = "No se pudo crear el trabajo de piedra."
	_refresh_interface()


func _gather_wood() -> void:
	if simulation.active_level != 0:
		message = "La tala y preparación de madera se gestiona en el nivel 1."
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
