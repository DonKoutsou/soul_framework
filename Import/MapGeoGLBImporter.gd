@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	var sourceFile = get_source_file()
	var filePath = sourceFile.substr(0, sourceFile.length() - get_source_file().get_file().length())
	print("Saving at {0}".format([filePath]))
	# Change all node names to "modified_[oldnodename]"
	for g in scene.get_children():
		
		if (g is MeshInstance3D):
			var MeshSaveFilePath = filePath
			var MeshName : String
			var M = g.mesh
			if (g.name.find("Test") != -1):
				#MeshSaveFilePath += "Test/"
				MeshName = g.name.erase(0, 5)
			else: if (g.name.find("DungeonSmall") != -1):
				MeshSaveFilePath += "DungeonSmall/"
				MeshName = g.name.erase(0, 13)
			else: if (g.name.find("Dungeon") != -1):
				MeshSaveFilePath += "Dungeon/"
				MeshName = g.name.erase(0, 8)
			else: if (g.name.find("Mine") != -1):
				MeshSaveFilePath += "Mine/"
				MeshName = g.name.erase(0, 5)
			else: if (g.name.find("Forest") != -1):
				MeshSaveFilePath += "Forest/"
				MeshName = g.name.erase(0, 7)
			else: if (g.name.find("House") != -1):
				MeshSaveFilePath += "House/"
				MeshName = g.name.erase(0, 6)
			else: if (g.name.find("Cave") != -1):
				MeshSaveFilePath += "Cave/"
				MeshName = g.name.erase(0, 5)
			else: if (g.name.find("GraveYard") != -1):
				MeshSaveFilePath += "GraveYard/"
				MeshName = g.name.erase(0, 10)
			
			else:
				MeshName = g.name
				#print("thing")
			for SurfaceIndex in M.get_surface_count():
				var MatName = M.surface_get_material(SurfaceIndex).resource_name
				if (MatName == ""):
					continue
				var MatDir = "res://Engine/Shaders/Materials/" + MatName + ".tres"
				if (!ResourceLoader.exists(MatDir, "*.tres")):
					MatDir = "res://Shaders/MapMaterials/" + MatName + ".tres"
				M.surface_set_material(SurfaceIndex, load(MatDir))
				#print(Mat.resource_name)
			#var dir : DirAccess = DirAccess.open(MeshSaveFilePath)
			#dir.remove(MeshName + ".res")
			#OS.move_to_trash(ProjectSettings.globalize_path(MeshSaveFilePath  + MeshName + ".res"))
			#DirAccess.remove(MeshSaveFilePath + "" + ".res")
			#if (ResourceLoader.exists(MeshSaveFilePath + MeshName + ".res", "*.res")):
				#var t = ResourceLoader.load(MeshSaveFilePath + MeshName + ".res", "", ResourceLoader.CACHE_MODE_REPLACE) as Mesh
				#M.take_over_path(t.resource_path)
			ResourceSaver.save(M, MeshSaveFilePath + MeshName + ".res",ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
			
	return scene # Remember to return the imported scene
