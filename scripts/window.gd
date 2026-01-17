extends Window

@onready var _MainWindow : Window = get_focused_window()
@onready var _SubWindow : Window  = $"."
@onready var player_size :Vector2i = Vector2i(32,32)

func _ready() -> void:
	_SubWindow.world_2d = _MainWindow.world_2d
	ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed" , true)
	
	_MainWindow.borderless = true
	_MainWindow.unresizable = true
	_MainWindow.always_on_top = true
	_MainWindow.gui_embed_subwindows = false
	_MainWindow.transparent = true
	_MainWindow.transparent_bg = true
	
	_MainWindow.min_size = player_size
	_MainWindow.size = _MainWindow.min_size
