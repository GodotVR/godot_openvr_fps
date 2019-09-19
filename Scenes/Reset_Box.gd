# Extend the VR_Interactable_Rigidbody class so the VR controllers know they can interact
# and call the functions defined in VR_Interactable_Rigidbody with this object.
extends VR_Interactable_Rigidbody

# A copy of the global transform when the game starts.
# A variable to hold the global transform of this object when the game starts.
# This position will be used to reset the reset box once it has been moved
var start_transform

# A variable to hold the amount of time that has passed since the reset box's position has
# been reset back to the initial starting position.
var reset_timer = 0
# A constant to define how long the reset box has to wait before being reset.
const RESET_TIME = 10
# A constant to define how far the reset box has to be away from the starting position
# before the timer starts counting down
const RESET_MIN_DISTANCE = 1


func _ready():
	# Get the starting transform and store it.
	start_transform = global_transform


func _physics_process(delta):
	# Get the distance between the start_transform position and the current reset box position
	if start_transform.origin.distance_to(global_transform.origin) >= RESET_MIN_DISTANCE:
		# Add time, delta, to the reset timer
		reset_timer += delta
		# If the reset timer is more than the RESET_TIME constant...
		if reset_timer >= RESET_TIME:
			# Reset the global transform to the transform in the start_transform variable.
			global_transform = start_transform
			# Reset the reset_timer variable
			reset_timer = 0


# Called when the interact button is pressed while the object is held by a VR controller.
func interact():
	# Reload the Game scene
	#
	# (Ignore the unused variable warning)
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Game.tscn")


# Called when the object has just been dropped up by a VR controller.
func dropped():
	# Reset the global transform to the transform in the start_transform variable.
	global_transform = start_transform
	# Reset the reset_timer variable
	reset_timer = 0
