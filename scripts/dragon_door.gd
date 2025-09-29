extends Node3D
class_name DragonDoor
## Easy to use door script that should cover most cases.

signal opened ## Emitted when the door has finished opening
signal closed ## Emitted when the door has finished closing
signal lock_changed(value) ## Emitted when the locked state of the door changes

## Locked state of the door, if true the door cannot be interacted with
@export var locked : bool = false
## If true, the door will lock itself while swinging. This stops the player from opening/closing the door mid-swing.
@export var lock_while_swinging := true
## The angle the door should swing open in degrees from the closed angle.
@export_range(0, 180, 1) var swing_angle : float = 90.0
## How long it takes for the door to open/close in seconds.
@export_range(0.1, 15, 0.1) var open_time : float = 2.0

@export_group("Collision Settings")
## If true, the set collider will disable during swinging. This allows the door to pass through objects like the player while opening/closing.
@export var disable_while_swinging := true
## The collider to disable during swinging if disable_while_swinging is true
@export var collider : CollisionShape3D

@export_group("Swing Settings")
## If true, the door only opens in one direction
@export var unidirectional : bool = false
## Reverses the direction of the unidirectional swing if true
@export var reverse_direction : bool = false
## If true, the angle set at closed_angle_override is used as the closed angle instead of the door's starting rotation. Useful if you want a door to start slightly open.
@export var use_closed_override : bool = false
## The angle to use instead of the door's starting rotation
@export var closed_angle_override : float = 0
## If true, the door will open completely when first interacted with if closed_angle_override is used. Will close completely if false.
@export var open_first : bool = true

@export_group("Tween Settings")
## Tween transition type for the door swinging tween.
@export var transition_type : Tween.TransitionType = Tween.TRANS_CUBIC
## The ease type for the door swinging tween.
@export var ease_type : Tween.EaseType = Tween.EASE_OUT
## The minimum swing time for the tween. The tween time is calculated using the remaining swing distance if the door is interacted with mid swing, a 
##minimum time ensures the short tweens are reasonable. Set to 0 to disable.
@export_range(0.0, 15.0, 0.01) var min_swing_time : float = 0.15

@export_group("Audio Settings")
## Sound to play when opening the door
@export var open_sound : AudioStream
## Sound to play when closing the door. May need to be delayed to fit when it actually closes.
@export var close_sound : AudioStream
## Sound to play when the door is interacted with when locked
@export var locked_sound : AudioStream
## Audio bus the door sounds should play on
@export var audio_bus : String = "Master"
@export_subgroup("Volume")
## Volume of the AudioStreamPlayer3D playing the open sound
@export_range(-80.0, 80.0, 0.1) var open_volume_db := 0.0
## Volume of the AudioStreamPlayer3D playing the close sound
@export_range(-80.0, 80.0, 0.1) var close_volume_db := 0.0
## Volume of the AudioStreamPlayer3D playing the locked sound
@export_range(-80.0, 80.0, 0.1) var locked_volume_db := 0.0
@export_subgroup("Delay")
## How long in seconds should the door wait to play the opening sound
@export_range(0.0, 15.0, 0.01) var open_sound_delay : float = 0.0
## How long in seconds should the door wait to play the closing sound
@export_range(0.0, 15.0, 0.01) var close_sound_delay : float = 0.0


## Starting rotation in radians
var starting_rot : float
## Target rotation in radians
var target_rot : float
## Tween used to swing the door
var swing_tween : Tween
## AudioStreamPlayer3D to play the open sound
var open_sound_player : AudioStreamPlayer3D
## AudioStreamPlayer3D to play the close sound
var close_sound_player : AudioStreamPlayer3D
## AudioStreamPlayer3D to play the locked sound
var locked_sound_player : AudioStreamPlayer3D
## Timer used to delay the sounds playing, shared by all sounds.
var sound_timer : SceneTreeTimer


func _ready() -> void:
	starting_rot = self.rotation.y if not use_closed_override else deg_to_rad(closed_angle_override)
	
	if use_closed_override and not open_first:
		target_rot = self.rotation.y
	else:
		target_rot = starting_rot
	
	_setup_audio_players()


## Interact with the door. Opens if closed, closes if opened.
## interact_pos should be the position of what is interacting with the door. This is used to determine the open swing direction.
func interact(interact_pos : Vector3 = Vector3.BACK) -> bool:
	if target_rot == starting_rot:
		return open(interact_pos)
	else:
		return close()


## Opens the door and plays the open door sound if set. 
## If fully open, does nothing. If the door is closed and locked, plays the lock sound.
func open(interact_pos: Vector3 = Vector3.BACK) -> bool:
	if locked or (lock_while_swinging and swing_tween and swing_tween.is_running()) or target_rot != starting_rot:
		if is_locked() and locked_sound_player:
			locked_sound_player.play()
		return false
	
	if sound_timer and sound_timer.timeout.is_connected(_on_sound_timer_end):
		sound_timer.timeout.disconnect(_on_sound_timer_end)
	
	if open_sound_player:
		if open_sound_delay > 0.0:
			sound_timer = get_tree().create_timer(open_sound_delay)
			sound_timer.timeout.connect(_on_sound_timer_end.bind(open_sound_player))
		else:
			open_sound_player.play()
	
	var swing_dir = sign(self.global_transform.origin.direction_to(interact_pos).dot(Vector3.BACK.rotated(Vector3.UP, global_rotation.y))) if !unidirectional else (1 if not reverse_direction else -1)
	target_rot = starting_rot + (deg_to_rad(swing_angle) * swing_dir)
	
	_swing()
	
	return true


## Closes the door if open, plays the close door sound.
## If the door is fully closed, does nothing.
func close() -> bool:
	if locked or (lock_while_swinging and swing_tween and swing_tween.is_running()) or target_rot == starting_rot:
		return false
	
	if sound_timer and sound_timer.timeout.is_connected(_on_sound_timer_end):
		sound_timer.timeout.disconnect(_on_sound_timer_end)
	
	if close_sound_player:
		if close_sound_delay > 0.0:
			var calc_delay = ((abs(starting_rot - rotation.y)) / deg_to_rad(swing_angle)) * close_sound_delay
				
			sound_timer = get_tree().create_timer(calc_delay)
			sound_timer.timeout.connect(_on_sound_timer_end.bind(close_sound_player))
		else:
			close_sound_player.play()
	
	target_rot = starting_rot
	
	_swing()
	
	return true


## Set the locked state of the door
func set_locked(value: bool = true) -> void:
	locked = value
	lock_changed.emit(value)


## Returns true if the door is closed and not actively swinging
func is_closed() -> bool:
	return target_rot == starting_rot and rotation.y == target_rot and (not is_swinging())


## Returns true if the door is swinging
func is_swinging() -> bool:
	return swing_tween and swing_tween.is_running()


## Returns true if the door is locked and not swinging.
## We check that its not swinging as lock_while_swinging uses the same locked value.
func is_locked() -> bool:
	return not is_swinging() and locked


## Private function to swing the door. Sets the tween up and disables the collider if set.
func _swing() -> void:
	if swing_tween:
		swing_tween.kill()
	swing_tween = create_tween()
	swing_tween.finished.connect(_on_tween_finished)
	
	var calc_open_time : float = ((abs(target_rot - rotation.y)) / deg_to_rad(swing_angle)) * open_time
	
	swing_tween.tween_property(self, "rotation:y", target_rot, max(calc_open_time, min_swing_time)).set_trans(transition_type).set_ease(ease_type)
	if disable_while_swinging and collider:
		collider.disabled = true


## Private function that handles cleaning up the tween and emitting the signals as needed.
func _on_tween_finished() -> void:
	if collider:
		collider.disabled = false
	swing_tween.kill()
	
	if is_closed():
		closed.emit()
	else:
		opened.emit()


## Private function to set up the audio players for the door.
func _setup_audio_players() -> void:
	if open_sound:
		open_sound_player = AudioStreamPlayer3D.new()
		open_sound_player.bus = audio_bus
		open_sound_player.volume_db = open_volume_db
		open_sound_player.stream = open_sound
		self.add_child(open_sound_player)
	
	if close_sound:
		close_sound_player = AudioStreamPlayer3D.new()
		close_sound_player.bus = audio_bus
		close_sound_player.volume_db = close_volume_db
		close_sound_player.stream = close_sound
		self.add_child(close_sound_player)
	
	if locked_sound:
		locked_sound_player = AudioStreamPlayer3D.new()
		locked_sound_player.bus = audio_bus
		locked_sound_player.volume_db = locked_volume_db
		locked_sound_player.stream = locked_sound
		self.add_child(locked_sound_player)


## Private function used to play the sounds when the delay timer ends.
func _on_sound_timer_end(player: AudioStreamPlayer3D) -> void:
	player.play()
