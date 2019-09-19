# Extend the VR_Interactable_Rigidbody class so the VR controllers know they can interact
# and call the functions defined in VR_Interactable_Rigidbody with this object.
extends VR_Interactable_Rigidbody

# A constant to define the amount of damage the sword does.
# This amount of damage is executed to every object in the sword on every _physics_process call
const SWORD_DAMAGE = 2

# A constant that defines the amount of force applied to RigidBody nodes when the sword
# collides with a CollisionBody.
const COLLISION_FORCE = 0.15

# A variable to hold the KinematicBody used to detect whether the sword is stabbing a CollisionBody node.
var damage_body = null


func _ready():
	# Get the KinematicBody the sword will use for collision detection and assign it to the
	# damage_body variable.
	damage_body = get_node("Damage_Body")
	# The KinematicBody uses the same layer/mask as the sword Rigidbody, so we need to add
	# this node as a collision exception so it does not effect the collision detection.
	damage_body.add_collision_exception_with(self)


func _physics_process(_delta):
	
	# Use the move_and_collide function to get a KinematicCollision object containing information
	# about the KinematicBody node collision, if there is one.
	# We pass in a velocity of zero, and set the test_only argument (the fourth argument) to true
	# so that the KinematicBody queries the physics world without actually causing any collisions.
	var collision_results = damage_body.move_and_collide(Vector3.ZERO, true, true, true);
	
	# If the KinematicBody collided with something...
	if (collision_results != null):
		# If the CollisionBody the sword collided with has a function called damage, then call it
		# so the CollisionBody takes damage from the sword.
		if collision_results.collider.has_method("damage"):
			collision_results.collider.damage(SWORD_DAMAGE)
		# If the CollisionBody the sword collided with has a function called apply_impulse...
		elif collision_results.collider.has_method("apply_impulse"):
			# If the sword is NOT being held by a VR controller...
			if controller == null:
				# Then move the CollisionBody using the apply_impulse function. For the direction of the
				# force applied, use the sword's RigidBody node velocity.
				collision_results.collider.apply_impulse(
					collision_results.position, 
					collision_results.normal * linear_velocity * COLLISION_FORCE)
			# If the sword IS being held by a VR controller...
			else:
				# Then move the CollisionBody using the apply_impulse function. For the direction of the
				# force applied, use the velocity of the VR controller.
				collision_results.collider.apply_impulse(
					collision_results.position,
					collision_results.normal * controller.controller_velocity * COLLISION_FORCE)
		
		# Play a sound for the sword colliding with something!
		get_node("AudioStreamPlayer3D").play()

