class_name Tile
extends Resource

@export var tile_name: StringName
@export var wall_variant: Tile
@export var source_id: int = 1
@export var atlas_coords: Array[Vector2i] = [Vector2i.ZERO]
@export var is_background: bool = false
@export var is_droppable: bool = true
