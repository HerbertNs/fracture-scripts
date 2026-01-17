#region
##fallback
#extends Window
#
#@export var base_resolution := Vector2(1920, 1080)
#@export var authored_position := Vector2(0, 0)
#@export var authored_size := Vector2(640, 360)
#@export var pixel_snap := true
#var position_ratio := Vector2.ZERO
#var size_ratio := Vector2.ZERO
#var origin_pos : Vector2
#var origin_size : Vector2
#
#func _ready():
	#_convert_authored_to_ratios()
	#_apply_layout_from_ratios()
#
#func _convert_authored_to_ratios():
	#position_ratio = Vector2(
		#authored_position.x / base_resolution.x,
		#authored_position.y / base_resolution.y
	#)
#
	#size_ratio = Vector2(
		#authored_size.x / base_resolution.x,
		#authored_size.y / base_resolution.y
	#)
#
#func _apply_layout_from_ratios():
	#var screen_id := DisplayServer.window_get_current_screen(get_window_id())
	#var screen_size := Vector2(DisplayServer.screen_get_size(screen_id))
#
	#var new_position := position_ratio * screen_size
	#var new_size := size_ratio * screen_size
#
	#if pixel_snap:
		#new_position = new_position.floor()
		#new_size = new_size.floor()
#
	#position = new_position
	#size = new_size
	#
	#origin_pos = position
	#origin_size = size
#endregion

extends Window

# -------------------------------------------------
# LAYOUT (RATIO-BASED, AUTHOR-FRIENDLY)
# -------------------------------------------------
@onready var camera: Camera2D = $Camera2D
var last_window_pos: Vector2i
var window_velocity: Vector2i
@export var base_resolution := Vector2(1920, 1080)
@export var authored_position := Vector2(0, 0)
@export var authored_size := Vector2(640, 360)
@export var pixel_snap := true

var position_ratio := Vector2.ZERO
var size_ratio := Vector2.ZERO

var origin_pos : Vector2
var origin_size : Vector2

# -------------------------------------------------
# STATE MACHINE
# -------------------------------------------------

enum State {
	STATIC,
	OSCILLATE,
	COLLAPSING
}

@export var current_state : State = State.STATIC
var previous_state : State
var time := 0.0

# -------------------------------------------------
# OSCILLATE
# -------------------------------------------------

@export var osc_direction := Vector2(1, 0)
@export var osc_amplitude := 120.0
@export var osc_speed := 1.0

# -------------------------------------------------
# UNSTABLE
# -------------------------------------------------

@export var unstable := false
@export var shake_strength := 4.0
@export var breathe_strength := 0.03

# -------------------------------------------------
# COLLAPSE
# -------------------------------------------------

@export var unstable_duration := 4.0
@export var aggressive_duration := 3.0
@export var shrink_duration := 0.5
@export var restore_duration := 0.5

var collapse_timer := 0.0
var collapse_osc_offset := Vector2.ZERO

var shrink_start_size := Vector2.ZERO
var shrink_end_size := Vector2(5, 5)
var restore_start_size := Vector2.ZERO

# -------------------------------------------------
# READY
# -------------------------------------------------

func _ready():
	_convert_authored_to_ratios()
	_apply_layout_from_ratios()
	
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	last_window_pos = position
	
	transient = true
	close_requested.connect(queue_free)
	
# -------------------------------------------------
# LAYOUT (ONE-TIME / MANAGER-DRIVEN)
# -------------------------------------------------

func _convert_authored_to_ratios():
	position_ratio = authored_position / base_resolution
	size_ratio = authored_size / base_resolution

func _apply_layout_from_ratios():
	var screen_id := DisplayServer.window_get_current_screen(get_window_id())
	var screen_size := Vector2(DisplayServer.screen_get_size(screen_id))

	var new_position := position_ratio * screen_size
	var new_size := size_ratio * screen_size

	if pixel_snap:
		new_position = new_position.floor()
		new_size = new_size.floor()

	position = new_position
	size = new_size

	origin_pos = position
	origin_size = size


# -------------------------------------------------
# PROCESS
#var screen_offset: Vector2
#func _physics_process(delta: float) -> void:
	## Camera position stays fixed relative to the world
	## Only update if you want shake/oscillation visual effects
	## Otherwise, do NOT move the camera based on window.position
	#camera.position = Vector2.ZERO
# -------------------------------------------------

func _process(delta):
	time += delta

	if current_state == State.COLLAPSING:
		_update_collapse(delta)
		return

	var pos_offset := Vector2.ZERO
	var size_offset := Vector2.ZERO

	if current_state == State.OSCILLATE:
		pos_offset += _oscillate_offset()

	if unstable:
		pos_offset += _unstable_offset()
		size_offset += _breathe_offset()
	position = (origin_pos + pos_offset).round()
	size = (origin_size + size_offset).round()
	
	#camera
	
	window_velocity = position - last_window_pos
	last_window_pos = position

	_apply_camera_compensation()

func _apply_camera_compensation():
	# Move camera opposite to window motion
	camera.position -= Vector2(window_velocity)
	camera.position = camera.position.round()

# -------------------------------------------------
# OSCILLATE
# -------------------------------------------------

func _oscillate_offset() -> Vector2:
	return osc_direction.normalized() * sin(time * osc_speed) * osc_amplitude

# -------------------------------------------------
# UNSTABLE
# -------------------------------------------------

func _unstable_offset() -> Vector2:
	return Vector2(
		sin(time * 14.0),
		cos(time * 13.0)
	) * shake_strength

func _breathe_offset() -> Vector2:
	var v := sin(time * 2.0) * breathe_strength
	return origin_size * v

# -------------------------------------------------
# COLLAPSE CONTROL
# -------------------------------------------------

func start_collapse():
	if current_state == State.COLLAPSING:
		return

	previous_state = current_state
	collapse_timer = 0.0
	shrink_start_size = Vector2.ZERO
	restore_start_size = Vector2.ZERO

	collapse_osc_offset = (
		_oscillate_offset()
		if current_state == State.OSCILLATE
		else Vector2.ZERO
	)

	current_state = State.COLLAPSING

# -------------------------------------------------
# COLLAPSE SEQUENCE
# -------------------------------------------------

func _update_collapse(delta):
	collapse_timer += delta

	var p1 := unstable_duration
	var p2 := p1 + aggressive_duration
	var p3 := p2 + shrink_duration
	var p4 := p3 + restore_duration

	# Phase 1 – unstable
	if collapse_timer < p1:
		unstable = true
		position = (origin_pos + collapse_osc_offset + _unstable_offset()).round()
		return

	# Phase 2 – aggressive unstable
	if collapse_timer < p2:
		unstable = true
		position = (origin_pos + collapse_osc_offset + _unstable_offset() * 3.0).round()
		return

	# Phase 3 – shrink
	if collapse_timer < p3:
		if shrink_start_size == Vector2.ZERO:
			shrink_start_size = size

		var t := (collapse_timer - p2) / shrink_duration
		var new_size := shrink_start_size.lerp(shrink_end_size, t)
		size = new_size.round()
		position = origin_pos + collapse_osc_offset + origin_size * 0.5 - new_size * 0.5
		return

	# Phase 4 – restore
	if collapse_timer < p4:
		if restore_start_size == Vector2.ZERO:
			restore_start_size = shrink_end_size

		var t := (collapse_timer - p3) / restore_duration
		var new_size := restore_start_size.lerp(origin_size, t)
		size = new_size.round()
		position = origin_pos + collapse_osc_offset + origin_size * 0.5 - new_size * 0.5
		return

	# Finish
	current_state = previous_state
	unstable = false
	collapse_timer = 0.0
	time = 0.0
