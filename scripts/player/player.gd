@icon("res://assets/icons/node_2D/icon_character.png")
class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var action_range: int = 5
@export var move_speed: float = 300.0
@export var jump_height: float = 1.2

@export_category("Animation")
@export var skeleton: Skeleton2D
@export var animator: AnimationTree

@export_category("View")
@export var camera: Camera2D
@export var world: Terrain

@export_category("Skin")
@export var skin: CharacterSkin
@export var head: Sprite2D
@export var body: Sprite2D
@export var left_arm: Sprite2D
@export var right_arm: Sprite2D
@export var left_leg: Sprite2D
@export var right_leg: Sprite2D

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var selected_tile: Tile
var direction: float

var mouse_coords: Vector2i
var coords: Vector2i
var current_tile: Terrain.WorldTile
var jump_velocity: float

var pathfinder: AStarGrid2D

func _ready() -> void:
	direction = 0
	jump_velocity = - sqrt(2 * jump_height * world.tile_size * gravity)
	world.set_limits()
	
	pathfinding_setup()

	head.texture = skin.head
	body.texture = skin.body
	left_arm.texture = skin.arms
	right_arm.texture = skin.arms
	left_leg.texture = skin.legs
	right_leg.texture = skin.legs
	
func set_obstacle(cell: Vector2i, solid: bool) -> void:
	if pathfinder and pathfinder.is_in_boundsv(cell):
		pathfinder.set_point_solid(cell, solid)

func pathfinding_setup() -> void:
	pathfinder = AStarGrid2D.new()
		
	pathfinder.cell_size = world.foreground.tile_set.tile_size
	pathfinder.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	pathfinder.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	pathfinder.region = world.foreground.get_used_rect()
	pathfinder.update()

	for cell in world.foreground.get_used_cells():
		if pathfinder.is_in_boundsv(cell):
			pathfinder.set_point_solid(cell)
	
func is_reachable(target: Vector2i) -> bool:
	var distance: int = absi(coords.x - target.x) + absi(coords.y - target.y)

	if distance <= 0 or distance > action_range:
		return false

	for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var stand_position := target + dir

		if not pathfinder.is_in_boundsv(stand_position):
			continue

		if pathfinder.is_point_solid(stand_position):
			continue

		var path := pathfinder.get_id_path(coords, stand_position)

		if not path.is_empty():
			return true

	return false
	
func show_debug() -> void:
		var selected_tile_name: StringName = selected_tile.tile_name if selected_tile else StringName("None")
		var current_tile_name: StringName = current_tile.chosen_tile.tile_name if current_tile else StringName("None")
	
		world.debug.add_debug_property("FPS", Engine.get_frames_per_second())
		world.debug.add_debug_property("Player Coordinates", coords)
		world.debug.add_debug_property("Mouse Coordinates", mouse_coords)
		world.debug.add_debug_property("Selected Tile", selected_tile_name)
		world.debug.add_debug_property("Current Tile", current_tile_name)
		world.debug.add_debug_property("Seed", world.noise_seed)
		world.debug.add_debug_property("Reachable", is_reachable(mouse_coords))

func _process(_delta: float) -> void:
	coords = world.foreground.local_to_map(world.foreground.to_local(global_position))
	mouse_coords = world.foreground.local_to_map(world.foreground.to_local(get_global_mouse_position()))
	current_tile = world.world_tiles.get(mouse_coords)

	direction = Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("select") and current_tile:
		selected_tile = current_tile.chosen_tile
	
	# todo: maybe check this only when interacting
	var in_range: bool = is_reachable(mouse_coords)

	var is_hitting: bool = animator.get("parameters/OneShot/active")
	
	if in_range and not is_hitting and Input.is_action_just_pressed("attack"):
		animator.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		world.remove_tile(mouse_coords)
	elif in_range and not is_hitting and Input.is_action_just_pressed("place"):
		animator.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		world.place_tile(selected_tile, mouse_coords, world.foreground, false)
		
	if world.debug.visible:
		show_debug()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if direction:
		velocity.x = direction * move_speed
		if direction > 0:
			skeleton.scale.x = -1
		if direction < 0:
			skeleton.scale.x = 1
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)

	move_and_slide()
