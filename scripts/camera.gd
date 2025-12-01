class_name PlayerCamera extends Camera2D

@export_range(0, 1) var smooth_time: float
@export var player_transform: Node2D

func _physics_process(_delta: float) -> void:
	position = lerp(position, player_transform.position, smooth_time)
