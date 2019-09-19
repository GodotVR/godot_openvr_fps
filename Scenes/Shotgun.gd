# Extend the VR_Interactable_Rigidbody class so the VR controllers know they can interact
# and call the functions defined in VR_Interactable_Rigidbody with this object.
extends VR_Interactable_Rigidbody

# A variable to hold the mesh that is used to simulate the muzzle flash on the shotgun.
var flash_mesh
# A constant to define how long the muzzle flash on the shotgun will be visible.
const FLASH_TIME = 0.25
# A variable to hold the amount of time the muzzle flash has been visible for.
var flash_timer = 0

# A variable that will hold a long mesh that will act as the shotgun's laser sight.
var laser_sight_mesh
# A variable to hold a reference to the AudioStreamPlayer used for the shotgun's firing sound.
var shotgun_fire_sound

# A variable to hold the node that holds all of the Raycast nodes that the shotgun uses for calculating
# the bullet position and normal when the shotgun is fired.
var raycasts
# A constant to define the amount of damage a single bullet does.
const BULLET_DAMAGE = 30
# A constant that defines the amount of force applied to RigidBody nodes when one of the shotgun's
# bullets collide. This force is strongest when the object is right next to the shotgun.
const COLLISION_FORCE = 4


func _ready():
	# Get the shotgun flash mesh and make it invisible by default.
	flash_mesh = get_node("Shotgun_Flash")
	flash_mesh.visible = false
	# Get the shotgun laser sight mesh and make it invisible by default.
	laser_sight_mesh = get_node("LaserSight")
	laser_sight_mesh.visible = false
	# Get the node that holds all of the Raycast nodes that will be used for the shotgun's bullets
	raycasts = get_node("Raycasts")
	# Get the AudioStreamPlayer3D used for shotgun's firing sound
	shotgun_fire_sound = get_node("AudioStreamPlayer3D")


func _physics_process(delta):
	# If the muzzle flash is visible...
	# (flash_timer will be more than zero if the pistol's muzzle flash is visible.)
	if flash_timer > 0:
		# Remove time, delta, from the flash_timer variable
		flash_timer -= delta
		# If the flash_timer variable is now zero or less, the pistol flash just finished and the
		# muzzle flash mesh should be made invisible.
		if flash_timer <= 0:
			flash_mesh.visible = false


# Called when the interact button is pressed while the object is held by a VR controller.
func interact():
	# If the muzzle flash is invisible...
	# (We can use this to limit the rate of fire for the shotgun to the length of time the muzzle
	# flash is visible)
	if flash_timer <= 0:
		
		# Set flash_timer to FLASH_TIME and make the muzzle flash mesh visible.
		flash_timer = FLASH_TIME
		flash_mesh.visible = true
		
		# Go through every raycast in the raycasts node...
		for raycast in raycasts.get_children():
			
			# If the node is not a Raycast node, then skip it!
			if not raycast is RayCast:
				continue
			
			# Rotate the racyast randomly around a small 10 degrees to 10 degrees cone.
			# This will give the shotgun 'bullet's some random spread.
			raycast.rotation_degrees = Vector3(90 + rand_range(10, -10), 0, rand_range(10, -10))
			
			# Force the raycast node to update so it collides with the latest version of the physics world.
			raycast.force_raycast_update()
			# If the raycast collided with something...
			if raycast.is_colliding():
				
				# Get the CollisionBody the raycast collided with
				var body = raycast.get_collider()
				# Use the raycast's positive Z axis to determine the direction of the raycast.
				var direction_vector = raycasts.global_transform.basis.z.normalized()
				# Get the distance from the node that holds the Raycasts to the raycast collision point.
				var raycast_distance = raycasts.global_transform.origin.distance_to(raycast.get_collision_point())
				
				# If the CollisionBody has a function called damage, then call it so it takes damage.
				if body.has_method("damage"):
					body.damage(BULLET_DAMAGE)
				# If the CollisionBody has a function called apply_impulse...
				elif body.has_method("apply_impulse"):
					# Calculate how much force will be applied. Account for the distance of the raycast and the
					# mass of the other object so that objects closer to the shotgun are pushed farther
					# when the bullet from the shotgun collides.
					var collision_force = (COLLISION_FORCE / raycast_distance) * body.mass
					# Push the CollisionBody using the apply_impulse function!
					body.apply_impulse((raycast.global_transform.origin - body.global_transform.origin).normalized(), direction_vector * collision_force)
		
		# Play the shotgun firing sound!
		shotgun_fire_sound.play()
		
		# Add a little rumble to the VR controller
		if controller != null:
			controller.rumble = 0.25


# Called when the object has just been picked up by a VR controller.
func picked_up():
	# Make the laser sight mesh visible.
	laser_sight_mesh.visible = true


# Called when the object has just been dropped up by a VR controller.
func dropped():
	# Make the laser sight mesh invisible.
	laser_sight_mesh.visible = false

