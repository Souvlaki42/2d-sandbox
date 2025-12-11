class_name Game
extends Node2D

@export var day_length_seconds: float = 120.0
@export var orbit_radius: float = 1000.0
@export var world: TerrainGenerator

var orbit_center: Vector2
var angle: float = 0.0


func _physics_process(delta: float) -> void:
	orbit_center = world.player.camera.global_position
	angle = fmod(angle + (TAU / day_length_seconds) * delta, TAU)

	var sun_pos = orbit_center + Vector2(
		cos(angle + PI) * orbit_radius,
		sin(angle + PI) * orbit_radius,
	)
	world.sun.global_position = sun_pos

	var moon_pos = orbit_center + Vector2(
		cos(angle) * orbit_radius,
		sin(angle) * orbit_radius,
	)
	world.moon.global_position = moon_pos
