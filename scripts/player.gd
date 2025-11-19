extends Camera2D
class_name PlayerCamera

@export_group("Movement")
@export var move_speed: float = 600.0
@export var drag_sensitivity: float = 1.0

@export_group("Zoom")
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.05
@export var max_zoom: float = 10.0
@export var zoom_smoothness: float = 15.0 

var target_zoom: Vector2
var is_dragging: bool = false

func _ready() -> void:
	target_zoom = zoom

func _process(delta: float) -> void:
	handle_movement(delta)
	handle_zoom(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cam_pan"):
		is_dragging = true
	elif event.is_action_released("cam_pan"):
		is_dragging = false
		
	if is_dragging and event is InputEventMouseMotion:
		position -= event.relative * drag_sensitivity / zoom.x

	if event.is_action_pressed("cam_zoom_in", true):
		zoom_towards_mouse(1.0 + zoom_speed)
	elif event.is_action_pressed("cam_zoom_out", true):
		zoom_towards_mouse(1.0 - zoom_speed)

func handle_movement(delta: float) -> void:
	if is_dragging: return

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		position += direction * move_speed * delta * (1.0 / zoom.x)

func handle_zoom(delta: float) -> void:
	if not is_equal_approx(zoom.x, target_zoom.x):
		zoom = zoom.lerp(target_zoom, zoom_smoothness * delta)

func zoom_towards_mouse(zoom_factor: float) -> void:
	var old_zoom = target_zoom
	var new_zoom = old_zoom * zoom_factor
	
	new_zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	
	var mouse_world_pos = get_global_mouse_position()
	var zoom_ratio = old_zoom.x / new_zoom.x
	var diff = mouse_world_pos - global_position
	
	target_zoom = new_zoom
	global_position += diff * (1.0 - zoom_ratio)
