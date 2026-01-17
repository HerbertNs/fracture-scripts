extends Node

# --- Assign windows in the editor ---
@export var windows: Array[Window] = []
@onready var main_window : Window = get_window()
@export var window_size: Vector2i = Vector2i(32, 32)
func _ready():
	_setup_main_window()
	# Share main world to all subwindows
	for w in windows:
		if w:
			w.world_2d = main_window.world_2d


# ---------------------------
# WINDOW CONTROL FUNCTIONS
# ---------------------------

# Trigger collapse for a specific window
func collapse_window(window_node: Window):
	if window_node and window_node.has_method("start_collapse"):
		window_node.start_collapse()

# Trigger oscillate for a specific window
func oscillate_window(window_node: Window, direction: Vector2, amplitude: float, speed: float):
	if window_node and window_node.has_method("set_oscillate"):
		window_node.set_oscillate(direction, amplitude, speed)

# Trigger unstable for a specific window
func unstable_window(window_node: Window):
	if window_node and window_node.has_method("set_unstable"):
		window_node.set_unstable

func _setup_main_window():
	# Apply window settings
	main_window.borderless = true
	main_window.unresizable = true
	main_window.always_on_top = true
	main_window.gui_embed_subwindows = false
	main_window.transparent = true
	main_window.transparent_bg = true
	main_window.min_size = window_size
	main_window.size = main_window.min_size
	ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", true)

	# Optional: minimize on launch
	main_window.mode = Window.MODE_MINIMIZED

# ---------------------------
# EXAMPLES / DEMO KEYBIND
# ---------------------------

func _process(delta):
	#oscillate_window(windows[0], Vector2(1, 0), 150, 1.0)
	#unstable_window(windows[0])
	# Example: collapse second window
	if Input.is_action_just_pressed("collapse") and windows.size() > 1:
		collapse_window(windows[2])

	# Example: make first window oscillate
	if Input.is_action_just_pressed("ui_accept") and windows.size() > 0:
		pass

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
