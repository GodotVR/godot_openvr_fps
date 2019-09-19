extends ARVRController

# This is only a rough approximation of the controller's velocity, though it works
# fairly well in most cases.
var controller_velocity = Vector3(0,0,0)
# A variable to hold the VR controller's last position in 3D space.
# This is used to get a rough approximation of the VR controller's velocity.
var prior_controller_position = Vector3(0,0,0)
# A Array to hold the last 30 calculated controller velocities. This is used to smooth velocity
# calculates out over time.
var prior_controller_velocities = []

# A variable to hold a reference to the object the VR controller is currently holding, if the
# VR controller is holding anything. If the VR controller is not holding anything, then the
# variable will be equal to null.
var held_object = null
# A dictionary to hold data for the currently held RigidBody object. This is used to
# reset a RigidBody's mode, layer, and mask when the object is no longer held.
var held_object_data = {"mode":RigidBody.MODE_RIGID, "layer":1, "mask":1}

# A variable to hold the Area node used to grab objects.
var grab_area
# A variable to hold the Raycast node used to grab objects.
var grab_raycast
# The current grab mode
# A variable to define the grab mode the VR controlelr is using.
#
# There are only two implemented modes: Area and Rayacst.
# Area mode allows for grabbing objects with an Area node, while Raycast allows for grabbing objects
# with a Raycast node.
var grab_mode = "AREA"
# A variable to hold the node that will be used to position and rotate objects held by the VR controller.
var grab_pos_node

# A variable to hold the hand mesh that is used to represent the VR controller when the
# player is not holding anything.
var hand_mesh
# A variable to hold the AudioStreamPlayer3D that contains the pickup/drop noise.
var hand_pickup_drop_sound

# A variable to hold the position of the player will be teleported to when VR controller teleports the player.
var teleport_pos = Vector3.ZERO
# A variable to hold the MeshInstance node used to show where the player will be teleporting to.
var teleport_mesh
# A variable to track whether this controller's teleport button is held down. This is used to detect whether
# this VR controller is teleporting the player.
var teleport_button_down
# A variable to hold the Raycast node used to calculate the teleportation position.
# (The Raycast node also has a 'laser sight' MeshInstance for aiming the raycast)
var teleport_raycast

# A constant to define the dead zone for both the trackpad and the joystick.
# See (http://www.third-helix.com/2013/04/12/doing-thumbstick-dead-zones-right.html)
# for more information on what dead zones are, and how we are using them in this project.
#
# The deadzone defined below is large so little bumps on the trackpad/joystick do not move the player.
const CONTROLLER_DEADZONE = 0.65

# A constant to define the speed the player moves at when using the trackpad/joystick.
const MOVEMENT_SPEED = 1.5

# A constant to define how fast the VR controller rumble fades.
const CONTROLLER_RUMBLE_FADE_SPEED = 2.0

# A variable to track whether this VR controller is moving the player.
# (This is needed for the vignette effect, as it only shows when the VR controller(s) are moving the player)
var directional_movement = false


func _ready():
	# Ignore the warnings the from the connect function calls.
	# (We will not need the returned values for this tutorial)
	# warning-ignore-all:return_value_discarded
	
	# Get the teleport nodes (notice how the teleport mesh is not part of the controller, but
	# rather part of Game!)
	
	# Get the teleport raycast node and assign it to the teleport_raycast variable.
	teleport_raycast = get_node("RayCast")
	
	# Get the teleport mesh and assign it to the teleport_mesh variable.
	#
	# The teleport mesh is a child of the game scene so it is not effected changes in the VR controller
	# and so the teleport mesh can be used by both VR controllers.
	teleport_mesh = get_tree().root.get_node("Game/Teleport_Mesh")
	
	# Set teleport_button_down variable to false.
	teleport_button_down = false
	# Make the teleport meshes invisible.
	teleport_mesh.visible = false
	teleport_raycast.visible = false
	
	# Get the grab area node, the grab raycast node, and the grab position node. Assign these nodes to
	# their respective variables.
	grab_area = get_node("Area")
	grab_raycast = get_node("GrabCast")
	grab_pos_node = get_node("Grab_Pos")
	
	# Set the VR controller's inital grab mode to Area, and make the grab_raycast node invisible.
	grab_mode = "AREA"
	grab_raycast.visible = false
	
	# Connect the Area signals for the Sleep_Area node to the sleep_area_entered and sleep_area_exited functions
	# (This makes it where RigidBody nodes cannot sleep when nearby the VR controller)
	get_node("Sleep_Area").connect("body_entered", self, "sleep_area_entered")
	get_node("Sleep_Area").connect("body_exited", self, "sleep_area_exited")
	
	# Get the MeshInstance node for the hand and assign it to the hand_mesh variable.
	hand_mesh = get_node("Hand")
	# Get the drop/pick-up AudioStreamPlayer3D node and assign it to the hand_pickup_drop_sound variable.
	hand_pickup_drop_sound = get_node("AudioStreamPlayer3D")
	
	# Connect the VR buttons signals to the button_pressed and button_released functions.
	connect("button_pressed", self, "button_pressed")
	connect("button_release", self, "button_released")


func _physics_process(delta):
	# If the VR controller is rumbling...
	if rumble > 0:
		# Reduce the rumble by CONTROLLER_RUMBLE_FADE_SPEED every second (by multiplying by delta)
		rumble -= delta * CONTROLLER_RUMBLE_FADE_SPEED
		# If the rumble gets below zero, reset it to zero so the rumble cannot be negative.
		if rumble < 0:
			rumble = 0
	
	# If this VR controller is trying to teleport...
	if teleport_button_down == true:
		# Force the teleport raycast node to update so it collides with the latest version of the physics world.
		teleport_raycast.force_raycast_update()
		# If the raycast collided with something...
		if teleport_raycast.is_colliding():
			# If the CollisionBody is a StaticBody node...
			# (We check this so the player cannot teleport onto RigidBody nodes)
			if teleport_raycast.get_collider() is StaticBody:
				# Check to see if the normal vector, the raycast 'bounce', is facing upright.
				# This makes it where the player cannot teleport on the side of walls or on the ceiling.
				if teleport_raycast.get_collision_normal().y >= 0.85:
					# Assign the teleport_pos variable to the raycast collision point.
					teleport_pos = teleport_raycast.get_collision_point()
					# Move the teleport mesh to the raycast collision point.
					teleport_mesh.global_transform.origin = teleport_pos
	
	
	# If the VR controller is active/present...
	if get_is_active() == true:
		# Calculate the controller's velocity using changes in position.
		# It is not perfect, but it gets a rough idea of the velocity of the VR controller.
		_physics_process_update_controller_velocity(delta)
	
	# Update the held object's position and rotation if there is one.
	# Because of how scale works, we need to temporarily store it and then reset the
	# scale, otherwise the scale will always be the same as the controller.
	
	# If the VR controller is holding an object...
	if held_object != null:
		# Store the held object's scale temporarily.
		var held_scale = held_object.scale
		# Set the global transform of the held object to the global transform of the grab_pos_node.
		# This will make the held object have the same position, rotation, and scale of the grap_pos_node
		# in world space.
		held_object.global_transform = grab_pos_node.global_transform
		# Apply the cached held object's scale. This keeps the object from changing scale when grabbed by
		# the VR controller.
		held_object.scale = held_scale
	
	# Call the _physics_process_directional_movement function to the player can move using the trackpad/joystick. 
	_physics_process_directional_movement(delta);


# This function does a rough calculate of the VR controller's veloctiy by calculating the relative changes
# in position over the last 30 _physics_process calls.
func _physics_process_update_controller_velocity(delta):
	# Reset the controller_velocity variable
	controller_velocity = Vector3(0,0,0)
	
	# Add the following lines if you want to use the velocity
	# calculations from before.
	# Using the prior calculations gives a smoother throwing/catching
	# experience, though it is not perfect...
	# Add the previous controller velocities
	
	# If there are cached velocities saved...
	if prior_controller_velocities.size() > 0:
		# Go through each of these velocities and add them to controller_velocity.
		for vel in prior_controller_velocities:
			controller_velocity += vel
		
		# Get the average velocity, instead of just adding them together, by dividing the combined velocity
		# by the size of the prior_controller_velocities Array.
		# This will make it where the velocity calculations take the previous motion of the VR controller into
		# account, giving *slightly* more accurate and smooth velocity results in most cases.
		controller_velocity = controller_velocity / prior_controller_velocities.size()
	
	# Calculate the change in position the VR controller has taken since the last _physics_process
	# function call. This will give us a rough idea of how fast the controller is moving through 3D space.
	var relative_controller_position = (global_transform.origin - prior_controller_position)
	
	# Add the change in position to the controller_velocity variable.
	controller_velocity += relative_controller_position
	
	# Add the change in position to the prior_controller_velocities list so it is
	# taken into account on the next _physics_process_update_controller_velocity call.
	prior_controller_velocities.append(relative_controller_position)
	
	# Update prior_controller_position with the current position of the VR controler
	prior_controller_position = global_transform.origin
	
	# Divide by delta so the velocity is higher (giving more expected results) while still being relative
	# to the amount of time that has passed.
	controller_velocity /= delta;
	
	# If there are more than 30 relative velocities cached within prior_controller_velocities, then we
	# want to remove the oldest velocity so that we only have 30 cached velocity calculations.
	if prior_controller_velocities.size() > 30:
		prior_controller_velocities.remove(0)


# This function handles moving the player when the joystick/touchpad is changed.
func _physics_process_directional_movement(delta):
	# NOTE: These joystick axis index values are based on the Windows-Mixed-Reality VR controller.
	# Other VR controllers may require adjusting the joystick index values.
	
	# Convert the VR controller's trackpad axis values into a Vector2 and store it in a variable called trackpad_vector.
	var trackpad_vector = Vector2(-get_joystick_axis(1), get_joystick_axis(0))
	# Convert the VR controller's joystick axis values into a Vector2 and store it in a variable called trackpad_vector.
	var joystick_vector = Vector2(-get_joystick_axis(5), get_joystick_axis(4))
	
	# If the trackpad_vector's length is less than CONTROLLER_DEADZONE, then just ignore the input entirely.
	if trackpad_vector.length() < CONTROLLER_DEADZONE:
		trackpad_vector = Vector2(0,0)
	# If the trackpad_vector's length is not less than CONTROLLER_DEADZONE, then process the input
	# while accounting for the deadzones within the controller.
	else:
		# (See the link at CONTROLLER_DEADZONE for an explanation of how this code works!)
		trackpad_vector = trackpad_vector.normalized() * ((trackpad_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))
	
	# If the joystick_vector's length is less than CONTROLLER_DEADZONE, then just ignore the input entirely.
	if joystick_vector.length() < CONTROLLER_DEADZONE:
		joystick_vector = Vector2(0,0)
	# If the joystick_vector's length is not less than CONTROLLER_DEADZONE, then process the input
	# while accounting for the deadzones within the controller.
	else:
		# (See the link at CONTROLLER_DEADZONE for an explanation of how this code works!)
		joystick_vector = joystick_vector.normalized() * ((joystick_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))
	
	# Get the forward and right direction vectors relative to the global transform of the player camera.
	# What this does is that it gives us vectors that point forward and right relative to the rotation
	# of the player camera.
	# We can use this to move relative to the rotation of the player camera, so that when you push forward
	# on the joystick/trackpad, you move in the direction that the player camera is facing.
	var forward_direction = get_parent().get_node("Player_Camera").global_transform.basis.z.normalized()
	var right_direction = get_parent().get_node("Player_Camera").global_transform.basis.x.normalized()
	
	# Calculate how much we will move by adding both the trackpad and the joystick vectors together
	# and normalizing them.
	
	# Because the trackpad and the joystick will both move the player, we can add them together and normalize
	# the result, giving the combined movement direction
	var movement_vector = (trackpad_vector + joystick_vector).normalized()
	
	# Calculate the amount of movement the player will take on the Z (forward) axis and assign it to movement_forward.
	var movement_forward = forward_direction * movement_vector.x * delta * MOVEMENT_SPEED
	# Calculate the amount of movement the player will take on the X (right) axis and assign it to movement_forward.
	var movement_right = right_direction * movement_vector.y * delta * MOVEMENT_SPEED
	
	# Remove any movement on the Y axis so the player will not be able to fly/fall just by moving the trackpad/joystick.
	movement_forward.y = 0
	movement_right.y = 0
	
	# If there is movement to apply in either movement_right or movement_forward...
	if (movement_right.length() > 0 or movement_forward.length() > 0):
		# Move the ARVR node (which is assumed to be the parent node) in the direction the player is pushing
		# the trackpad/joystick towards.
		get_parent().global_translate(movement_right + movement_forward)
		# Set directional_movement to true so the code knows this VR controller moving the player.
		directional_movement = true
	# If there is not movement to apply...
	else:
		# Set directional_movement to false so the code knows this VR controller is not moving the player.
		directional_movement = false


# This function is called when any of the VR buttons are pressed.
func button_pressed(button_index):
	# NOTE: These button index values are based on the Windows-Mixed-Reality VR controller.
	# Other VR controllers may require adjusting the index values for proper button placement.
	
	# If the trigger is pressed...
	if button_index == 15:
		# Call the _on_button_pressed_trigger function.
		_on_button_pressed_trigger()
	
	# If the grab button is pressed...
	if button_index == 2:
		# Call the _on_button_pressed_grab function.
		_on_button_pressed_grab()
		
	# If the menu button on the VR controller is pressed...
	if button_index == 1:
		# Call the _on_button_pressed_menu function.
		_on_button_pressed_menu()


# This function is called when the trigger button on the VR controller is pressed.
func _on_button_pressed_trigger():
	# If the VR controller is NOT currently holding anything...
	if held_object == null:
		# Make sure the teleport mesh is currently invisible. We do this because if the teleport
		# mesh is visible, then the other VR controller is trying to teleport. We do not want both
		# controllers to allow teleportation at the same time, so we do this to work around it.
		if teleport_mesh.visible == false:
			# If the teleport mesh is not visible, then we can teleport with this VR controller.
			#
			# Set the teleport_button_down variable to true, make the teleport mesh visible, and
			# make the teleport raycast mesh visible.
			teleport_button_down = true
			teleport_mesh.visible = true
			teleport_raycast.visible = true
	# If the VR contoller IS currently holding something...
	else:
		# If the objecth the VR controller is holding extends VR_Interactable_RigidBody...
		if held_object is VR_Interactable_Rigidbody:
			# Call the interact function so the object can do whatever it does when interacted with.
			held_object.interact()


# This function is called when the grab button on the VR controller is pressed.
func _on_button_pressed_grab():
	# If the teleport button, the VR trigger, is being pressed, then do nothing.
	# This is because we do not want the VR controller to be able to grab/throw an object
	# while trying to teleport.
	if teleport_button_down == true:
		return
	
	# If the VR controller is not holding anything, held_object will be null. If this happens
	# and the grab button is pressed, then we want to attempt to pickup a RigidBody node.
	if held_object == null:
		_pickup_rigidbody()
	# If the VR controller is holding something, then held_object will NOT be null. If this happens
	# and the grab button is pressed, then we want to drop/throw the held object.
	else:
		_throw_rigidbody()
	
	# play the pick-up/drop noise
	hand_pickup_drop_sound.play()


func _pickup_rigidbody():
	# Make a variable so we can determine what RigidBody node the VR controller is going to pickup
	# assuming the VR controller can pickup a Rigidbody.
	var rigid_body = null
	
	# If the VR controller's grab mode is Area...
	if grab_mode == "AREA":
		# Get all of the CollisionBody nodes within the grab_area Area node and assign them
		# to the bodies variable.
		var bodies = grab_area.get_overlapping_bodies()
		# If the length of the bodies variable, which is now an Array, is over zero, then we have
		# at least a single CollisionBody could potentially be grabbed by the VR controller.
		if len(bodies) > 0:
			# Go through all of the CollisionBody nodes in the bodies variable...
			for body in bodies:
				# In this tutorial, the VR controllers can only interact with RigidBody nodes.
				# Because of this, we need to check and see if the CollisionBody node is a RigidBody.
				if body is RigidBody:
					# Check to make sure there is NOT a variable/constant called NO_PICKUP defined within
					# the RigidBody node. This makes it where RigidBody nodes that have NO_PICKUP cannot
					# be grabbed by the VR controllers.
					if !("NO_PICKUP" in body):
						# If the RigidBody node does not have a variable/constant called NO_PICKUP
						# then assign the RigidBody node to the rigid_body variable and break the for loop.
						rigid_body = body
						break
	
	# If the VR controller's grab mode is Raycast
	elif grab_mode == "RAYCAST":
		# Force the grab raycast node to update so it collides with the latest version of the physics world.
		grab_raycast.force_raycast_update()
		# If the raycast collided with something...
		if (grab_raycast.is_colliding()):
			# Get the CollisionBody the raycast collided with
			var body = grab_raycast.get_collider()
			# In this tutorial, the VR controllers can only interact with RigidBody nodes.
			# Because of this, we need to check and see if the CollisionBody node is a RigidBody.
			if body is RigidBody:
				# If the RigidBody node does not have a variable/constant called NO_PICKUP
				# then assign the RigidBody node to the rigid_body variable.
				if !("NO_PICKUP" in body):
					rigid_body = body
	
	
	# If the rigid_body variable is NOT null, then the VR controller found a RigidBody node that
	# can be grabbed...
	if rigid_body != null:
		
		# Assign the held_object variable to the RigidBody we want the VR controller to hold.
		held_object = rigid_body
		
		# Store the RigidBody's mode, collision layer, and collision mask. We want to store these because later
		# when the object is dropped, we want to reapply them, allowing the RigidBody to function as it did
		# prior to being picked up.
		held_object_data["mode"] = held_object.mode
		held_object_data["layer"] = held_object.collision_layer
		held_object_data["mask"] = held_object.collision_mask
		
		# Set the RigidBody's mode to Static, change it's collision layer to zero, and change it's collision mask
		# to zero. This will make it where the RigidBody cannot interact with the physics world when held by
		# the VR controller.
		held_object.mode = RigidBody.MODE_STATIC
		held_object.collision_layer = 0
		held_object.collision_mask = 0
		
		# Make the hand mesh invisible so the VR controller hand does not get in the way of the held object.
		hand_mesh.visible = false
		# Make the grab raycast mesh invisible so it does not get in the way of the held object.
		grab_raycast.visible = false
		
		# If the held object extends the VR_Interactable_Rigidbody class...
		if held_object is VR_Interactable_Rigidbody:
			# Call the held object's picked_up function, and set the controller variable to this VR controller.
			held_object.controller = self
			held_object.picked_up()


func _throw_rigidbody():
	# If the VR controller is not holding any objects, we cannot throw anything!
	# If this somehow happens, simply return.
	if held_object == null:
		return
	
	# Set the held object's RigidBody data back to the stored RigidBody data from the
	# _pickup_rigidbody function.
	held_object.mode = held_object_data["mode"]
	held_object.collision_layer = held_object_data["layer"]
	held_object.collision_mask = held_object_data["mask"]
	
	# Use the apply_impulse function to throw the RigidBody in the direction of the controller's velocity.
	held_object.apply_impulse(Vector3(0, 0, 0), controller_velocity)
	
	# If the held object extends the VR_Interactable_Rigidbody class...
	if held_object is VR_Interactable_Rigidbody:
		# Call the held object's dropped function, and set the controller variable to null.
		held_object.dropped()
		held_object.controller = null
	
	# Set the held_object variable to null, as the VR controller is no longer holding anything.
	held_object = null
	# Since nothing is beind held, make the hand_mesh visible so the VR controller still has a visible mesh.
	hand_mesh.visible = true
	
	# If the VR controller's grab mode is Raycast, then make the grab_raycast mesh visible.
	if grab_mode == "RAYCAST":
		grab_raycast.visible = true


# This function is called when the menu button on the VR controller is pressed.
func _on_button_pressed_menu():
	# If the current grab mode is set to Area mode...
	if grab_mode == "AREA":
		# Change the grab mode to Raycast mode.
		grab_mode = "RAYCAST"
		# If the VR controller is not holding anything, then make the grab_raycast mesh visible.
		if held_object == null:
			grab_raycast.visible = true
	
	# If the current grab mode is set to Raycast mode...
	elif grab_mode == "RAYCAST":
		# Change the grab mode to Area mode.
		grab_mode = "AREA"
		# Make the grab_raycast mesh invisible.
		grab_raycast.visible = false


# This function is called when any of the VR buttons are released.
func button_released(button_index):
	# If the trigger button is released...
	if button_index == 15:
		_on_button_released_trigger()


# This function is called when the trigger on the VR controller is released.
func _on_button_released_trigger():
	# Make sure the VR controller is trying to teleport...
	if teleport_button_down == true:
		
		# Check if there is a teleport position set and that the teleport mesh is visible...
		if teleport_pos != null and teleport_mesh.visible == true:
			# We need to calculate the distance the player is from the ARVR origin. We need to do this because most
			# VR headsets use room tracking, which allows the camera to be offset from the ARVR origin.
			# To work around this, we just need to figure out the difference in position from the camera
			# to the ARVR origin node.
			var camera_offset = get_parent().get_node("Player_Camera").global_transform.origin - get_parent().global_transform.origin
			# However, we do not want to offset according to the player's height, so we remove the difference on the Y axis.
			# If we did not do this, then the player's head would be level with the ground.
			camera_offset.y = 0
			
			# Teleport the ARVR origin to the teleport position, removing the room tracking camera offset.
			get_parent().global_transform.origin = teleport_pos - camera_offset
		
		# Reset the teleport related variables.
		teleport_button_down = false
		teleport_mesh.visible = false
		teleport_raycast.visible = false
		teleport_pos = null


func sleep_area_entered(body):
	# When a CollisionBody enters the sleep_area, we want to check if it is sleeping. If the CollisionBody is sleeping
	# then we will not be able to grab it with the VR controllers. To work around this, we will 'wake' it up.
	#
	# Check if the CollisionBody has a variable called "can_sleep"...
	if "can_sleep" in body:
		# If it does, then set the can_sleep variable to false and set the sleeping variable to false.
		# This will 'wake' the CollisionBody up, allowing it to be used by the VR controller.
		body.can_sleep = false
		body.sleeping = false


func sleep_area_exited(body):
	# When a CollisionBody leaves the sleep_area, we want to allow it to sleep to save performance.
	#
	# Check if the CollisionBody has a variable called "can_sleep"...
	if "can_sleep" in body:
		# Allow the CollisionBody to sleep by setting the "can_sleep" variable to true
		body.can_sleep = true

