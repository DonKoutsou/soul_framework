@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	var sourceFile = get_source_file()
	var filePath = sourceFile.substr(0, sourceFile.length() - get_source_file().get_file().length())
	print("Saving at {0}".format([filePath]))

	for g in scene.get_children():
		
		if (g is MeshInstance3D):
			var MeshSaveFilePath = filePath
			var MeshName : String
			var M = g.mesh
			
			MeshName = g.name
			
			ResourceSaver.save(M, MeshSaveFilePath + MeshName + ".res",ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
			
	return scene # Remember to return the imported scene
