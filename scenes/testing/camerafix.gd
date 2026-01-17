extends "res://scenes/testing/layout_window_test.gd"



#@export var base_resolution := Vector2(1920, 1080)
#@export var authored_position := Vector2(0, 0)
#@export var authored_size := Vector2(640, 360)
#@export var pixel_snap := true
#
#@onready var camera: Camera2D = $Camera2D
#
#var position_ratio := Vector2.ZERO
#var size_ratio := Vector2.ZERO
#
#var last_window_pos: Vector2i
#var window_velocity: Vector2i

func _ready():
	# --- Layout ---
	_convert_authored_to_ratios()
	_apply_layout_from_ratios()

	# --- Camera setup ---
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	camera.position = Vector2.ZERO

	last_window_pos = position

	transient = true
	close_requested.connect(queue_free)

func _process(_delta):
	_update_camera_from_window()

# -------------------------
# Layout
# -------------------------

func _convert_authored_to_ratios():
	position_ratio = authored_position / base_resolution
	size_ratio = authored_size / base_resolution

func _apply_layout_from_ratios():
	var screen_id := DisplayServer.window_get_current_screen(get_window_id())
	var screen_size := Vector2(DisplayServer.screen_get_size(screen_id))

	var new_pos := position_ratio * screen_size
	var new_size := size_ratio * screen_size

	if pixel_snap:
		new_pos = new_pos.floor()
		new_size = new_size.floor()

	position = new_pos
	size = new_size

# -------------------------
# Camera logic (IMPORTANT)
# -------------------------

func _update_camera_from_window():
	var current_pos: Vector2i = position
	window_velocity = current_pos - last_window_pos
	last_window_pos = current_pos

	# Camera looks at world position matching window screen position
	camera.position = Vector2(position)
