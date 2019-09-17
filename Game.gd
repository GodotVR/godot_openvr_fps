extends Spatial

# A variable to store the amount of spheres in the scene
# This is used to track whether all of the spheres in the scene have been destoyed
var spheres_left = 10
# A variable to store the UI used for the sphere count.
# This variable is assumed to be set by Main_VR_UI_Base_Control.gd
var sphere_ui = null


func _ready():
	# We will be using OpenVR to drive the VR interface, so we need to find it.
	var VR = ARVRServer.find_interface("OpenVR");
	# If the OpenVR interface was found and initialization is successful...
	if VR and VR.initialize():
		
		# Turn the main viewport into a AR/VR viewport and turn off HDR
		get_viewport().arvr = true
		get_viewport().hdr = false
		
		# Let's disable VSync so the FPS is not capped and set the target FPS to 90,
		# which is standard for most VR headsets.
		#
		# This is not strictly required, but it will make the experience smoother for most VR headsets
		# and then the computer monitor's VSync will not effect the VR headset.
		OS.vsync_enabled = false
		Engine.target_fps = 90
		# Also, the physics FPS in the project settings is also 90 FPS. This makes the physics
		# run at the same frame rate as the display, which makes things look a little smoother in VR!


func remove_sphere():
	# Remove one from the spheres_left variable
	spheres_left -= 1
	
	# If sphere_ui is not null, then assume it is set to a node with Main_VR_UI_Base_Control.gd
	# and call the update_ui function
	if sphere_ui != null:
		sphere_ui.update_ui(spheres_left)

