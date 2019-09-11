extends Spatial

# The amount of sphere's left to destroy
var spheres_left = 10
# A variable to store the UI used for the sphere count.
var sphere_ui = null

func _ready():
	
	# We will be using OpenVR to drive the VR interface, so we need to find and initialize it.
	var VR = ARVRServer.find_interface("OpenVR")
	if VR and VR.initialize():
		
		# Turn the main viewport into a AR/VR viewport,
		# and turn off HDR (which currently does not work)
		get_viewport().arvr = true
		get_viewport().hdr = false
		
		# Let's disable VSync so we are not running at whatever the monitor's VSync is,
		# and let's set the target FPS to 90, which is standard for most VR headsets.
		OS.vsync_enabled = false
		Engine.target_fps = 90
		# Also, the physics FPS in the project settings is also 90 FPS. This makes the physics
		# run at the same frame rate as the display, which makes things look smoother in VR!


func remove_sphere():
	# Remove a sphere
	spheres_left -= 1
	
	# If we have a node attached to sphere_ui, then we want to update it!
	if sphere_ui != null:
		sphere_ui.update_ui(spheres_left)

