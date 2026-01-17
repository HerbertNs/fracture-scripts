extends Node

@onready var _MainWindow: Window = get_window()
@onready var _SubWindow: Window = $Window
@onready var _Window2: Window = $Window2
@onready var _Window3: Window = $Window3
@onready var _Window4: Window = $Window4
@export  var player_size: Vector2i = Vector2i(32, 32)

## Oscillation
#@export var osc_amplitude: int = 150      # pixels left/right from center
#@export var osc_speed: float = 0.377   # radians per second
#@export var osc_axis := Vector2i(0, 1)      # (1,0)=horizontal, (0,1)=vertical
#var osc_active := true
#var osc_time := 0.0
#var osc_origin: Vector2i
var window_origins := {}

##window positions.
#take the window positions and make them 
#screen 1920x1080 px
const WINDOW_LAYOUT := {
	"window_1" : Vector2(0.039 ,  0.314),
	"window_2" : Vector2(0.2021,  0.416),
	"window_3" : Vector2(0.4469,  0.416),
	"window_4" : Vector2(0.7526,  0.314)
}





func _ready():
	#place_window($Window, WINDOW_LAYOUT["window_1"])
	#place_window($Window2, WINDOW_LAYOUT["window_2"])
	#place_window($Window3, WINDOW_LAYOUT["window_3"])
	#place_window($Window4, WINDOW_LAYOUT["window_4"])

	for w in [$Window, $Window2, $Window3]:
		window_origins[w] = w.position
	# Share world
	_SubWindow.world_2d = _MainWindow.world_2d
	_Window2.world_2d = _MainWindow.world_2d
	_Window3.world_2d = _MainWindow.world_2d
#	_Window4.world_2d = _MainWindow.world_2d
	
	ProjectSettings.set_setting(
		"display/window/per_pixel_transparency/allowed",
		true
	)
	_MainWindow.borderless = true
	_MainWindow.unresizable = true
	_MainWindow.always_on_top = true
	_MainWindow.gui_embed_subwindows = false
	_MainWindow.transparent = true
	_MainWindow.transparent_bg = true
	_MainWindow.min_size = player_size
	_MainWindow.size = _MainWindow.min_size
	_MainWindow.MODE_MINIMIZED
	

#	osc_origin = _Window3.position



func _physics_process(delta: float) -> void:pass
	
	#osc_time += delta
#
	#oscillate_window($Window2, window_origins[$Window2], Vector2(1,0),osc_amplitude, osc_speed, osc_time)
	#oscillate_window($Window, window_origins[$Window], Vector2(0,0.1),osc_amplitude, osc_speed, osc_time)
	#oscillate_window($Window3, window_origins[$Window3], Vector2(-1,0).normalized(),osc_amplitude, osc_speed, osc_time)
#
#func oscillate_window(
	#window: Window,
	#origin: Vector2i,
	#direction: Vector2,
	#amplitude: int,
	#speed: float,
	#time: float
#) -> void:
	#var offset := sin(time * speed) * amplitude
	#var move := Vector2i(
		#int(direction.x * offset),
		#int(direction.y * offset)
	#)
#
	#window.position = origin + move
#
#func place_window(window: Window, ratio: Vector2) -> void:
	#var screen := DisplayServer.window_get_current_screen()
	#var screen_size := DisplayServer.screen_get_size(screen)
#
	#var pixel_pos := Vector2i(
		#int(screen_size.x * ratio.x),
		#int(screen_size.y * ratio.y)
	#)
#
	#window.position = pixel_pos
