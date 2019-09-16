extends Spatial

# A variable to track whether the target has been destoryed, a variable to
# track how long the target has been destroyed, and a constant fow how long
# the pieces of the target should last.
var destroyed = false
var destroyed_timer = 0
const DESTROY_WAIT_TIME = 80

# The amount of health the target has.
var health = 80

# The RigidBody target scene.
const RIGID_BODY_TARGET = preload("res://Assets/RigidBody_Sphere.scn")


func _ready():
	# We do not want to call physics_process because we will only use physics_process
	# for destroying the target.
	set_physics_process(false)


func _physics_process(delta):
	# If enough time has passed, destroy the target.
	destroyed_timer += delta
	if destroyed_timer >= DESTROY_WAIT_TIME:
		queue_free()


func damage(damage):
	
	# On the extremely odd chance this target could be damaged and destroyed, return
	# so no other code is called.
	if destroyed == true:
		return
	
	# Remove damage from health
	health -= damage
	
	# If the target has taken enough damage to be destroyed.
	if health <= 0:
		
		# Disable the collision shape and make the mesh invisible.
		get_node("CollisionShape").disabled = true
		get_node("Shpere_Target").visible = false
		
		# Make a RigidBody version of the target and instance it at this target's position.
		var clone = RIGID_BODY_TARGET.instance()
		add_child(clone)
		clone.global_transform = global_transform
		
		# set destroyed to true and start processing physics.
		destroyed = true
		set_physics_process(true)
		
		# Play a sound, and tell the game to remove a sphere.
		get_node("AudioStreamPlayer").play()
		get_tree().root.get_node("Game").remove_sphere()

