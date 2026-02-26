@icon("res://assets/icons/node_2D/icon_character.png")
class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var action_range: int
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

var hit: bool
var place: bool
var select: bool

var mouse_coords: Vector2i
var coords: Vector2i
var current_tile: Terrain.WorldTile
var jump_velocity: float


func _ready() -> void:
	direction = 0
	jump_velocity = -sqrt(2 * jump_height * world.tile_size * gravity)
	world.set_limits()

	head.texture = skin.head
	body.texture = skin.body
	left_arm.texture = skin.arms
	right_arm.texture = skin.arms
	left_leg.texture = skin.legs
	right_leg.texture = skin.legs


func _process(_delta: float) -> void:
	coords = world.get_coordinates_from_position(global_position)
	mouse_coords = world.get_coordinates_from_position(get_global_mouse_position())
	current_tile = world.world_tiles.get(mouse_coords)

	if world.debug.visible:
		var selected_tile_name: StringName = selected_tile.tile_name if selected_tile else StringName("None")
		var current_tile_name: StringName = current_tile.chosen_tile.tile_name if current_tile else StringName("None")

		world.debug.add_debug_property("FPS", Engine.get_frames_per_second())
		world.debug.add_debug_property("Player Coordinates", coords)
		world.debug.add_debug_property("Mouse Coordinates", mouse_coords)
		world.debug.add_debug_property("Selected Tile", selected_tile_name)
		world.debug.add_debug_property("Current Tile", current_tile_name)
		world.debug.add_debug_property("Seed", world.noise_seed)

	hit = Input.is_action_pressed("hit")
	place = Input.is_action_pressed("place")

	select = Input.is_action_pressed("select")
	direction = Input.get_axis("move_left", "move_right")

	if select and current_tile and current_tile.chosen_layer == world.foreground:
		selected_tile = current_tile.chosen_tile

	var in_range: bool = (
		mouse_coords != coords and
		mouse_coords != Vector2i(coords.x, coords.y + 1) and
		coords.distance_to(mouse_coords) <= action_range
	)

	if in_range and hit:
		animator["parameters/ActionFilter/blend_amount"] = 1.0
		world.remove_tile(mouse_coords.x, mouse_coords.y)
	elif in_range and place:
		animator["parameters/ActionFilter/blend_amount"] = 1.0
		world.place_tile(selected_tile, mouse_coords.x, mouse_coords.y)
	else:
		animator["parameters/ActionFilter/blend_amount"] = 0.0


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
