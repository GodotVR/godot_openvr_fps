# Extend the VR_Interactable_Rigidbody class so the VR controllers know they can interact
# and call the functions defined in VR_Interactable_Rigidbody with this object
extends VR_Interactable_Rigidbody

# The amount of damage a single sword slice does.
const SWORD_DAMAGE = 2

# The amount of force to multiply by when applying force to a RigidBody.
const COLLISION_FORCE = 0.15

var damage_body = null

func _ready():
	damage_body = get_node("Damage_Body")
	damage_body.add_collision_exception_with(self)

func _physics_process(_delta):
	var collision_results = damage_body.move_and_collide(Vector3.ZERO, true, true, true);
	
	if (collision_results != null):
		if collision_results.collider.has_method("damage"):
			collision_results.collider.damage(SWORD_DAMAGE)
		elif collision_results.collider.has_method("apply_impulse"):
			if controller == null:
				collision_results.collider.apply_impulse(
					collision_results.position, 
					collision_results.normal * linear_velocity * COLLISION_FORCE)
			else:
				collision_results.collider.apply_impulse(
					collision_results.position,
					collision_results.normal * controller.controller_velocity * COLLISION_FORCE)
		
		# Play a sound
		get_node("AudioStreamPlayer3D").play()

