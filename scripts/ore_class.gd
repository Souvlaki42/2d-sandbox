@tool
extends Tile
class_name Ore

var noise: PerlinNoise = null

@export_range(0, 1) var rarity: float:
	set(new_value):
		rarity = new_value
		Globals.noise_settings_changed.emit()
		
@export_range(0, 1) var vein_size: float:
	set(new_value):
		vein_size = new_value
		Globals.noise_settings_changed.emit()
		
@export var max_spawn_height: int:
	set(new_value):
		max_spawn_height = new_value
		Globals.noise_settings_changed.emit()

@export var spread_image: Image
