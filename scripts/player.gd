class_name Player extends CharacterBody2D

@export var move_speed: float = 300.0
@export var jump_velocity: float = -450.0
@export var skeleton: Skeleton2D
@export var animator: AnimationTree

var direction: float
var hit: bool

func spawn(spawn_pos: Vector2) -> void:
	direction = 0
	position = spawn_pos

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	hit = Input.is_action_pressed("hit")

	if hit:
		animator["parameters/HitFilter/blend_amount"] = 1.0
	else:
		animator["parameters/HitFilter/blend_amount"] = 0.0

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
