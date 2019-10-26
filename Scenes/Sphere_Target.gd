extends Spatial

# A variable to track whether the sphere target has been destoyed.
var destroyed = false
# A variable to track how long the target has been destroyed.
var destroyed_timer = 0
# A constant to define the length of time the target can be destroyed before it frees itself
# and the broken target pieces from the scene.
const DESTROY_WAIT_TIME = 80

# A variable to store the amount of health the sphere target has
var health = 80

# A constant to hold the scene of the destroyed sphere target. The destroyed sphere target
# uses a bunch of RigidBody nodes and a broken sphere target model when the target is destroyed
# it appears to shatter into a bunch of pieces.
const RIGID_BODY_TARGET = preload("res://Assets/RigidBody_Sphere.scn")


func _ready():
	# Tell this script not to execute _physics process. We want to disable _physics_process for now
	# because we will only be using _physics_process for destroying this node when the destroyed_timer
	# has reached the time (in seconds) defined in DESTROY_WAIT_TIME
	set_physics_process(false)


func _physics_process(delta):
	# Add time, delta, to the destroyed_timer variable.
	destroyed_timer += delta
	# If the destroyed_timer variable is more than DESTROY_WAIT_TIME, free/remove the sphere
	# target from the scene.
	if destroyed_timer >= DESTROY_WAIT_TIME:
		queue_free()


func damage(damage):
	# If for some reason the damage function is called and the target has already been destroyed
	# simply return so nothing is messed up.
	if destroyed == true:
		return
	
	# Remove damage from health
	health -= damage
	
	# If the health variable is less than zero, the target has taken enough damage to be destroyed...
	if health <= 0:
		
		# Disable the collision shape so nothing can collide with the non-broken sphere target.
		get_node("CollisionShape").disabled = true
		# Make the non-broken sphere target mesh invisible.
		get_node("Shpere_Target").visible = false
		
		# Instance the RIGID_BODY_TARGET scene, add it as a child of this node, and set its
		# global_transform variable to this target's global_transform so it has the same scale,
		# rotation, and is at the same position.
		var clone = RIGID_BODY_TARGET.instance()
		add_child(clone)
		clone.global_transform = global_transform
		
		# Set the destroyed variable to true so the code knows the target has been destroyed
		destroyed = true
		# Tell this script to start executing _physics process. This will start the timer that will
		# eventually free/remove the sphere target from the scene
		set_physics_process(true)
		
		# Play a destruction sound
		get_node("AudioStreamPlayer").play()
		# Tell the Game.gd script to remove a sphere from the sphere count.
		get_tree().root.get_node("Game").remove_sphere()

