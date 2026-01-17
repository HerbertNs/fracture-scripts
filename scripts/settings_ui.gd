extends Control

var master_bus_index = AudioServer.get_bus_index("Master")
var sfx_bus_index = AudioServer.get_bus_index("SFX")
var music_bus_index = AudioServer.get_bus_index("MUSIC")

#func _on_volume_value_changed(value: float) -> void:
	#AudioServer.set_bus_volume_db(0,value)

#RESOLUTION OPTIONS
func _on_resolutions_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600,900))
		2:
			DisplayServer.window_set_size(Vector2i(1280,720))
		3:
			DisplayServer.window_set_size(Vector2i(1152,648))
		4:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		5:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		6:
			$MarginContainer/VBoxContainer/MasterVolumeSlider
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


#VOLUME SLIDERS
func _on_master_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
	
func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))


#SETTING UP VSYNC
func _on_vsync_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		1:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
