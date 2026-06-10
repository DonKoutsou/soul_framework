@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	# Change all node names to "modified_[oldnodename]"
	for g in scene.get_children():
		if (g is MeshInstance3D):
			processMesh(g)
		else:
			for z in g.get_children():
				if (z is Skeleton3D):
					var mesh : MeshInstance3D = z.get_child(0)
					processMesh(mesh)
			
	return scene # Remember to return the imported scene

func processMesh(mesh : MeshInstance3D) -> void:
	var sourceFile = get_source_file()
	var filePath = sourceFile.substr(0, sourceFile.length() - get_source_file().get_file().length())
	print("Saving at {0}".format([filePath]))

	var M = mesh.mesh
	var MeshName : String = mesh.name

	for SurfaceIndex in M.get_surface_count():
		var MatName = M.surface_get_material(SurfaceIndex).resource_name
		if (MatName == ""):
			continue
		var MatDir = "res://Engine/Shaders/Materials/"
			
		MatDir = MatDir + MatName + ".tres"
		M.surface_set_material(SurfaceIndex, load(MatDir))

		
	ResourceSaver.save(M, filePath + MeshName + ".res",ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	
	if (mesh.skin != null):
		var skin : Skin = mesh.skin
		var skeleton : Skeleton3D = mesh.get_parent()
		var packed_skeleton = PackedScene.new()
		packed_skeleton.pack(skeleton)
		ResourceSaver.save(skin, filePath + MeshName + "_Skin.res",ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
		ResourceSaver.save(packed_skeleton, filePath + MeshName + "_Skeleton.tscn",ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
