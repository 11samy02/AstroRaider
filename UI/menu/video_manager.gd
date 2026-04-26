extends Node

@onready var left_device_display: Button = %left_device_display
@onready var display_selected_text: Button = %display_selected_text
@onready var right_device_display: Button = %right_device_display

@onready var left_device_resolution: Button = %left_device_resolution
@onready var resolution_selected_text: Button = %resolution_selected_text
@onready var right_device_resolution: Button = %right_device_resolution

@onready var left_device_monitor: Button = %left_device_monitor
@onready var monitor_selected_text: Button = %monitor_selected_text
@onready var right_device_monitor: Button = %right_device_monitor

@onready var left_device_fps: Button = %left_device_fps
@onready var fps_selected_text: Button = %fps_selected_text
@onready var right_device_fps: Button = %right_device_fps

@onready var vsync_on_checkbox: CheckButton = %Vsync_on_checkbox

var selected_monitor := 0

var display_modes := [
	DisplayServer.WINDOW_MODE_WINDOWED,
	DisplayServer.WINDOW_MODE_FULLSCREEN,
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
]

var display_mode_names := [
	"Windowed",
	"Fullscreen",
	"Exclusive"
]

var base_resolutions := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3440, 1440),
	Vector2i(3840, 2160)
]

var resolutions: Array[Vector2i] = []

var base_fps_limits := [
	0,
	30,
	60,
	120,
	144,
	165,
	240,
	360
]

var fps_limits: Array[int] = []


func _ready() -> void:
	selected_monitor = DisplayServer.window_get_current_screen()
	refresh_dynamic_options()
	connect_signals()
	update_all_texts()


func connect_signals() -> void:
	left_device_display.pressed.connect(change_display_mode.bind(false))
	right_device_display.pressed.connect(change_display_mode.bind(true))

	left_device_resolution.pressed.connect(change_resolution.bind(false))
	right_device_resolution.pressed.connect(change_resolution.bind(true))

	left_device_monitor.pressed.connect(change_monitor.bind(false))
	right_device_monitor.pressed.connect(change_monitor.bind(true))

	left_device_fps.pressed.connect(change_fps_limit.bind(false))
	right_device_fps.pressed.connect(change_fps_limit.bind(true))

	vsync_on_checkbox.toggled.connect(vsync_checkbox_pressed)


func refresh_dynamic_options() -> void:
	refresh_resolutions()
	refresh_fps_limits()


func refresh_resolutions() -> void:
	resolutions.clear()

	var screen_size := DisplayServer.screen_get_size(selected_monitor)

	for res in base_resolutions:
		if res.x <= screen_size.x and res.y <= screen_size.y:
			resolutions.append(res)

	if resolutions.is_empty():
		resolutions.append(screen_size)

	if not resolutions.has(screen_size):
		resolutions.append(screen_size)

	resolutions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x * a.y < b.x * b.y
	)


func refresh_fps_limits() -> void:
	fps_limits.clear()
	
	var refresh_rate := int(round(DisplayServer.screen_get_refresh_rate(selected_monitor)))
	
	for fps in base_fps_limits:
		if fps == 0:
			fps_limits.append(fps)
		elif refresh_rate <= 0 or fps <= refresh_rate:
			fps_limits.append(fps)
	
	if refresh_rate > 0 and not fps_limits.has(refresh_rate):
		fps_limits.append(refresh_rate)
	
	fps_limits.sort()
	
	if fps_limits.has(0):
		fps_limits.erase(0)
		fps_limits.push_front(0)


func update_all_texts() -> void:
	update_display_text()
	update_resolution_text()
	update_monitor_text()
	update_fps_text()
	update_vsync_checkbox()


func get_current_display_index() -> int:
	var current := DisplayServer.window_get_mode()

	for i in display_modes.size():
		if display_modes[i] == current:
			return i

	return 0


func update_display_text() -> void:
	var index := get_current_display_index()
	display_selected_text.text = display_mode_names[index]


func change_display_mode(goes_forward: bool) -> void:
	var index := get_current_display_index()

	if goes_forward:
		index += 1
		if index >= display_modes.size():
			index = 0
	else:
		index -= 1
		if index < 0:
			index = display_modes.size() - 1

	DisplayServer.window_set_current_screen(selected_monitor)
	DisplayServer.window_set_mode(display_modes[index])

	if display_modes[index] == DisplayServer.WINDOW_MODE_WINDOWED:
		center_window_on_selected_monitor()

	update_display_text()
	update_resolution_text()
	update_monitor_text()


func get_current_resolution_index() -> int:
	if resolutions.is_empty():
		refresh_resolutions()

	var current := DisplayServer.window_get_size()

	for i in resolutions.size():
		if resolutions[i] == current:
			return i

	var closest_index := 0
	var closest_distance := INF

	for i in resolutions.size():
		var distance = abs(resolutions[i].x - current.x) + abs(resolutions[i].y - current.y)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = i

	return closest_index


func update_resolution_text() -> void:
	if resolutions.is_empty():
		refresh_resolutions()

	var index := get_current_resolution_index()
	var res := resolutions[index]
	resolution_selected_text.text = str(res.x) + " x " + str(res.y)


func change_resolution(goes_forward: bool) -> void:
	if resolutions.is_empty():
		refresh_resolutions()

	var index := get_current_resolution_index()

	if goes_forward:
		index += 1
		if index >= resolutions.size():
			index = 0
	else:
		index -= 1
		if index < 0:
			index = resolutions.size() - 1

	var new_size := resolutions[index]

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_current_screen(selected_monitor)
	DisplayServer.window_set_size(new_size)
	center_window_on_selected_monitor()

	update_display_text()
	update_resolution_text()
	update_monitor_text()


func update_monitor_text() -> void:
	var screen_count := DisplayServer.get_screen_count()

	if screen_count <= 0:
		monitor_selected_text.text = "Monitor 1"
		return

	selected_monitor = clamp(selected_monitor, 0, screen_count - 1)

	var screen_size := DisplayServer.screen_get_size(selected_monitor)
	var refresh_rate := DisplayServer.screen_get_refresh_rate(selected_monitor)

	if refresh_rate > 0:
		monitor_selected_text.text = "Monitor " + str(selected_monitor + 1) + " (" + str(screen_size.x) + " x " + str(screen_size.y) + " @ " + str(roundi(refresh_rate)) + "Hz)"
	else:
		monitor_selected_text.text = "Monitor " + str(selected_monitor + 1) + " (" + str(screen_size.x) + " x " + str(screen_size.y) + ")"


func change_monitor(goes_forward: bool) -> void:
	var screen_count := DisplayServer.get_screen_count()

	if screen_count <= 0:
		return

	if goes_forward:
		selected_monitor += 1
		if selected_monitor >= screen_count:
			selected_monitor = 0
	else:
		selected_monitor -= 1
		if selected_monitor < 0:
			selected_monitor = screen_count - 1

	DisplayServer.window_set_current_screen(selected_monitor)

	refresh_dynamic_options()

	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		center_window_on_selected_monitor()

	update_all_texts()


func center_window_on_selected_monitor() -> void:
	var screen_count := DisplayServer.get_screen_count()

	if screen_count <= 0:
		return

	selected_monitor = clamp(selected_monitor, 0, screen_count - 1)

	var screen_pos := DisplayServer.screen_get_position(selected_monitor)
	var screen_size := DisplayServer.screen_get_size(selected_monitor)
	var window_size := DisplayServer.window_get_size()

	DisplayServer.window_set_position(screen_pos + ((screen_size - window_size) / 2))


func get_current_fps_index() -> int:
	if fps_limits.is_empty():
		refresh_fps_limits()

	var current := Engine.max_fps

	for i in fps_limits.size():
		if fps_limits[i] == current:
			return i

	return 0


func update_fps_text() -> void:
	if fps_limits.is_empty():
		refresh_fps_limits()

	var index := get_current_fps_index()
	var fps := fps_limits[index]

	if fps <= 0:
		fps_selected_text.text = "Unlimited"
	else:
		fps_selected_text.text = str(fps) + " FPS"


func change_fps_limit(goes_forward: bool) -> void:
	if fps_limits.is_empty():
		refresh_fps_limits()

	var index := get_current_fps_index()

	if goes_forward:
		index += 1
		if index >= fps_limits.size():
			index = 0
	else:
		index -= 1
		if index < 0:
			index = fps_limits.size() - 1

	Engine.max_fps = fps_limits[index]
	update_fps_text()


func update_vsync_checkbox() -> void:
	vsync_on_checkbox.set_block_signals(true)
	vsync_on_checkbox.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	vsync_on_checkbox.set_block_signals(false)


func vsync_checkbox_pressed(toggle_on: bool) -> void:
	if toggle_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
