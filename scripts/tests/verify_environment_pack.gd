extends SceneTree

func _init() -> void:
	print("--- VERIFYING VTM ENVIRONMENT PACK IN GODOT ---")
	var path = "res://assets/models/environment/first_stage_pack.glb"
	assert(FileAccess.file_exists(path), "GLB file does not exist: " + path)
	
	var scene_res = load(path)
	assert(scene_res != null, "Failed to load GLB as PackedScene: " + path)
	
	var inst: Node = scene_res.instantiate()
	assert(inst != null, "Failed to instantiate GLB scene")
	root.add_child(inst)
	
	print("Root name:", inst.name, "Children count:", inst.get_child_count())
	var expected_nodes = [
		"Rock_Monolith_Large",
		"Rock_Monolith_Medium",
		"Rock_Monolith_Spire",
		"Ancient_Pillar_Intact",
		"Ancient_Pillar_Broken",
		"Alien_Crystal_Cluster",
		"Alien_Mushroom_Spore",
		"Teleporter_Platform"
	]
	
	for name in expected_nodes:
		var node = inst.find_child(name, true, false)
		assert(node != null, "Missing expected node in GLB: " + name)
		print("[OK] Found node: " + name)
		if node is MeshInstance3D:
			var aabb: AABB = node.mesh.get_aabb()
			print("   Mesh AABB: pos=" + str(aabb.position) + " size=" + str(aabb.size))
			assert(is_equal_approx(aabb.position.y, 0.0) or aabb.position.y >= -0.01, "Origin must be at base Z/Y=0")
	
	print("[ALL CHECKS PASSED] Environment pack successfully verified in Godot!")
	quit()
