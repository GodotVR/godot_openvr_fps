extends Control

# NOTE: This script controls the "main" VR GUI that shows the VR controls and the amount
# of spheres left to destroy.

# A variable to hold the Label node that shows the amount of spheres remaining in the scene
var sphere_count_label

func _ready():
	# Get the Label node
	sphere_count_label = get_node("Label_Sphere_Count")

	# Get the root node of the Game scene and assign this script to sphere_ui.
	# This makes it where the update_ui function will get called when a sphere
	# in the scene is destroyed.
	get_tree().root.get_node("Game").sphere_ui = self


func update_ui(sphere_count):
	# If there is at least a single sphere remaining...
	if sphere_count > 0:
		# Update the label text to show how many spheres are remaining.
		sphere_count_label.text = str(sphere_count) + " Spheres remaining"
	# If no spheres are left...
	else:
		# Then change the label to reflect the change
		sphere_count_label.text = "No spheres remaining! Good job!"

