extends SceneTree
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1
func run() -> void:
	var grass := WolfForestMesh.get_mesh("grass")
	var arrays: Array=grass.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var has_midpoint := false
	var heights := {}
	for point in vertices:
		heights[snappedf(point.y,.001)]=true
		if point.y>.20 and point.y<.42:has_midpoint=true
	check(grass.surface_get_array_index_len(0)<=81 and has_midpoint and heights.size()>5,"curved grass fans have intermediate bends and a small shared topology")
	check(WolfForestMesh.get_mesh("fern").surface_get_array_index_len(0)<=210,"fern fronds remain inside a bounded instanced mesh")
	for kind in ["leaf","pine"]:
		var mesh := WolfForestMesh.get_mesh(kind)
		var finite := true
		for point in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:finite=finite and point.is_finite()
		check(finite and WolfForestMesh.lod_index_counts[kind].far*3<=WolfForestMesh.lod_index_counts[kind].near,"irregular crown keeps valid native distant geometry "+kind)
	WolfState.save_path="user://wolf_landscape_test.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var game: Node=load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game)
	await process_frame
	game.close_overlay();game.set_process(false)
	game.change_region(0,WolfWorldData.SPAWN)
	game.map_view._prepare_ground(Color("#719348"),"forest")
	var tree_count := 0
	var broad_count := 0
	for object in game.world.objects:
		if object.kind=="tree":
			tree_count+=1
			if object.variant!=0:broad_count+=1
	check(tree_count>150 and game.map_view.cached_tree_shadows==tree_count,"every original forest tree casts a cached soil shadow")
	var soil: Mesh=game.map_view.ground_chunks[0].mesh
	game.state.pos+=Vector2(60,40)
	game.map_view._prepare_ground(Color("#719348"),"forest")
	check(game.map_view.ground_chunks[0].mesh==soil and game.map_view.ground_chunks.size()<=64,"camera motion reuses the bounded shadow and fern cache")
	game.toggle_view()
	var trunk_instances := 0
	var batches := 0
	var floor_found := false
	for child in game.world_view.contents.get_children():
		if child is MeshInstance3D and child.material_override is ShaderMaterial:
			var material: ShaderMaterial=child.material_override
			if material.get_shader_parameter("surface_kind")==5:
				floor_found=float(material.get_shader_parameter("forest_floor"))>.8 and child.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if child is MultiMeshInstance3D:
			batches+=1
			if child.multimesh.mesh==WolfForestMesh.get_mesh("trunk"):
				trunk_instances+=child.multimesh.instance_count
	check(broad_count>30 and trunk_instances==tree_count+broad_count and batches<220,"slanted branches reuse the original spatial grove budget")
	# Dummy cannot read GPU instance transforms. Check the actual submitted
	# transform before upload; real GL images verify the resulting branches.
	var probe := WolfWorldView.new()
	probe.add_shape("trunk",Vector3(1,3,1),Vector3(.2,1.6,.2),Color("#987654"),.4,.52)
	var submitted: Transform3D=probe.batches.values()[0].transforms[0]
	check(submitted.basis.y.length()>1.59 and submitted.basis.y.normalized().dot(Vector3.UP)<.9,"branch transform actually tilts the shared trunk geometry")
	probe.free()
	check(floor_found,"woodland soil receives litter shading without terrain self shadows")
	var model: WolfAnimalModel=game.world_view.animal_nodes[0]
	var animal: Dictionary=game.world.animals[0]
	var first_index := 2 if animal.kind=="rabbit" else 0
	var cycle_distance: float=model.stride_length()*model.scale.x/(18.0*.032)
	animal.speed=32.0;animal.mood="wandern";animal.facing=Vector2.UP
	animal.gait=cycle_distance*.08;model.rotation.y=0;model.last_time=-1
	game.world_view.sync_camera()
	var first: Vector3=model.global_transform*model.foot_position(first_index)
	animal.p.y-=cycle_distance*.08*18.0
	animal.gait=cycle_distance*.16;model.last_time=-1
	game.world_view.sync_camera()
	var second: Vector3=model.global_transform*model.foot_position(first_index)
	check(absf(second.z-first.z)<.006,"live NPC renderer cancels real gameplay travel during stance")
	var alert := WolfMapView.animal_pose("deer",Vector2.LEFT,0,0,"lauschen",false,1)
	var feeding := WolfMapView.animal_pose("deer",Vector2.LEFT,0,0,"grasen")
	var muzzle := Vector2(-39,-10)
	check(muzzle.rotated(alert.head_angle).y<muzzle.y-3 and muzzle.rotated(feeding.head_angle).y+feeding.head_drop>muzzle.y+12,"2D attention raises the muzzle while grazing lowers it")
	game.sound.stream_paused=false;game.ambient.stream_paused=false
	await create_timer(.2).timeout
	game._release_audio();await create_timer(.2).timeout
	root.remove_child(game);game.queue_free();await process_frame
	await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Landscape failures: ",failures)
	quit(failures)
