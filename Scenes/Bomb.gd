extends RigidBody

# The MeshInstance used for the bomb.
var bomb_mesh

# A constant for how long the fuse needs to burn before the bomb explodes and
# a timer variable to track how long the fuse has been burning
const FUSE_TIME = 4
var fuse_timer = 0

# The explosion area, how much damage the explosion does,
# how long the explosion lasts (calculated using the particles), a timer variable for
# tracking how long the bomb has been exploded, and a boolean for tracking whether or not the
# bomb has exploded.
var explosion_area
var EXPLOSION_DAMAGE = 100
var EXPLOSION_TIME = 0.75
var explosion_timer = 0
var explode = false

# The particle nodes
var fuse_particles
var explosion_particles

# The controller that is currently holding this bomb, if there is one.
# This is set by the controller, so we do not need to check anything.
var controller = null

func _ready():
	
	# Get the nodes and assign them to the proper variables.
	bomb_mesh = get_node("Bomb")
	explosion_area = get_node("Area")
	fuse_particles = get_node("Fuse_Particles")
	explosion_particles = get_node("Explosion_Particles")
	
	# We do not want to process physics_process since we will be using it
	# only for the fuse and for destroying the bomb.
	set_physics_process(false)

func _physics_process(delta):
	
	# If we fuse_timer is less than FUSE_TIME, then the bomb is burning the fuse.
	if fuse_timer < FUSE_TIME:
		
		# Add time to fuse_timer.
		fuse_timer += delta
		
		# If the bomb has waited long enough and the fuse is burned through...
		if fuse_timer >= FUSE_TIME:
			
			# Stop emitting smoke particles, start emitting the explosion particles,
			# and hide the bomb mesh
			fuse_particles.emitting = false
			explosion_particles.one_shot = true
			explosion_particles.emitting = true
			bomb_mesh.visible = false
			
			# Set the collision layer and mask to zero and set the RigidBody mode to static so
			# the bomb stays put and cannot interact with the physics world.
			collision_layer = 0
			collision_mask = 0
			mode = RigidBody.MODE_STATIC
			
			# Explode everything inside the explosion area.
			for body in explosion_area.get_overlapping_bodies():
				# Make sure we are not exploding the bomb itself.
				if body == self:
					pass
				else:
					# If the body has the damage function, than use that. If it does not, then push it using apply_impulse.
					if body.has_method("damage"):
						body.damage(global_transform.looking_at(body.global_transform.origin, Vector3(0,1,0)), EXPLOSION_DAMAGE)
					elif body.has_method("apply_impulse"):
						var direction_vector = body.global_transform.origin - global_transform.origin
						body.apply_impulse(direction_vector.normalized(), direction_vector.normalized() * 1.8)
			
			# Set explode to true and play a sound
			explode = true
			get_node("AudioStreamPlayer3D").play()
	
	
	# If the bomb has exploded, then we need to wait until the particles are done.
	if explode:
		
		explosion_timer += delta
		if explosion_timer >= EXPLOSION_TIME:
			
			# In Godot 3.0.2 there is a bug when you remove a Area node with the monitoring property
			# set to true and the node is freed. To ensure this bug does not happen, we will set monitoring to false.
			explosion_area.monitoring = false
			
			# If there is a controller holding this bomb, then we need to tell it that it is no longer
			# holding a bomb, and we need to make it's hand mesh visible again.
			if controller != null:
				controller.held_object = null
				controller.hand_mesh.visible = true
				
				# If the grab mode is RAYCAST, we also need to make the grab raycast visible
				if controller.grab_mode == "RAYCAST":
					controller.grab_raycast.visible = true
			
			# Free the bomb
			queue_free()


# Called when the interact button is pressed while the object is held.
func interact():
	# Set physics_process to true so the fuse starts burning, and start emitting smoke particles
	set_physics_process(true)
	fuse_particles.emitting = true


# Call when the object is picked up.
func picked_up():
	pass

# Called when the object is dropped.
func dropped():
	pass
