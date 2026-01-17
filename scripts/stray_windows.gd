extends Node

@export var shake_strength := 3
@export var shake_interval := 0.04

@export var breathe_amplitude := 2
@export var breathe_speed := 1.3

const WINDOW_LAYOUT := {
	"window_1" : Vector2(0.354,   0.300),   #stray
	"window_2" : Vector2(0.263,   0.468),   #stray3
	"window_3" : Vector2(0.671,   0.425),   #stray5
	"window_4" : Vector2(0.312,   0.611)    #stray2
}

var _windows := []
var _origins := {}
var _sizes := {}

var _shake_timer := 0.0
var _shake_offsets := {}
var _breathe_time := 0.0

func _ready():
	place_window($stray, WINDOW_LAYOUT["window_1"])
	place_window($stray3, WINDOW_LAYOUT["window_2"])
	place_window($stray5, WINDOW_LAYOUT["window_3"])
	place_window($stray2, WINDOW_LAYOUT["window_4"])
	var main_world := get_window().world_2d

	for w in get_children():
		if w is Window:
			w.world_2d = main_world

			_windows.append(w)
			_origins[w] = w.position
			_sizes[w] = w.size
			_shake_offsets[w] = Vector2i.ZERO

	randomize()

func _process(delta):
	_update_shake(delta)
	_update_breath(delta)
	_apply_motion()

func _update_shake(delta):
	_shake_timer += delta
	if _shake_timer >= shake_interval:
		_shake_timer = 0.0
		for w in _windows:
			_shake_offsets[w] = Vector2i(
				randi_range(-shake_strength, shake_strength),
				randi_range(-shake_strength, shake_strength)
			)

func _update_breath(delta):
	_breathe_time += delta

func _apply_motion():
	for w in _windows:
		var h := int(sin(_breathe_time * breathe_speed) * breathe_amplitude)

		w.size.y = _sizes[w].y + h
		w.position = _origins[w] + _shake_offsets[w] - Vector2i(0, h / 2)


func place_window(window: Window, ratio: Vector2) -> void:
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)

	var pixel_pos := Vector2i(
		int(screen_size.x * ratio.x),
		int(screen_size.y * ratio.y)
	)

	window.position = pixel_pos
