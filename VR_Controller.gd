extends ARVRController

# The velocity the controller is moving at (calculated using physics frames)
var controller_velocity = Vector3(0,0,0)
# The controller's previous position (used to calculate velocity)
var prior_controller_position = Vector3(0,0,0)
# The last 30 calculated velocities (1/3 of a second worth of velocity calculations,
# assuming the game is running at 90 FPS)
var prior_controller_velocities = []

# The currently held object, if there is one
var held_object = null
# The RigidBody data of the currently held object, used to reset the object when
# no longer holding it.
var held_object_data = {"mode":RigidBody.MODE_RIGID, "layer":1, "mask":1}

# The Area node used to grab objects.
var grab_area
# The Raycast node used to grab objects.
var grab_raycast
# The current grab mode
var grab_mode = "AREA"
# The position where held objects stay
var grab_pos_node

# The hand mesh, used to represent the player's hand when they are not holding anything.
var hand_mesh

# The position the teleport raycast is aimed at, the mesh used to represent the teleport
# position, the teleport 'laser sight' finger mesh, a variable to track whether the teleport
# button is down, and the teleport raycast.
var teleport_pos
var teleport_mesh
var teleport_button_down
var teleport_raycast

# The dead zone for both the trackpad and the joystick.
# See (http://www.third-helix.com/2013/04/12/doing-thumbstick-dead-zones-right.html)
# for more information on what dead zones are, and how we are using them.
#
# Notice that we are using a really large dead zone. This is because we do not want to move
# the player if they barely bump the trackpad/joystick.
const CONTROLLER_DEADZONE = 0.65

# The speed the player moves at when moving using the trackpad and/or joystick.
const MOVEMENT_SPEED = 1.5

# The speed the controller rumble fades at
const CONTROLLER_RUMBLE_FADE_SPEED = 2.0

# A boolean to track whether the player is moving using this controller.
# This is needed for the vignette effect that shows only when the player is moving.
var directional_movement = false

func _ready():
	# Ignore the warnings the from the connect function calls.
	# We will not need the returned value for this tutorial.
	# warning-ignore-all:return_value_discarded
	
	# Get the teleport nodes (notice how the teleport mesh is not part of the controller, but
	# rather part of Game!)
	teleport_raycast = get_node("RayCast")
	teleport_mesh = get_tree().root.get_node("Game/Teleport_Mesh")
	# Set teleport button down to false, and hide the teleport meshes.
	teleport_button_down = false
	teleport_mesh.visible = false
	teleport_raycast.visible = false
	
	# Get the grab related nodes
	grab_area = get_node("Area")
	grab_raycast = get_node("GrabCast")
	grab_pos_node = get_node("Grab_Pos")
	grab_mode = "AREA"
	grab_raycast.visible = false
	
	# Connect the sleep area signals (to make it where RigidBodies cannot sleep when close to
	# the player)
	get_node("Sleep_Area").connect("body_entered", self, "sleep_area_entered")
	get_node("Sleep_Area").connect("body_exited", self, "sleep_area_exited")
	
	# Get the hand mesh
	hand_mesh = get_node("Hand")
	
	# Connect the VR buttons
	connect("button_pressed", self, "button_pressed")
	connect("button_release", self, "button_released")


func _physics_process(delta):
	
	# Reduce controller rumble by delta, if the controller is rumbling
	if rumble > 0:
		rumble -= delta * CONTROLLER_RUMBLE_FADE_SPEED
		if rumble < 0:
			rumble = 0
	
	# Update the teleportation mesh and position IF the teleport button is down
	if teleport_button_down == true:
		teleport_raycast.force_raycast_update()
		if teleport_raycast.is_colliding():
			# Make sure the teleport raycast is colliding with a StaticBody, and make
			# sure it's normal is more or less facing upright.
			if teleport_raycast.get_collider() is StaticBody:
				if teleport_raycast.get_collision_normal().y >= 0.85:
					# Set teleport_pos to the raycast point and move the teleport mesh.
					teleport_pos = teleport_raycast.get_collision_point()
					teleport_mesh.global_transform.origin = teleport_pos
	
	
	# Controller velocity
	# --------------------
	# Update velocity, IF there is a controller active for this controller (left/right hand)
	if get_is_active() == true:
		
		# Reset the controller velocity
		controller_velocity = Vector3(0,0,0)
		
		# Add the following lines if you want to use the velocity
		# calculations from before.
		# Using the prior calculations gives a smoother throwing/catching
		# experience, though it is not perfect...
		# Add the previous controller velocities
		if prior_controller_velocities.size() > 0:
			for vel in prior_controller_velocities:
				controller_velocity += vel
			
			# Get the average velocity, instead of just adding them together.
			controller_velocity = controller_velocity / prior_controller_velocities.size()
		
		# Add the most recent controller velocity to the list of propr controller velocities
		# (not needed if you are not using the controller's prior velocities)
		prior_controller_velocities.append((global_transform.origin - prior_controller_position) / delta)
		
		# If you want to only use the last frame's position to calculate velocity, then
		# only use the two lines of code below (and not the ones with prior_controller_velocities above!)
		# Calculate the velocity using the controller's prior position.
		controller_velocity += (global_transform.origin - prior_controller_position) / delta
		prior_controller_position = global_transform.origin
		
		# If we have more than a third of a seconds worth of velocities, then we
		# should remove the oldest (not needed if you are not using the controller's prior velocities)
		if prior_controller_velocities.size() > 30:
			prior_controller_velocities.remove(0)
	
	# --------------------
	
	# Update the held object's position and rotation if there is one.
	# Because of how scale works, we need to temporarily store it and then reset the
	# scale, otherwise the scale will always be the same as the controller.
	if held_object != null:
		var held_scale = held_object.scale
		held_object.global_transform = grab_pos_node.global_transform
		held_object.scale = held_scale
	
	
	# Directional movement
	# --------------------
	# First we need to convert the VR axes to Vectors.
	# We do this for both the trackpad and the joystick.
	# 
	# NOTE: you may need to change this depending on which VR controllers
	# you are using and which OS you are on.
	var trackpad_vector = Vector2(-get_joystick_axis(1), get_joystick_axis(0))
	var joystick_vector = Vector2(-get_joystick_axis(5), get_joystick_axis(4))
	
	# Account for dead zones on both the trackpad and the joystick, starting with the trackpad.
	# See the link at CONTROLLER_DEADZONE for an explanation of how this code works!
	if trackpad_vector.length() < CONTROLLER_DEADZONE:
		trackpad_vector = Vector2(0,0)
	else:
		trackpad_vector = trackpad_vector.normalized() * ((trackpad_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))
	
	# Account for dead zones on the the joystick
	if joystick_vector.length() < CONTROLLER_DEADZONE:
		joystick_vector = Vector2(0,0)
	else:
		joystick_vector = joystick_vector.normalized() * ((joystick_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))
	
	# Get the VR camera's forward and right directional/local-space vectors
	var forward_direction = get_parent().get_node("Player_Camera").global_transform.basis.z.normalized()
	var right_direction = get_parent().get_node("Player_Camera").global_transform.basis.x.normalized()
	
	# Calculate how much we will move by adding both the trackpad and the joystick vectors together
	# and normalizing them.
	var movement_vector = (trackpad_vector + joystick_vector).normalized()
	
	# Calculate how far we will move forward/backwards and right/left, using the camera's directional/local-space vectors.
	var movement_forward = forward_direction * movement_vector.x * delta * MOVEMENT_SPEED
	var movement_right = right_direction * movement_vector.y * delta * MOVEMENT_SPEED
	
	# Remove movement on the Y axis so the player cannot fly/fall by moving
	movement_forward.y = 0
	movement_right.y = 0
	
	# Move the player if there is any movement forward/backwards or right/left.
	if (movement_right.length() > 0 or movement_forward.length() > 0):
		get_parent().translate(movement_right + movement_forward)
		directional_movement = true
	else:
		directional_movement = false
	# --------------------


func button_pressed(button_index):
	
	# If the trigger is pressed...
	if button_index == 15:
		# Interact with held object, if there is one and it extends VR_Interactable_RigidBody
		if held_object != null:
			if held_object is VR_Interactable_Rigidbody:
				held_object.interact()
		
		# Teleport if we are not holding a object.
		else:
			# Make sure the other controller is not already trying to teleport.
			if teleport_mesh.visible == false and held_object == null:
				teleport_button_down = true
				teleport_mesh.visible = true
				teleport_raycast.visible = true
	
	
	# If the grab button is pressed...
	if button_index == 2:
		
		# Make sure we cannot pick up objects while trying to teleport.
		if (teleport_button_down == true):
			return
		
		# Pick up RigidBody if we are not holding a object
		if held_object == null:
			
			var rigid_body = null
			
			# If we are using a Area to grab
			if (grab_mode == "AREA"):
				# Get all of the bodies in the grab area, assuming there are any
				var bodies = grab_area.get_overlapping_bodies()
				if len(bodies) > 0:
					
					# Check to see if there is a rigid body among the bodies inside the grab area.
					for body in bodies:
						if body is RigidBody:
							# Assuming there is no variable called NO_PICKUP in the RigidBody.
							# By adding a variable/constant called NO_PICKUP, you can make it where
							# the RigidBody cannot be picked up by the controller(s).
							if !("NO_PICKUP" in body):
								rigid_body = body
								break
			
			# We are using the raycast to grab
			elif (grab_mode == "RAYCAST"):
				# Force the raycast to update
				grab_raycast.force_raycast_update()
				# Check if the raycast is colliding.
				if (grab_raycast.is_colliding()):
					# If what the raycast is colliding with is a RigidBody and it does not have
					# a variable called NO_PICKUP, then we can pick it up
					if grab_raycast.get_collider() is RigidBody and !("NO_PICKUP" in grab_raycast.get_collider()):
						rigid_body = grab_raycast.get_collider()
			
			
			# If there was a RigidBody found using either the Area or the Raycast
			if rigid_body != null:
				
				# Assign held object to it.
				held_object = rigid_body
				
				# Store the now held RigidBody's information.
				held_object_data["mode"] = held_object.mode
				held_object_data["layer"] = held_object.collision_layer
				held_object_data["mask"] = held_object.collision_mask
				
				# Set it so it cannot collide with anything.
				held_object.mode = RigidBody.MODE_STATIC
				held_object.collision_layer = 0
				held_object.collision_mask = 0
				
				# Make the hand mesh invisible.
				hand_mesh.visible = false
				# Make the grab raycast mesh invisible.
				grab_raycast.visible = false
				
				# If the Rigidbody extends VR_Interactable_RigidBody, then call the picked_up function
				# and assign the controller variable to this controller
				if held_object is VR_Interactable_Rigidbody:
					held_object.picked_up()
					held_object.controller = self
				
				# Add a little rumble to the controller
				rumble = 0.5
		
		
		# Drop/Throw RigidBody if we are holding a object
		else:
			
			# Set the held object's RigidBody data back to what is stored.
			held_object.mode = held_object_data["mode"]
			held_object.collision_layer = held_object_data["layer"]
			held_object.collision_mask = held_object_data["mask"]
			
			# Apply a impulse in the direction of the controller's velocity.
			held_object.apply_impulse(Vector3(0, 0, 0), controller_velocity)
			
			# If the RigidBody extends VR_Interactable_Rigidbody, then call the dropped function
			# and set the controller variable to null so it knows it is no longer being held
			if held_object is VR_Interactable_Rigidbody:
				held_object.dropped()
				held_object.controller = null
			
			# Set held_object to null since this controller is no longer holding anything.
			held_object = null
			# Make the hand mesh visible.
			hand_mesh.visible = true
			
			# Make the grab raycast mesh visible if we are using the RAYCAST grab mode
			if (grab_mode == "RAYCAST"):
				grab_raycast.visible = true
			
		
		# play the pick-up/drop noise
		get_node("AudioStreamPlayer3D").play(0)
	
	
	# If the menu button is pressed...
	if button_index == 1:
		# Change modes to the opposite mode, and make the grab raycast visible/invisible as needed.
		#
		# NOTE: There are better ways to do this, but for the purposes of this tutorial, this will
		# work fine.
		if grab_mode == "AREA":
			grab_mode = "RAYCAST"
			
			if held_object == null:
				grab_raycast.visible = true
		elif grab_mode == "RAYCAST":
			grab_mode = "AREA"
			grab_raycast.visible = false


func button_released(button_index):
	
	# If the trigger button is released...
	if button_index == 15:
		
		# Make sure we are trying to teleport.
		if (teleport_button_down == true):
			
			# If we have a teleport position, and the teleport mesh is visible, then teleport the player.
			if teleport_pos != null and teleport_mesh.visible == true:
				# Because of how ARVR origin works, we need to figure out where the player is in relation to the ARVR origin.
				# This is so we can teleport the player at their current position in VR to the teleport position
				var camera_offset = get_parent().get_node("Player_Camera").global_transform.origin - get_parent().global_transform.origin
				# We do not want to account for offsets in the player's height.
				camera_offset.y = 0
				
				# Teleport the ARVR origin to the teleport position, applying the camera offset.
				get_parent().global_transform.origin = teleport_pos - camera_offset
			
			# Reset the teleport related variables.
			teleport_button_down = false
			teleport_mesh.visible = false
			teleport_raycast.visible = false
			teleport_pos = null


func sleep_area_entered(body):
	# When a body enters, check if it has can_sleep. If it has can_sleep, then make sure it cannot sleep
	# and wake it up. This makes RigidBody nodes act like the are supposed to when the player is close.
	if "can_sleep" in body:
		body.can_sleep = false
		body.sleeping = false

func sleep_area_exited(body):
	# When a body exits, check if it has can_sleep. If it has can_sleep, then make sure it can sleep again
	# to save on performance.
	if "can_sleep" in body:
		body.can_sleep = true
	
