# Extend the VR_Interactable_Rigidbody class so the VR controllers know they can interact
# and call the functions defined in VR_Interactable_Rigidbody with this object
extends VR_Interactable_Rigidbody

# A copy of the global transform when the game starts.
var start_transform

# A timer for tracking how long until the transform resets automatically.
var reset_timer = 0
const RESET_TIME = 120


func _ready():
	# Get the starting transform and store it.
	start_transform = global_transform


func _physics_process(delta):
	# If enough time has passed since the last reset, then reset the transform
	# and reset the timer.
	reset_timer += delta
	if reset_timer >= RESET_TIME:
		global_transform = start_transform
		reset_timer = 0


# Called when the interact button is pressed while the object is held.
func interact():
	# Reload the Game scene
	# (Ignore the unused variable warning)
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Game.tscn")


# Called when the object is dropped.
func dropped():
	# Reset the transform and reset the timer
	global_transform = start_transform
	reset_timer = 0
