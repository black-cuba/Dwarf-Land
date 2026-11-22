extends Node2D

const WORLD_WIDTH := 1280.0
const WORLD_HEIGHT := 720.0
const TICK_SECONDS := 4.0

var active_level := 0
var day := 1
var hour := 7
var paused := false
var tick_timer := 0.0
var message := "El refugio necesita agua, comida y descanso."

var supplies := {
	"food": 24,
	"water": 30,
	"wood": 18,
	"stone": 12
}

var workers := [
	{"name": "Borin", "x": 250.0, "hunger": 12.0, "thirst": 10.0, "fatigue": 15.0, "health": 100.0, "job": "Recolector"},
	{"name": "Dora", "x": 500.0, "hunger": 18.0, "thirst": 12.0, "fatigue": 8.0, "health": 100.0, "job": "Agricultora"},
	{"name": "Krag", "x": 760.0, "hunger": 8.0, "thirst": 18.0, "fatigue": 22.0, "health": 100.0, "job": "Minero"}
]

var hud: CanvasLayer
var status_label: Label
var message_label: Label
var level_label: Label
var action_buttons: Array[Button] = []


func _ready() -> void:
	_build_interface()
	queue_redraw()


func _process(delta: float) -> void:
	if paused:
		return
	tick_timer += delta
	if tick_timer >= TICK_SECONDS:
		tick_timer = 0.0
		_simulate_tick()
	queue_redraw()


func _draw() -> void:
	_draw_cavern()
	_draw_structures()
	_draw_workers()
	_draw_level_marker()


func _draw_cavern() -> void:
	draw_rect(Rect2(0, 0, WORLD_WIDTH, WORLD_HEIGHT), Color("#111827"))
	draw_rect(Rect2(0, 130, WORLD_WIDTH, 480), Color("#202a36"))
	# Geological strata and rock silhouettes.
	for i in range(16):
		var x := float(i) * 88.0
		draw_rect(Rect2(x, 155 + (i % 3) * 12, 56, 9), Color("#344252"))
		draw_rect(Rect2(x + 24, 570 + (i % 4) * 8, 70, 7), Color("#303d4b"))
	# The two playable underground floors.
	draw_rect(Rect2(45, 330, 1190, 18), Color("#8b6548"))
	draw_rect(Rect2(45, 570, 1190, 18), Color("#8b6548"))
	draw_rect(Rect2(45, 348, 1190, 7), Color("#513d32"))
	draw_rect(Rect2(45, 588, 1190, 7), Color("#513d32"))
	draw_string(ThemeDB.fallback_font, Vector2(65, 305), "NIVEL 1 · REFUGIO Y PRODUCCIÓN", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8d6b5"))
	draw_string(ThemeDB.fallback_font, Vector2(65, 545), "NIVEL 2 · EXTRACCIÓN Y MATERIALES", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8d6b5"))
	# Lift shaft connects the two floors; it does not create another level.
	draw_rect(Rect2(1080, 260, 70, 330), Color("#495565"), false, 5.0)
	draw_line(Vector2(1115, 265), Vector2(1115, 575), Color("#c7a66a"), 3.0)
	draw_circle(Vector2(1115, active_level == 0 ? 330.0 : 570.0), 10.0, Color("#f4c76b"))


func _draw_structures() -> void:
	# Upper level: shelter, food store and beds.
	draw_rect(Rect2(150, 270, 190, 60), Color("#67513f"))
	draw_rect(Rect2(165, 240, 160, 30), Color("#9a7654"))
	draw_rect(Rect2(180, 290, 42, 40), Color("#302b2b"))
	draw_rect(Rect2(245, 290, 42, 40), Color("#302b2b"))
	draw_string(ThemeDB.fallback_font, Vector2(165, 230), "REFUGIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_rect(Rect2(410, 290, 135, 40), Color("#80623e"))
	draw_rect(Rect2(425, 270, 105, 20), Color("#b08a50"))
	draw_string(ThemeDB.fallback_font, Vector2(420, 258), "ALMACÉN", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	# Lower level: mine and a simple workbench.
	draw_rect(Rect2(180, 520, 145, 50), Color("#59616a"))
	draw_rect(Rect2(195, 500, 115, 20), Color("#8b9298"))
	draw_string(ThemeDB.fallback_font, Vector2(195, 490), "TALLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	for i in range(5):
		draw_circle(Vector2(450 + i * 35, 555 - (i % 2) * 16), 13, Color("#77818b"))
		draw_circle(Vector2(450 + i * 35, 555 - (i % 2) * 16), 6, Color("#a9b0b7"))


func _draw_workers() -> void:
	var floor_y := 330.0 if active_level == 0 else 570.0
	for i in range(workers.size()):
		var worker: Dictionary = workers[i]
		var px: float = float(worker["x"])
		var py := floor_y - 24.0
		var body_color := [Color("#d6a56e"), Color("#c78d72"), Color("#9eb6c7")][i]
		draw_circle(Vector2(px, py - 22), 13, Color("#d9b58b"))
		draw_rect(Rect2(px - 12, py - 12, 24, 27), body_color)
		draw_rect(Rect2(px - 10, py + 13, 8, 12), Color("#403b3a"))
		draw_rect(Rect2(px + 2, py + 13, 8, 12), Color("#403b3a"))
		draw_string(ThemeDB.fallback_font, Vector2(px - 38, py - 42), str(worker["name"]), HORIZONTAL_ALIGNMENT_CENTER, 76, 13, Color.WHITE)


func _draw_level_marker() -> void:
	var label := "REFUGIO ACTIVO" if active_level == 0 else "MINA ACTIVA"
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

	var title := Label.new()
	title.text = "DWARF LAND     ·     DÍA %d     ·     %02d:00" % [day, hour]
	title.add_theme_font_size_override("font_size", 23)
	top_box.add_child(title)

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

	_add_button(row, "Nivel: cambiar", _switch_level)
	_add_button(row, "Recolectar comida", _gather_food)
	_add_button(row, "Recoger agua", _gather_water)
	_add_button(row, "Extraer piedra", _mine_stone)
	_add_button(row, "Descansar", _rest_workers)
	_add_button(row, "Pausar", _toggle_pause)

	message_label = Label.new()
	message_label.position = Vector2(24, 575)
	message_label.size = Vector2(900, 32)
	message_label.add_theme_font_size_override("font_size", 17)
	message_label.add_theme_color_override("font_color", Color("#ffe0a1"))
	root.add_child(message_label)
	_refresh_interface()


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
	status_label.text = "Comida: %d   Agua: %d   Madera: %d   Piedra: %d   |   Colonos: %d" % [
		supplies["food"], supplies["water"], supplies["wood"], supplies["stone"], workers.size()
	]
	message_label.text = message
	var title_node := hud.get_child(0).get_child(0).get_child(0) as Label
	title_node.text = "DWARF LAND     ·     DÍA %d     ·     %02d:00" % [day, hour]
	if action_buttons.size() > 5:
		action_buttons[5].text = "Reanudar" if paused else "Pausar"


func _simulate_tick() -> void:
	hour += 2
	if hour >= 24:
		hour = 0
		day += 1
		supplies["food"] = maxi(0, int(supplies["food"]) - workers.size() * 2)
		supplies["water"] = maxi(0, int(supplies["water"]) - workers.size() * 2)
	for worker in workers:
		worker["hunger"] = minf(100.0, float(worker["hunger"]) + 3.0)
		worker["thirst"] = minf(100.0, float(worker["thirst"]) + 4.0)
		worker["fatigue"] = minf(100.0, float(worker["fatigue"]) + 2.0)
		if float(worker["hunger"]) > 85.0 or float(worker["thirst"]) > 85.0:
			worker["health"] = maxf(0.0, float(worker["health"]) - 2.0)
		worker["x"] = clampf(float(worker["x"]) + randf_range(-24.0, 24.0), 140.0, 980.0)
	if supplies["food"] <= 5 or supplies["water"] <= 5:
		message = "¡Alerta! Las reservas son bajas. Produce o recolecta recursos."
	else:
		message = "La colonia sigue trabajando. Revisa las necesidades de cada colono."
	_refresh_interface()


func _switch_level() -> void:
	active_level = 1 - active_level
	message = "Ahora estás viendo el nivel %d de 2." % (active_level + 1)
	_refresh_interface()
	queue_redraw()


func _gather_food() -> void:
	supplies["food"] = int(supplies["food"]) + 6
	message = "Se han almacenado 6 raciones de comida."
	_refresh_interface()


func _gather_water() -> void:
	supplies["water"] = int(supplies["water"]) + 8
	message = "Se han almacenado 8 unidades de agua."
	_refresh_interface()


func _mine_stone() -> void:
	if active_level != 1:
		message = "La extracción de piedra se realiza en el nivel 2."
	else:
		supplies["stone"] = int(supplies["stone"]) + 5
		message = "Los mineros han extraído 5 unidades de piedra."
	_refresh_interface()


func _rest_workers() -> void:
	for worker in workers:
		worker["fatigue"] = maxf(0.0, float(worker["fatigue"]) - 20.0)
	message = "Los colonos han descansado. El tiempo de simulación sigue activo."
	_refresh_interface()


func _toggle_pause() -> void:
	paused = not paused
	message = "Simulación pausada." if paused else "La colonia vuelve a trabajar."
	_refresh_interface()
