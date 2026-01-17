extends Window

## Layout 
@export var base_resolution := Vector2(1920, 1080)
@export var authored_position := Vector2(0, 0)
@export var authored_size := Vector2(640, 360)
@export var pixel_snap := true
var position_ratio := Vector2.ZERO
var size_ratio := Vector2.ZERO
var base_pos: Vector2
var base_size: Vector2
##Camera
@onready var camera: Camera2D = $Camera2D
var last_window_pos: Vector2i
## State machine 
enum WindowState { STATIC, OSCILLATE, UNSTABLE, COLLAPSE }
@export var state: WindowState = WindowState.STATIC
var previous_state: WindowState = WindowState.STATIC
##Offsets applied by states
var state_offset := Vector2.ZERO
var shake_offset := Vector2.ZERO
##Oscillate
@export var osc_dir := Vector2.RIGHT
@export var osc_amp := 10.0
@export var osc_speed := 6.0
@export var osc_time := 0.0
##Unstable
@export var unstable_enabled := true
@export var unstable_strength := 8.0
@export var unstable_speed := 12.0
@export var unstable_time := 0.0
##Collapse
var collapse_timer := 0.0
const UNSTABLE_TIME := 4.0
const AGGRESSIVE_TIME := 3.0
const SHRINK_TIME := 0.4
const RESTORE_TIME := 0.6
var shrink_start_size := Vector2.ZERO
var collapse_shake_time := 0.0


func _ready():
	# Layout
	_convert_authored_to_ratios()
	_apply_layout_from_ratios()

	# Camera
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	camera.position = Vector2(position)
	last_window_pos = position

	transient = true
	close_requested.connect(queue_free)

func _process(delta):
	_update_state(delta)
	_apply_state_transform()
	_update_camera()


##custom  Layout management,uses a reference ratio to scale the windows and positions
##instead of the default which resets on launvh.


func _convert_authored_to_ratios():
	position_ratio = authored_position / base_resolution
	size_ratio = authored_size / base_resolution

func _apply_layout_from_ratios():
	var screen_id := DisplayServer.window_get_current_screen(get_window_id())
	var screen_size := Vector2(DisplayServer.screen_get_size(screen_id))

	base_pos = (position_ratio * screen_size).floor()
	base_size = (size_ratio * screen_size).floor()

	position = base_pos
	size = base_size


# Camera stuff
func _update_camera():
	camera.position = Vector2(position)


##STATE MACHINES.


func _update_state(delta):
	match state:
		WindowState.OSCILLATE:
			osc_time += delta
			state_offset = osc_dir.normalized() * sin(osc_time * osc_speed) * osc_amp

		WindowState.UNSTABLE:
			if unstable_enabled:
				unstable_time += delta
				shake_offset = Vector2(
					sin(unstable_time * unstable_speed * 1.3) * unstable_strength,
					cos(unstable_time * unstable_speed * 0.9) * unstable_strength * 0.8
				)
			else:
				# If unstable is disabled, return to previous state
				state = previous_state

		WindowState.COLLAPSE:
			_process_collapse(delta)

		_:
			state_offset = Vector2.ZERO
			shake_offset = Vector2.ZERO

func _apply_state_transform():
	position = (base_pos + state_offset + shake_offset).floor()


# Collapse sequence

func _process_collapse(delta):
	collapse_timer += delta
	collapse_shake_time += delta

	if collapse_timer < UNSTABLE_TIME:
		var _t := collapse_timer / UNSTABLE_TIME  
		var intensity := 1.0  
		shake_offset = Vector2(
			sin(collapse_shake_time * 15.0) * unstable_strength * intensity,
			cos(collapse_shake_time * 12.0) * unstable_strength * intensity
		)

	elif collapse_timer < UNSTABLE_TIME + AGGRESSIVE_TIME:
		var t := (collapse_timer - UNSTABLE_TIME) / AGGRESSIVE_TIME 
		var intensity := 1.0 + t * 1.0 
		shake_offset = Vector2(
			sin(collapse_shake_time * 20.0) * unstable_strength * intensity,
			cos(collapse_shake_time * 16.0) * unstable_strength * intensity
		)

	elif collapse_timer < UNSTABLE_TIME + AGGRESSIVE_TIME + SHRINK_TIME:
		if shrink_start_size == Vector2.ZERO:
			shrink_start_size = size

		var t := (collapse_timer - UNSTABLE_TIME - AGGRESSIVE_TIME) / SHRINK_TIME
		var new_size := shrink_start_size.lerp(Vector2(5, 5), t).floor()

		size = new_size
		position = base_pos + base_size * 0.5 - new_size * 0.5

	elif collapse_timer < UNSTABLE_TIME + AGGRESSIVE_TIME + SHRINK_TIME + RESTORE_TIME:
		var t := (collapse_timer - UNSTABLE_TIME - AGGRESSIVE_TIME - SHRINK_TIME) / RESTORE_TIME
		var new_size := Vector2(5, 5).lerp(base_size, t).floor()

		size = new_size
		position = base_pos + base_size * 0.5 - new_size * 0.5

	else:
		size = base_size
		state = previous_state
		collapse_timer = 0.0
		shrink_start_size = Vector2.ZERO
		collapse_shake_time = 0.0


## External window manager API 

func set_oscillate(dir: Vector2, amplitude: float, speed: float):
	osc_dir = dir
	osc_amp = amplitude
	osc_speed = speed
	state = WindowState.OSCILLATE

func set_unstable():
	state = WindowState.UNSTABLE

func start_collapse():
	if state != WindowState.COLLAPSE:
		previous_state = state
		state = WindowState.COLLAPSE
		collapse_timer = 0.0
