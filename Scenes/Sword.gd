# Extend the VR_Interactable_Rigidbody class so the VR controllers know they can interact
# and call the functions defined in VR_Interactable_Rigidbody with this object
extends VR_Interactable_Rigidbody

# The amount of damage a single sword slice does.
const SWORD_DAMAGE = 20

# The amount of force to multiply by when applying force to a RigidBody.
const COLLISION_FORCE = 2

func _ready():
	# Ignore the warnings the from the connect function calls.
	# We will not need the returned value for this tutorial.
	# warning-ignore-all:return_value_discarded
	
	# Connect all of the tiny area's that compose the length of the sword.
	# We need to use several small areas so we can roughly know where on the sword the
	# object that has entered the sword is.
	get_node("Damage_Area_01").connect("body_entered", self, "body_entered_sword", ["01"])
	get_node("Damage_Area_02").connect("body_entered", self, "body_entered_sword", ["02"])
	get_node("Damage_Area_03").connect("body_entered", self, "body_entered_sword", ["03"])
	get_node("Damage_Area_04").connect("body_entered", self, "body_entered_sword", ["04"])


func body_entered_sword(body, number):
	# Make sure the body the sword has collided with is not itself.
	if body == self:
		pass
	
	else:
		
		# Figure out which part of the sword collided with the body.
		var sword_part = null
		if number == "01":
			sword_part = get_node("Damage_Area_01")
		elif number == "02":
			sword_part = get_node("Damage_Area_02")
		elif number == "03":
			sword_part = get_node("Damage_Area_03")
		elif number == "04":
			sword_part = get_node("Damage_Area_04")
		
		# If the body has the damage method/function, then use that, otherwise use apply_impulse.
		if body.has_method("damage"):
			body.damage(sword_part.global_transform.looking_at(body.global_transform.origin, Vector3(0, 1, 0)), SWORD_DAMAGE)
			
			# Play a sound
			get_node("AudioStreamPlayer3D").play()
		
		elif body.has_method("apply_impulse"):
			
			# Calculate roughly which direction the sword collided with the object at.
			var direction_vector = sword_part.global_transform.origin - body.global_transform.origin
			
			# If there is not a controller holding the sword, use the RigidBody node's velocity to move the object(s).
			# If there IS a controller holding the sword, then use the controller's velocity to move the object(s).
			# (The controller variable is defined in VR_Interactable_Rigidbody and is set by the VR controller)
			if controller == null:
				body.apply_impulse(direction_vector.normalized(), direction_vector.normalized() * linear_velocity * COLLISION_FORCE)
			else:
				body.apply_impulse(direction_vector.normalized(), direction_vector.normalized() * controller.controller_velocity * COLLISION_FORCE)
			
			# Play a sound
			get_node("AudioStreamPlayer3D").play()
			
			# Add a little rumble to the controller
			if controller != null:
				controller.rumble = 0.25
			
		

