extends Control

# Variable to hold both of the controllers.
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
	
	# If no interface is found, then do not attempt to start VR.
	if interface == null:
		set_process(false)
		printerr("Movement_Vignette: no VR interface found!")
		return
	
	# Set the size to be the same size as the VR headset, and set the position to (0,0)
	# so it covers the entire view
	rect_size = interface.get_render_targetsize()
	rect_position = Vector2(0,0)
	
	# Get the right and left controllers.
	controller_one = get_parent().get_node("Left_Controller")
	controller_two = get_parent().get_node("Right_Controller")
	
	# Make the vignette invisible.
	visible = false


func _process(_delta):
	
	# Make sure both controllers are gotten
	if (controller_one == null or controller_two == null):
		return
	
	# Only make the vignette visible if one (or both) of the controllers are moving the player using
	# the touchpad or joystick. If neither of the controllers are moving the player, then make the
	# vignette invisible.
	if (controller_one.directional_movement == true or controller_two.directional_movement == true):
		visible = true
	else:
		visible = false

