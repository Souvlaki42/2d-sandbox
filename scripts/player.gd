class_name Player extends CharacterBody2D

@export var move_speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var sprite_root: Sprite2D
@export var animations: AnimationPlayer

@onready var direction: float = 0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * move_speed
		if direction > 0:
			sprite_root.scale.x = -1
		if direction < 0:
			sprite_root.scale.x = 1
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)

	move_and_slide()
