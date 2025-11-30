@tool
class_name TileAtlas extends Resource

@export_category("Environment")
@export var grass: Tile
@export var dirt: Tile
@export var stone: Tile
@export var addons: Tile
@export var tree_log: Tile
@export var tree_leaves: Tile
@export var snow: Tile
@export var sand: Tile

@export_category("Ores")
@export var coal: Ore
@export var iron: Ore
@export var gold: Ore
@export var diamond: Ore

func get_ores() -> Array[Ore]:
	var ores: Array[Ore] = []
	if coal != null:
		ores.push_back(coal)
	if iron != null:
		ores.push_back(iron)
	if gold != null:
		ores.push_back(gold)
	if diamond != null:
		ores.push_back(diamond)
	return ores
