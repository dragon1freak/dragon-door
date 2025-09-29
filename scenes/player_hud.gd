extends Control


@onready var interact_indicator: TextureRect = %InteractIndicator
@onready var locked_label: Label = %LockedLabel


func _ready() -> void:
	interact_indicator.visible = false
	locked_label.visible = false


func _on_interactor_can_interact_changed(can_interact: Variant) -> void:
	interact_indicator.visible = can_interact


var door_lock_timer : SceneTreeTimer
func show_door_locked() -> void:
	if not door_lock_timer:
		locked_label.visible = true
		door_lock_timer = get_tree().create_timer(1.0)
		await door_lock_timer.timeout
		locked_label.visible = false
		door_lock_timer = null
