@tool
extends EditorScenePostImport

class_name Enemy_Visual_Importer

const SKELETON_SCENE := "res://Engine/Controllers/Fight_Characters/EnemyRig/EnemyRigSkeleton.tscn"
const PLAYER_SKELETON_SCENE := "res://Engine/Controllers/Fight_Characters/PlayerRig/PlayerRigSkeleton.tscn"
const NPC_SKELETON_SCENE := "res://Engine/Assets/Characters/DummyNPC/NPC_RigSkeleton.tscn"
func _post_import(scene):
	#Remove get and save separatly
	var sourceFile = get_source_file()
	var filePath = sourceFile.substr(0, sourceFile.length() - get_source_file().get_file().length())
	print("Saving at {0}".format([filePath]))
	
	var VisualRoot = Node3D.new()
	var skeletonScene : PackedScene 
	if (scene.name.containsn("player")):
		skeletonScene = load(PLAYER_SKELETON_SCENE)
	else : if (scene.name.containsn("npc")):
		skeletonScene = load(NPC_SKELETON_SCENE)
	else:
		skeletonScene = load(SKELETON_SCENE)
		
	var skeleton : Skeleton3D = skeletonScene.instantiate()
	
	for g in scene.get_children():
		if (g is MeshInstance3D):
			scene.remove_child(g)
			g.owner = null
			VisualRoot.add_child(g)
			g.owner = VisualRoot
			
			var mesh = g.mesh
			var correctMat : Material
			match (mesh.surface_get_material(0).resource_name):
				"TestMat":
					correctMat = load("res://Engine/Shaders/Materials/TestMat.tres")
				"Leather":
					correctMat = load("res://Shaders/MapMaterials/Leather.tres")
				"Metal":
					correctMat = load("res://Shaders/MapMaterials/Metal_UV.tres")
				"Gold":
					correctMat = load("res://Shaders/MapMaterials/Gold.tres")
				"Clothing":
					correctMat = load("res://Shaders/MapMaterials/Characters/Goblin/GoblinClothing.tres")
				"GoblinEyes":
					correctMat = load("res://Shaders/MapMaterials/Characters/Goblin/GoblinEyes.tres")
			
			var boneName : String = ""
			for boneIndex in skeleton.get_bone_count():
				boneName = skeleton.get_bone_name(boneIndex)
				var importedBoneName = boneName.replace(".", "_")

				var meshBoneName = g.name.substr(g.name.length() - importedBoneName.length())
				if (meshBoneName == importedBoneName):
					break
			
			if (boneName == ""):
				mesh.surface_set_material(0, correctMat)
				printerr("Missing bone name skipping skinning")
				ResourceSaver.save(mesh, filePath + "{0}.res".format([g.name]),ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
				g.mesh = load(filePath + "{0}.res".format([g.name]))
			else:
				var skinnedMesh : ArrayMesh = build_skinned_mesh(mesh, skeleton, boneName)
				skinnedMesh.surface_set_material(0, correctMat)
				ResourceSaver.save(skinnedMesh, filePath + "{0}.res".format([g.name]),ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
				g.mesh = load(filePath + "{0}.res".format([g.name]))
				g.skin = skinnedMesh.get_meta("generated_skin")
			#g.mesh = load()
		
	var packedVisuals = PackedScene.new()
	packedVisuals.pack(VisualRoot)
	ResourceSaver.save(packedVisuals, filePath + "{0}_Visuals.tscn".format([scene.name]),ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	
	return scene # Remember to return the imported scene

func build_skinned_mesh(source_mesh: ArrayMesh, skeleton: Skeleton3D,bone_name: String) -> ArrayMesh:

	var bone_idx := skeleton.find_bone(bone_name)

	if bone_idx == -1:
		push_error("Bone not found: %s" % bone_name)
		return source_mesh

	var skin := _create_skin(skeleton)

	var result := ArrayMesh.new()

	for surface_idx in source_mesh.get_surface_count():

		var arrays := source_mesh.surface_get_arrays(surface_idx)

		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]

		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()

		for i in vertices.size():

			bones.append(bone_idx)
			bones.append(0)
			bones.append(0)
			bones.append(0)

			weights.append(1.0)
			weights.append(0.0)
			weights.append(0.0)
			weights.append(0.0)

		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights

		result.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES,
			arrays
		)

	result.set_meta("generated_skin", skin)

	return result


func _create_skin(skeleton: Skeleton3D) -> Skin:

	var skin := Skin.new()

	for bone_idx in skeleton.get_bone_count():

		var bind_pose := (
			skeleton.get_bone_global_pose(bone_idx)
			.affine_inverse()
		)
		
		skin.add_bind(bone_idx, bind_pose)
		skin.set_bind_name(bone_idx, skeleton.get_bone_name(bone_idx))

	return skin
