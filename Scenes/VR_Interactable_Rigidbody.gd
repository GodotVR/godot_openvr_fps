class_name VR_Interactable_Rigidbody
extends RigidBody

# The controller that is currently holding this object, if there is one.
# This is set by the controller, so we do not need to check anything.
#
# (Ignore the unused variable warning)
# warning-ignore:unused_class_variable
var controller = null


func _ready():
	pass


# Called when the interact button is pressed while the object is held.
# This function is designed to be overwritten. The reason we define it here is so there
# is a consistent interface to use in VR_Controller.gd
func interact():
	pass


# Called when the object is picked up.
# This function is designed to be overwritten.
func picked_up():
	pass


# Called when the object is dropped.
# This function is designed to be overwritten.
func dropped():
	pass

