@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	var sourceFile = get_source_file()
	var filePath = sourceFile.substr(0, sourceFile.length() - get_source_file().get_file().length())
	print("Saving at {0}".format([filePath]))
	
	var materialDirs : PackedStringArray = GetMaterials()
	
	for g in scene.get_children():
		
		if (g is MeshInstance3D):
			var MeshSaveFilePath = filePath
			var MeshName : String
			var M = g.mesh
			
			for surface in M.get_surface_count():
				var matName = M.surface_get_material(surface).resource_name
				var mat = FindMaterial(matName , materialDirs)
				if (mat != ""):
					print("Setting mat {0}".format([mat]))
					M.surface_set_material(surface, load(mat))
			
			MeshName = g.name
			
			ResourceSaver.save(M, MeshSaveFilePath + MeshName + ".res",ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
			
	return scene # Remember to return the imported scene

func GetMaterials() -> PackedStringArray:
	var materials : PackedStringArray
	
	var engineShaderLocation = "res://Engine/Shaders/Materials/"
	materials.append_array(GetContentsOfDir(engineShaderLocation))
	
	var projectsShaderLocation = "res://Shaders/"
	materials.append_array(GetContentsOfDir(projectsShaderLocation))

	return materials
	
func GetContentsOfDir(dir : String) -> PackedStringArray:
	var contents : PackedStringArray
	
	for sub in ResourceLoader.list_directory(dir):
		if (sub.contains("/")):
			var subContents = GetContentsOfDir(dir + sub)
			contents.append_array(subContents)
		else :
			contents.append(dir + sub)
	
	return contents

func FindMaterial(matName : String, Dirs : PackedStringArray) -> String:
	for path in Dirs:
		var mName = path.get_file().substr(0, path.get_file().length() - 5)
		if mName.to_lower() == matName.to_lower():
			return path
	return "" 
