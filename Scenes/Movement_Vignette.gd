extends Control

# Variables that will hold references to each of the VR controllers.
# We need this so we can tell whether the player is moving or not.
var controller_one
var controller_two


func _ready():
	# Wait four frames to ensure the VR interface is ready and going
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	# Get the current VR interface.
	var interface = ARVRServer.primary_interface
	
	# If no interface is found, then we cannot track resize the vignette to the size of the VR viewport
	# and so we cannot really use the movement vignette.
	# If no interface is found, then print an error and disable _process.
	if interface == null:
		set_process(false)
		printerr("Movement_Vignette: no VR interface found!")
		return
	
	# Since a VR interface is found, we can set the size of the Control to the size of the VR viewport.
	# Set the size to be the same size as the VR headset, and set the position to (0,0)
	# so it covers the entire VR view.
	rect_size = interface.get_render_targetsize()
	rect_position = Vector2(0,0)
	
	# Get the right and left controllers and assign them to the proper variables.
	controller_one = get_parent().get_node("Left_Controller")
	controller_two = get_parent().get_node("Right_Controller")
	
	# Make the vignette invisible by default.
	visible = false


func _process(_delta):
	# If one of the VR controllers have not been assigned, then do nothing!
	if (controller_one == null or controller_two == null):
		return
	
	# Only make the vignette visible if one (or both) of the controllers are moving the player using
	# the touchpad or joystick. If neither of the controllers are moving the player, then make the
	# vignette invisible.
	
	# If either of the VR controllers are using directional movement, movement through the joystick
	# or touchpad, then we want to show the vignette to help reduce motion sickness.
	if (controller_one.directional_movement == true or controller_two.directional_movement == true):
		visible = true
	# If none of the VR controllers are using directional movement, then hide the vignette.
	else:
		visible = false

