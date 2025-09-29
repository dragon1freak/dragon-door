extends CharacterBody3D


@export_group("Controls")
## Base sensitivity
@export var mouse_sensitivity : float = 3.0
@export var gamepad_sensitivity := 0.075
@export_group("")

const SPEED = 5.0
const JUMP_VELOCITY = 4.5


var rotation_target: Vector3

@onready var pivot: Node3D = $Pivot

func _physics_process(delta: float) -> void:
	# Handles rotations if a rotation target exists
	if rotation_target:
		pivot.rotation.x = lerp_angle(pivot.rotation.x, rotation_target.x, delta * 25) # Rotate camera pivot up and down
		rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25) # Rotate player left and right
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


## Handles mouse aiming
func handle_mouse_look(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_target.y -= event.relative.x / mouse_sensitivity / 100
		rotation_target.x -= event.relative.y / mouse_sensitivity / 100
		rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))


func _input(event) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	handle_mouse_look(event)
