class_name GameCamera extends Camera2D

@export_range(0, 1) var smooth_time: float
@export var player_transform: Node2D

func spawn(spawn_pos: Vector2) -> void:
	position = spawn_pos

func _physics_process(_delta: float) -> void:
	position = lerp(position, player_transform.position, smooth_time)
