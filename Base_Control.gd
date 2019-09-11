extends Control

# While not the best name (Base_Control) this is the control
# node that drives the UI displaying the controls, and showing
# the amount of spheres left to destroy.

# The label that show how many spheres are remaining.
var sphere_count_label

func _ready():
	sphere_count_label = get_node("Label_Sphere_Count")
	
	# Get the root node of the Game scene, and assign this script to sphere_ui so
	# update_ui gets called when a sphere is removed.
	get_tree().root.get_node("Game").sphere_ui = self

func update_ui(sphere_count):
	# Update the text to show how many spheres are remaining if there is more
	# than zero sphere's left.
	if sphere_count > 0:
		sphere_count_label.text = str(sphere_count) + " Spheres remaining"
	# No sphere's are left, so show a different message!
	else:
		sphere_count_label.text = "No spheres remaining! Good job!"

