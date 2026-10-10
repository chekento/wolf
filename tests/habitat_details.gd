extends SceneTree

var failures := 0
const WORLD_HASH := "e316227507d877897c6918a2ca4536cd37b5e3eab0c68806712b39f4a55ee04b"

class UnderstoryProbe:
	extends WolfWorldView
	var submitted: Array[Dictionary]=[]
	func add_shape(kind: String,p: Vector3,dimensions: Vector3,color: Color,rotation: float=0,tilt: float=0) -> void:
		submitted.append({"kind":kind,"p":p,"dimensions":dimensions})
		super.add_shape(kind,p,dimensions,color,rotation,tilt)

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func baseline_understory_count(region: int,world: Dictionary) -> int:
	var biome: String=WolfWorldData.REGIONS[region].biome
	var paths := WolfWorldData.render_paths(region,world.objects)
	var count := 0
	for index in range(world.decor.size()):
		var point: Vector2=world.decor[index].p
		if WolfWildernessPaths.contains(point,paths,7) or WolfWorldData.water_blocked(point,region):continue
		if index%3==0 and biome in ["snow","alpine","coast"]:continue
		count+=1
	return count

func run() -> void:
	var hashes: Array[String]=[]
	var representatives: Array[int]=[]
	var biomes := {}
	for region in range(WolfWorldData.REGIONS.size()):
		var world := WolfWorldData.generate(region)
		hashes.append(JSON.stringify(world).sha256_text())
		var biome: String=WolfWorldData.REGIONS[region].biome
		if not biomes.has(biome):biomes[biome]=true;representatives.append(region)
	check("".join(hashes).sha256_text()==WORLD_HASH,"all 256 updated villages and provinces match the newly verified world baseline while preserving region IDs")
	var recipes := {}
	for kind in WolfForestMesh.HABITAT_KINDS:
		var mesh := WolfForestMesh.get_mesh(kind)
		var arrays: Array=mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var colors: PackedColorArray=arrays[Mesh.ARRAY_COLOR]
		var finite := vertices.size()>20 and normals.size()==vertices.size() and colors.size()==vertices.size()
		for index in range(vertices.size()):
			finite=finite and vertices[index].is_finite() and normals[index].is_finite()
			finite=finite and vertices[index].y>=-.005 and vertices[index].y<.52 and Vector2(vertices[index].x,vertices[index].z).length()<.82
		check(finite and mesh.surface_get_array_index_len(0)<=600,"original low grouped habitat has finite coloured geometry inside a tiny bounded footprint "+kind)
		check(is_same(mesh,WolfForestMesh.get_mesh(kind)),"habitat shares one cached original mesh "+kind)
		recipes[kind]=var_to_str(arrays).sha256_text()
	check(recipes.values().size()==11 and recipes.values().all(func(recipe: String):return recipes.values().count(recipe)==1),"all eleven botanical and ground groups have different original geometry")
	check(WolfForestMesh.get_mesh("grass").surface_get_array_index_len(0)<=81 and WolfForestMesh.get_mesh("fern").surface_get_array_index_len(0)<=210,"existing grass and fern topology stays unchanged")
	var tops_face_up := true
	for kind in ["habitat_litter","habitat_pebbles","habitat_fungi"]:
		var mesh := WolfForestMesh.get_mesh(kind)
		var arrays: Array=mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var top: float=mesh.get_aabb().end.y
		var tested := 0
		for index in range(vertices.size()):
			if vertices[index].y>=top-.001:
				tested+=1;tops_face_up=tops_face_up and normals[index].y>.95
		tops_face_up=tops_face_up and tested>0
	check(tops_face_up,"actual SurfaceTool leaf ridges, pebble domes and mushroom tops have upward normals for natural lighting")
	WolfState.save_path="user://wolf_habitat_test.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var game: Node=load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game);await process_frame
	game.close_overlay();game.set_process(false)
	var unchanged := true
	var clear := true
	var bounded := true
	var real_replacements := true
	var variety := {}
	var maximum_added_batches := 0
	for region in representatives:
		game.change_region(region,WolfWorldData.SPAWN)
		var before := JSON.stringify(game.world).sha256_text()
		var plan := WolfHabitatDetails.for_region(region,game.world)
		unchanged=unchanged and before==JSON.stringify(game.world).sha256_text()
		bounded=bounded and plan.entries.size()>30 and plan.entries.size()<=96 and plan.chunks.size()<=6
		var paths := WolfWorldData.render_paths(region,game.world.objects)
		var collision := WolfCollisionIndex.new();collision.build(game.world.objects)
		for index in plan.entries:
			var entry: Dictionary=plan.entries[index]
			clear=clear and entry.p==game.world.decor[index].p and not WolfWildernessPaths.contains(entry.p,paths,44)
			for offset in [Vector2.ZERO,Vector2(36,36),Vector2(-36,36),Vector2(36,-36),Vector2(-36,-36)]:
				clear=clear and collision.walkable(entry.p+offset) and not WolfWorldData.water_blocked(entry.p+offset,region)
			for object in game.world.objects:
				if object.kind=="den" and entry.p.distance_to(object.p)<150:clear=false
			variety[entry.kind]=true
		var probe := UnderstoryProbe.new();probe.game=game;probe.build_understory(WolfWorldData.REGIONS[region].biome)
		var actual_groups := 0
		var detail_batches := 0
		for entry in probe.submitted:
			if WolfForestMesh.is_habitat_mesh(entry.kind):actual_groups+=1
		for batch in probe.batches.values():
			if WolfForestMesh.is_habitat_mesh(batch.kind):detail_batches+=1
		maximum_added_batches=maxi(maximum_added_batches,detail_batches)
		real_replacements=real_replacements and probe.submitted.size()==baseline_understory_count(region,game.world) and actual_groups==plan.entries.size() and detail_batches<=6
		probe.free()
	check(unchanged,"habitat planning and actual renderer submissions never mutate generator data")
	check(clear,"every actual grouped footprint stays away from trails, water, colliders and direct den space")
	check(bounded,"all biome plans cap groups at 96 and spatial batches at six")
	check(real_replacements,"all biome renderers replace existing submitted flora one for one with zero additional instances")
	check(variety.size()>=9,"woodland, meadow, shore, marsh and snow display varied real habitat recipes")
	game.change_region(0,WolfWorldData.SPAWN)
	var home := WolfHabitatDetails.for_region(0,game.world)
	var home_kinds := {}
	for entry in home.entries.values():home_kinds[entry.kind]=true
	check(home_kinds.has("habitat_litter") and home_kinds.has("habitat_fungi") and home_kinds.has("habitat_deadwood"),"the actual home forest contains leaf, mushroom and deadwood groups instead of repeating one recipe")
	check(home==WolfHabitatDetails.build(0,game.world),"habitat selections and original decor anchors remain deterministic")
	game.map_view._prepare_ground(Color("#719348"),"forest")
	check(game.map_view.cached_habitat_count==home.entries.size(),"the actual 2D ground bake draws every shared habitat anchor")
	var baked_mesh: Mesh=game.map_view.ground_chunks[0].mesh
	game.state.pos+=Vector2(60,40);game.map_view._prepare_ground(Color("#719348"),"forest")
	check(game.map_view.ground_chunks[0].mesh==baked_mesh and game.map_view.ground_chunks.size()<=64,"moving the 2D camera reuses the bounded original ground chunks")
	game.toggle_view();await process_frame
	var actual_instances := 0
	var actual_batches := 0
	var actual_groups := 0
	var distance_limited := true
	for child in game.world_view.contents.get_children():
		if child is MultiMeshInstance3D:
			actual_instances+=child.multimesh.instance_count;actual_batches+=1
			if child.has_meta("habitat_kind"):
				actual_groups+=child.multimesh.instance_count
				distance_limited=distance_limited and child.visibility_range_end==26 and child.visibility_range_end_margin==3 and child.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	check(actual_instances==5450,"the living forest fits the verified baseline plus two unique guardian emblem instances: 5450")
	check(actual_batches<=198,"the forest adds only one guardian emblem batch beyond the fixed habitat budget")
	check(actual_groups==home.entries.size() and distance_limited,"the real 3D renderer shows shared low groups with 26m culling and no shadow overhead")
	for region in range(23):WolfHabitatDetails.for_region(region,WolfWorldData.generate(region))
	check(WolfHabitatDetails.cache.size()==16 and WolfHabitatDetails.recent.size()==16,"exploration evicts old habitat plans at the sixteen-region cache boundary")
	check(WolfForestMesh.cache.size()<=32 and WolfForestMesh.recent.size()<=32,"the original shared botanical mesh cache remains bounded")
	print("Habitat stats: ",representatives.size()," biomes; ",variety.size()," recipes; maximum ",maximum_added_batches," new detail batches; forest ",actual_instances," instances / ",actual_batches," batches")
	game.close_overlay();game.sound.stream_paused=false;game.ambient.stream_paused=false
	await create_timer(.2).timeout;game._release_audio();await create_timer(.2).timeout
	root.remove_child(game);game.queue_free();await process_frame;await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Habitat failures: ",failures)
	quit(failures)
