extends PointLight2D

@export var flicker_min_energy: float = 0.85
@export var flicker_max_energy: float = 1.25
@export var flicker_speed: float = 7.0
@export var flicker_interval: float = 0.06
@export var color_variation: float = 0.05 # 0 = no color change

var _target_energy: float
var _target_color: Color
var _timer: float = 0.0

func _ready():
	_target_energy = energy
	_target_color = color

func _process(delta: float):
	_timer -= delta
	if _timer <= 0.0:
		_target_energy = randf_range(flicker_min_energy, flicker_max_energy)
		# Slight hue variation (warm flicker)
		var hue_shift = randf_range(-color_variation, color_variation)
		_target_color = color.from_hsv(clamp(color.h + hue_shift, 0.0, 1.0), color.s, color.v)
		_timer = flicker_interval + randf() * 0.05

	energy = lerp(energy, _target_energy, delta * flicker_speed)
	color = color.lerp(_target_color, delta * flicker_speed)
