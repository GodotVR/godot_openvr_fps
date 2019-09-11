extends RigidBody

# The amount of damage a single sword slice does.
const SWORD_DAMAGE = 20

# The controller that is holding the sword, if there is one.
# This is set by the controller, so we do not need to check anything.
var controller

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


# Called when the interact button is pressed while the object is held.
func interact():
	pass


# Called when the object is picked up.
func picked_up():
	pass


# Called when the object is dropped.
func dropped():
	pass


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
			
			# Calculate roughly what direction the sword collided with the object at.
			var direction_vector = sword_part.global_transform.origin - body.global_transform.origin
			
			# If there is not a controller holding the sword, use the RigidBody node's velocity to move the object(s).
			# If there IS a controller holding the sword, then use the controller's velocity to move the object(s)
			if controller == null:
				body.apply_impulse(direction_vector.normalized(), direction_vector.normalized() * self.linear_velocity)
			else:
				body.apply_impulse(direction_vector.normalized(), direction_vector.normalized() * controller.controller_velocity)
			
			# Play a sound
			get_node("AudioStreamPlayer3D").play()
			
		

