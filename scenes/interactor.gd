extends RayCast3D
class_name Interactor
## The raycast used to interact with things.  Can be disabled

## Emits the state of the interactor.  Can be used to show and hide HUD elements
## for interacting such as pips or button prompts
signal can_interact_changed(can_interact)


## Disables the interactor.  This can be set in code with set_disabled or in the inspector.
@export var disabled := false

## If true, the player can interact with the current target
var can_interact := false

var previous_interactable_collider
var current_interactee : Node3D


@onready var hud: Control = %HUD


## Returns true if the target exists and has the correct method
func check_can_interact(target: Node3D) -> bool:
	if not target:
		return false
	
	if target.has_method("interact"):
		return true
	elif target.get_parent_node_3d() and target.get_parent_node_3d().has_method("interact"):
		return true
	return false


func _get_interactable(start_node: Node3D) -> Node3D:
	if not start_node:
		return null
	
	if start_node.has_method("interact"):
		return start_node
	elif start_node.get_parent():
		return _get_interactable(start_node.get_parent())
	return null


## Sets the local can_interact variable and emits the can_interact_changed signal
func set_can_interact(value : bool) -> void:
	if value and not can_interact:
		can_interact = true
		can_interact_changed.emit(true)
	if not value and can_interact:
		can_interact = false
		can_interact_changed.emit(false)
		current_interactee = null


func _physics_process(_delta):
	if disabled or (not can_interact and not self.is_colliding()):
		return
	
	var collider = self.get_collider()
	if collider != previous_interactable_collider:
		previous_interactable_collider = collider
		current_interactee = _get_interactable(self.get_collider())
		
	if not can_interact and self.is_colliding() and check_can_interact(current_interactee):
		set_can_interact(true)
	elif can_interact and (not self.is_colliding() or not check_can_interact(current_interactee)):
		set_can_interact(false)
	
	if Input.is_action_just_pressed("interact") and current_interactee and can_interact:
		do_interact(current_interactee)


func do_interact(interactee : Node3D) -> void:
	if interactee is DragonDoor:
		if interactee.is_locked():
			hud.show_door_locked()
		interactee.interact(self.global_position)
	else:
		interactee.interact()


func set_disabled(value : bool) -> void:
	disabled = value
