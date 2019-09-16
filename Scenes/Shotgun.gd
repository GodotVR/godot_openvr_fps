# Extend the VR_Interactable_Rigidbody class so the VR controllers know they can interact
# and call the functions defined in VR_Interactable_Rigidbody with this object
extends VR_Interactable_Rigidbody

# The mesh used to make the end of the shotgun flash,
# a constant for how long the shotgun flash is visible,
# and a variable for tracking how long the flash has been visible.
var flash_mesh
const FLASH_TIME = 0.25
var flash_timer = 0

# A long rectangle mesh used for the laser sight.
var laser_sight_mesh

# The Raycast nodes used for the shotgun firing, the amount of damage the bullet does, and how much
# the bullets move Rigidbody nodes upon collision
var raycasts
const BULLET_DAMAGE = 30
const COLLISION_FORCE = 4


func _ready():
	# Get the nodes, assign them to the proper variables, and make sure the mesh is not visible.
	flash_mesh = get_node("Shotgun_Flash")
	flash_mesh.visible = false
	
	laser_sight_mesh = get_node("LaserSight")
	laser_sight_mesh.visible = false
	
	raycasts = get_node("Raycasts")


func _physics_process(delta):
	# If the flash is visible, then remove time from flash_timer (which is a inverted timer, counts down instead of up)
	if flash_timer > 0:
		flash_timer -= delta
		# If the flash has been visible enough, then make the flash mesh invisible.
		if flash_timer <= 0:
			flash_mesh.visible = false


# Called when the interact button is pressed while the object is held.
func interact():
	
	# If the flash timer says the flash mesh is not visible, then we can fire again.
	if flash_timer <= 0:
		
		# Reset the flash timer and make the flash mesh visible again.
		flash_timer = FLASH_TIME
		flash_mesh.visible = true
		
		# Go through every raycast in the raycasts node
		for raycast in raycasts.get_children():
			
			# Rotate the racyast randomly around a small 10 degrees to 10 degrees cone.
			raycast.rotation_degrees = Vector3(90 + rand_range(10, -10), 0, rand_range(10, -10))
			
			# Update the raycast and see if it has collided with anything
			raycast.force_raycast_update()
			if raycast.is_colliding():
				
				# Get whatever the raycast collided with
				var body = raycast.get_collider()
				# Get the distance to the collision point
				var raycast_distance = global_transform.origin.distance_to(raycast.get_collision_point())
				
				# If the body has the damage method, then use that, otherwise use apply_impulse.
				if body.has_method("damage"):
					body.damage(BULLET_DAMAGE)
				elif body.has_method("apply_impulse"):
					#var direction_vector = raycast.global_transform.basis.z.normalized()
					var direction_vector = -raycasts.global_transform.basis.z.normalized()
					# Change the force based on the distance from the shotgun!
					var collision_force = (COLLISION_FORCE / raycast_distance) * body.mass
					body.apply_impulse((raycast.global_transform.origin - body.global_transform.origin).normalized(), direction_vector * collision_force)
		
		# Play a sound
		get_node("AudioStreamPlayer3D").play()
		
		# Add a little rumble to the controller
		if controller != null:
			controller.rumble = 0.25


# Called when the object is picked up.
func picked_up():
	# Make the laser sight mesh visible.
	laser_sight_mesh.visible = true


# Called when the object is dropped.
func dropped():
	# Make the laser sight mesh invisible.
	laser_sight_mesh.visible = false

