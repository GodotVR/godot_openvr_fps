extends MeshInstance

# Makes a new material and makes the viewport (called GUI) texture
# the texture for the MeshInstance.

# The nodepath to the Viewport to use
export (NodePath) var gui_viewport_path;
var gui_viewport = null;


func _ready():
	
	# Get the viewport at the exported NodePath and wait two frames
	gui_viewport = get_node(gui_viewport_path)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	# Get the texture
	var gui_img = gui_viewport.get_texture()
	
	# Make a new material and set the viewport texture as the texture, then set
	# the material for this MeshInstance to the newly created material.
	var material = SpatialMaterial.new()
	material.flags_unshaded = true
	material.albedo_texture = gui_img
	material.flags_transparent = true
	set_surface_material(0, material)
