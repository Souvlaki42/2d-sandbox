class_name Player
extends CharacterBody2D

@export var action_range: int
@export var move_speed: float = 300.0
@export var jump_velocity: float = -450.0
@export var smooth_time: float = 0.1
@export var skeleton: Skeleton2D
@export var animator: AnimationTree
@export var camera: Camera2D
@export var world: TerrainGenerator

var selected_tile: Tile
var direction: float

var hit: bool
var place: bool
var select: bool

var mouse_coords: Vector2i
var coords: Vector2i
var current_tile: TerrainGenerator.WorldTile


func spawn(spawn_pos: Vector2) -> void:
	direction = 0
	position = spawn_pos
	world.limit_camera_position(camera)


func _physics_process(delta: float) -> void:
	camera.global_position = lerp(camera.global_position, global_position, smooth_time)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	coords = world.get_coordinates_from_position(global_position)
	mouse_coords = world.get_coordinates_from_position(get_global_mouse_position())
	current_tile = world.world_tiles.get(mouse_coords)

	if world.debug.visible:
		var selected_tilename: StringName = selected_tile.tile_name if selected_tile else StringName("None")
		var tile_under_mouse: StringName = current_tile.chosen_tile.tile_name if current_tile else StringName("None")

		world.debug.add_debug_property("FPS", Engine.get_frames_per_second())
		world.debug.add_debug_property("Coordinates", coords)
		world.debug.add_debug_property("Mouse Coordinates", mouse_coords)
		world.debug.add_debug_property("Selected Tile", selected_tilename)
		world.debug.add_debug_property("Tile under mouse", tile_under_mouse)

	select = Input.is_action_pressed("select")
	if select and current_tile and current_tile.chosen_layer == world.foreground:
		selected_tile = current_tile.chosen_tile

	if mouse_coords != coords and mouse_coords != Vector2i(coords.x, coords.y + 1) and coords.distance_to(mouse_coords) <= action_range:
		hit = Input.is_action_pressed("hit")
		place = Input.is_action_pressed("place")

		if hit:
			animator["parameters/ActionFilter/blend_amount"] = 1.0
			world.remove_tile(mouse_coords.x, mouse_coords.y)
		elif place:
			animator["parameters/ActionFilter/blend_amount"] = 1.0
			world.place_tile(selected_tile, mouse_coords.x, mouse_coords.y)
		else:
			animator["parameters/ActionFilter/blend_amount"] = 0.0

	direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * move_speed
		if direction > 0:
			skeleton.scale.x = -1
		if direction < 0:
			skeleton.scale.x = 1
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)

	move_and_slide()
