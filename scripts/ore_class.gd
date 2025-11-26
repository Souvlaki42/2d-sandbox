@tool
extends Tile
class_name Ore

var noise: PerlinNoise = null

@export var rarity: float:
	set(new_value):
		rarity = new_value
		Globals.noise_settings_changed.emit()
		
@export var vein_size: float:
	set(new_value):
		vein_size = new_value
		Globals.noise_settings_changed.emit()

@export var spread_image: Image
