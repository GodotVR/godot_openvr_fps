# Extend the VR_Interactable_Rigidbody class so the VR controllers know they can interact
# and call the functions defined in VR_Interactable_Rigidbody with this object.
extends VR_Interactable_Rigidbody

# A variable to hold the MeshInstance node used for the bomb.
# We need this so we can make the bomb mesh invisible when the bomb explodes.
var bomb_mesh

# A constant to defines how long the fuse will "burn" before we explode the bomb.
const FUSE_TIME = 4
# A variable to hold the length of time that has passed since the bomb's fuse has started to burn.
var fuse_timer = 0

# A variable to hold the Area node used to detect objects within the bomb's explosion.
var explosion_area
# A constant to define how much damage is applied with the bomb explodes.
const EXPLOSION_DAMAGE = 100
# A constant to define how long the bomb will last in the scene after it explodes.
# This value should be the same as the lifetime property of the explosion Particles node
# so the bomb is removed from the scene once the explosion particles have finished.
const EXPLOSION_TIME = 0.75
# A variable to hold the length of time that has passed since the bomb exploded.
var explosion_timer = 0
# A variable to hold whether the bomb has exploded or not
var exploded = false

# A constant that defines the amount of force applied to RigidBody nodes when the bomb
# explodes. This force is strongest when the object is right next to the bomb.
const COLLISION_FORCE = 8

# A variable to hold a reference to the Particles node used for the bomb's fuse.
var fuse_particles
# A variable to hold a reference to the Particles node used for the bomb's explosion.
var explosion_particles
# A variable to hold a reference to the AudioStreamPlayer used for the explosion sound.
var explosion_sound


func _ready():
	
	# Get the nodes from the Bomb scene and assign them to the proper class variables for later use
	bomb_mesh = get_node("Bomb")
	explosion_area = get_node("Area")
	fuse_particles = get_node("Fuse_Particles")
	explosion_particles = get_node("Explosion_Particles")
	explosion_sound = get_node("AudioStreamPlayer3D")
	
	# Tell this script not to execute _physics process. We want to disable _physics_process for now
	# because we will be using _physics_process only for the fuse and destroying the bomb.
	set_physics_process(false)


func _physics_process(delta):
	
	# Check if the fuse_timer variable is less than FUSE_TIME. If fuse_timer is less than FUSE_TIME
	# than fuse in the bomb is still 'burning' and has not exploded yet.
	if fuse_timer < FUSE_TIME:
		
		# Add time, delta, to the fuse_timer variable.
		fuse_timer += delta
		
		# Check to see if the fuse timer is more or equal to FUSE_TIME. If it is, then the fuse has
		# just ended and we need to explode the bomb!
		if fuse_timer >= FUSE_TIME:
			
			# Stop emitting particles for the fuse
			fuse_particles.emitting = false
			# Tell the explosion Particles node to run in a single shot and start emitting
			# the explosion particles.
			explosion_particles.one_shot = true
			explosion_particles.emitting = true
			# Make the bomb mesh invisible so it looks like the bomb has exploded.
			bomb_mesh.visible = false
			
			# Set the collision layer and mask to zero and set the RigidBody mode to static.
			# This will keep the bomb in the correct position and will make it unable to interact
			# with other RigidBody nodes.
			collision_layer = 0
			collision_mask = 0
			mode = RigidBody.MODE_STATIC
			
			# Go through every PhysicsBody within the explosion Area node...
			for body in explosion_area.get_overlapping_bodies():
				# If the PhysicsBody is the bomb itself, then ignore it so the bomb does not explode itself.
				if body == self:
					pass
				# If the PhysicsBody is NOT the bomb...
				else:
					# If the PhysicsBody has a function called damage, then call it so it takes explosion damage.
					if body.has_method("damage"):
						body.damage(EXPLOSION_DAMAGE)
					
					# If the PhysicsBody is a RigidBody node...
					if body is RigidBody:
						# Calculate the direction from the bomb to the PhysicsBody
						var direction_vector = body.global_transform.origin - global_transform.origin
						# Get the bomb's distance from the PhysicsBody
						var bomb_distance = direction_vector.length()
						# Calculate how much force will be applied. Account for the distance of the bomb and the
						# mass of the other object so that objects closer to the bomb are pushed farther
						# when the bomb explodes.
						var collision_force = (COLLISION_FORCE / bomb_distance) * body.mass
						# Push the PhysicsBody using the apply_impulse function!
						body.apply_impulse(Vector3.ZERO, direction_vector.normalized() * collision_force)
			
			# Set the explode variable to true so the code knows the bomb has exploded
			exploded = true
			# Play the explosion sound!
			explosion_sound.play()
	
	
	# If the bomb has exploded, then we need to wait until the particles are done.
	if exploded == true:
		
		# Add time, delta, to explosion_timer. We need to do this because we need to wait until the explosion
		# particles are finished before freeing/deleting the bomb from the scene.
		explosion_timer += delta
		
		# If explosion_timer is more than or equal to EXPLOSION_TIME, then the explosion particles have finished
		if explosion_timer >= EXPLOSION_TIME:
			
			# In Godot 3.0.2 there was a bug when you remove a Area node with the monitoring property
			# set to true and the node is freed.
			# To ensure this bug does not happen for this project, we will set monitoring to false.
			explosion_area.monitoring = false
			
			# If there is a VR controller holding this bomb, we need to tell it that the controller is now
			# holding nothing.
			if controller != null:
				# Set the held object to null, and make the hand mesh visible.
				controller.held_object = null
				controller.hand_mesh.visible = true
				
				# If the grab mode is RAYCAST, we also need to make the grab raycast
				# on the VR controller visible
				if controller.grab_mode == "RAYCAST":
					controller.grab_raycast.visible = true
			
			# Free/Delete the bomb from the scene
			queue_free()


# Called when the interact button is pressed while the object is held by a VR controller.
func interact():
	# Tell this script to start executing _physics process. _Physics_Process has all of the code for the
	# bomb's fuse and will handle waiting for the fuse, exploding the bomb, and removing the bomb
	# from the scene when the explosion is finished.
	set_physics_process(true)
	
	# Start emitting fuse particles
	fuse_particles.emitting = true

