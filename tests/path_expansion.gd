extends SceneTree

var failures := 0
const LEGACY_WORLD_HASH := "681fd8f2d02213bd55029cfbfc777b3038bd535b1cd6459c049545340cc4f283"

class UnderstoryProbe:
	extends WolfWorldView
	var submitted: Array[Vector2]=[]
	func add_shape(_kind: String,p: Vector3,_dimensions: Vector3,_color: Color,_rotation: float=0,_tilt: float=0) -> void:
		submitted.append(Vector2(p.x/UNIT,p.z/UNIT))

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func area(points: PackedVector2Array) -> float:
	if points.size()<3:return 0.0
	var result := 0.0
	# Subtract the local origin before multiplication so shared-edge noise
	# at world coordinates around 1600 does not become a false overlap.
	var origin := points[0]
	for i in range(points.size()):result+=(points[i]-origin).cross(points[(i+1)%points.size()]-origin)
	return absf(result)*0.5

func covered(point: Vector2,paths: Dictionary) -> bool:
	for index in range(0,paths.vertices.size(),3):
		if Geometry2D.is_point_in_polygon(point,PackedVector2Array([paths.vertices[index],paths.vertices[index+1],paths.vertices[index+2]])):return true
	return false

func junction_overlap(paths: Dictionary) -> bool:
	var triangles: Array[Dictionary]=[]
	for index in range(0,paths.vertices.size(),3):
		var a: Vector2=paths.vertices[index]
		var b: Vector2=paths.vertices[index+1]
		var c: Vector2=paths.vertices[index+2]
		if ((a+b+c)/3).distance_to(paths.junction)>90:continue
		var lo := Vector2(minf(a.x,minf(b.x,c.x)),minf(a.y,minf(b.y,c.y)))
		var hi := Vector2(maxf(a.x,maxf(b.x,c.x)),maxf(a.y,maxf(b.y,c.y)))
		triangles.append({"polygon":PackedVector2Array([a,b,c]),"bounds":Rect2(lo,hi-lo)})
	for i in range(triangles.size()):
		for j in range(i+1,triangles.size()):
			if not triangles[i].bounds.intersects(triangles[j].bounds):continue
			for intersection in Geometry2D.intersect_polygons(triangles[i].polygon,triangles[j].polygon):
				if area(intersection)>0.1:return true
	return false

func run() -> void:
	var hashes: Array[String]=[]
	var unchanged := true
	var safe := true
	var terrain_contact := true
	var normals_up := true
	var branches_sparse := true
	var continuity := true
	var no_overlap := true
	var width_variation := true
	var gentle_turns := true
	var soft_edges := true
	var kinds := {}
	var faded := 0
	var total_vertices := 0
	var maximum_vertices := 0
	var painted_area := 0.0
	var start := Time.get_ticks_msec()
	for region in range(WolfWorldData.REGIONS.size()):
		var world := WolfWorldData.generate(region)
		var before := JSON.stringify(world).sha256_text()
		hashes.append(before)
		var collision := WolfCollisionIndex.new();collision.build(world.objects)
		var paths := WolfWildernessPaths.build(region,world.objects)
		if before!=JSON.stringify(world).sha256_text():unchanged=false
		kinds[paths.kind]=true
		if paths.branches.size()<2 or paths.branches.size()>3:branches_sparse=false
		total_vertices+=paths.vertices.size();maximum_vertices=maxi(maximum_vertices,paths.vertices.size())
		if not covered(paths.junction,paths):continuity=false
		if junction_overlap(paths):no_overlap=false
		for branch in paths.branches:
			if branch.fades_out:
				faded+=1
				if branch.fade[-1]!=0 or branch.half_widths[-1]>5:soft_edges=false
			if not covered(branch.points[1],paths):continuity=false
			var minimum := 99.0
			var maximum := 0.0
			for index in range(1,branch.points.size()):
				var width: float=branch.half_widths[index]
				minimum=minf(minimum,width);maximum=maxf(maximum,width)
				if width>19 or width<2:width_variation=false
				if index>1 and index<branch.points.size()-1:
					var a: Vector2=branch.points[index]-branch.points[index-1]
					var b: Vector2=branch.points[index+1]-branch.points[index]
					if a.normalized().dot(b.normalized())<0.91:gentle_turns=false
			if maximum-minimum<1.5:width_variation=false
		for index in range(0,paths.vertices.size(),3):
			var a: Vector2=paths.vertices[index]
			var b: Vector2=paths.vertices[index+1]
			var c: Vector2=paths.vertices[index+2]
			var signed_area := (b-a).cross(c-a)
			painted_area+=absf(signed_area)*0.5
			if signed_area<=0:normals_up=false
			for p in [a,b,c,(a+b+c)/3,(a+b)/2,(b+c)/2,(c+a)/2]:
				if not p.is_finite() or p.x<0 or p.y<0 or p.x>3200 or p.y>3200 or not collision.walkable(p) or WolfWorldData.water_blocked(p,region):safe=false
				if absf(WolfWorldData.height_at(p,region))>0.002:terrain_contact=false
		var colors := WolfWildernessPaths.vertex_colors(paths,paths.color)
		if colors.size()!=paths.vertices.size() or not paths.weights.has(0.0) or not paths.weights.has(0.86):soft_edges=false
		for color in colors:
			if color.a<0 or color.a>0.69:soft_edges=false
	print("Natural paths: %d vertices, max %d per region, %d fading arms, %d floor types, %.3f%% painted area; %d ms"%[total_vertices,maximum_vertices,faded,kinds.size(),painted_area/(256*3200*3200)*100,Time.get_ticks_msec()-start])
	check("".join(hashes).sha256_text()==LEGACY_WORLD_HASH,"all 256 complete generated worlds match the actual 0.7 baseline including objects, animals, tracks and decor")
	check(unchanged,"visual trail generation leaves every original world and RNG-derived position untouched")
	check(safe,"every trail triangle vertex, edge midpoint and centre stays on actual dry unobstructed ground")
	check(terrain_contact,"the new curves retain exact legacy flat-ground contact without changing player or animal terrain height")
	check(normals_up,"all shared trail triangles have consistent upward-facing world normals")
	check(branches_sparse and painted_area/(256*3200*3200)<0.017,"each region has two or three sparse narrow arms rather than a painted four-way road")
	check(continuity and no_overlap,"all 256 real junctions join their strip mouths without gaps or overlapping road surfaces")
	check(width_variation,"trail widths vary smoothly and remain less than 38 world units across")
	check(gentle_turns,"trail sections turn gradually instead of producing angular street corners")
	check(soft_edges and faded>40,"soft shoulders and disappearing ends fade into the existing natural floor")
	check(kinds.size()==8,"leaf litter, needles, grass, peat, stone, gravel, sand and snow use distinct floor styles")
	var home_world := WolfWorldData.generate(0)
	var home_paths := WolfWildernessPaths.build(0,home_world.objects)
	var den_quiet := true
	for point in home_paths.vertices:
		if point.distance_to(Vector2(1580,2180))<370 or point.distance_to(WolfWorldData.SPAWN)<300:den_quiet=false
	check(den_quiet and home_paths.branches.all(func(branch: Dictionary):return branch.direction!="south"),"the home den, family and spawn have natural floor without a broad southbound road")
	check(not WolfWildernessPaths.contains(WolfWorldData.SPAWN,home_paths,7),"the player's home clearing is available for low noncolliding natural understory")
	check(home_paths==WolfWildernessPaths.build(0,home_world.objects),"visual trail curves, widths, junction and colours are deterministic")
	check(home_paths.vertices!=WolfWildernessPaths.build(1,WolfWorldData.generate(1).objects).vertices,"neighbouring regions do not repeat the same path geometry")
	for region in range(22):WolfWorldData.render_paths(region,WolfWorldData.generate(region).objects)
	check(WolfWildernessPaths.cache.size()==16 and WolfWildernessPaths.recent.size()==16,"shared visual trail cache remains bounded while exploring new regions")
	var shared := WolfWorldData.render_paths(0,home_world.objects)
	check(is_same(shared,WolfWorldData.render_paths(0,home_world.objects)),"2D, 3D and both maps reuse the same cached regional trail data")
	for point in [Vector2(14,1600),Vector2(3186,1600),Vector2(1600,14),Vector2(1600,3186)]:
		check(WolfWorldData.walkable(point,home_world.objects) and not WolfWorldData.water_blocked(point,0),"existing home border transition remains genuinely walkable "+str(point))
	var river := WolfWorldData.generate(6)
	var river_motion := WolfAnimalMotion.new();river_motion.configure(6,river.objects)
	for y in [800,1600,2600]:
		var start_point := river_motion.nearest_free(Vector2(WolfWorldData.river_x(y)-180,y),100)
		var end_point := river_motion.nearest_free(Vector2(WolfWorldData.river_x(y)+180,y),100)
		var route := river_motion.route(start_point,end_point)
		route.insert(0,start_point)
		var bridge_open := route.size()>1
		for index in range(route.size()-1):
			if not river_motion.segment_free(route[index],route[index+1]):bridge_open=false
		check(bridge_open,"existing river bridge retains its actual dry crossing at "+str(y))
	WolfState.save_path="user://wolf_path_expansion.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var game: Node=load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game);await process_frame
	game.close_overlay();game.set_process(false)
	game.change_region(0,WolfWorldData.SPAWN)
	game.map_view._prepare_ground(Color("#719348"),"forest")
	var map_vertices=game.map_view.path_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var same_shape: bool=map_vertices.size()==shared.vertices.size()
	for index in range(mini(map_vertices.size(),shared.vertices.size())):
		if Vector2(map_vertices[index].x,map_vertices[index].y).distance_to(shared.vertices[index])>0.01:same_shape=false
	check(same_shape,"the live 2D floor uses the shared tapered junction mesh instead of legacy polylines")
	var cached_mesh: Mesh=game.map_view.path_mesh
	game.state.pos+=Vector2(60,40);game.map_view._prepare_ground(Color("#719348"),"forest")
	check(game.map_view.path_mesh==cached_mesh,"camera movement reuses the existing trail mesh without rebaking it")
	var probe := UnderstoryProbe.new();probe.game=game;probe.build_understory("forest")
	var reclaimed := 0
	for point in probe.submitted:
		if WolfWorldData.on_path(point,0,48) and not WolfWildernessPaths.contains(point,shared,7):reclaimed+=1
	check(reclaimed>40,"actual low flora reclaims the formerly empty road reservations outside the narrow trails")
	probe.free()
	game.toggle_view()
	var trail: MeshInstance3D=game.world_view.contents.get_node("WildernessPaths")
	var arrays: Array=trail.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var matches: bool=vertices.size()==shared.vertices.size()
	var follows_floor := true
	for index in range(mini(vertices.size(),shared.vertices.size())):
		var point: Vector2=shared.vertices[index]
		if Vector2(vertices[index].x,vertices[index].z).distance_to(point*WolfWorldView.UNIT)>0.0001:matches=false
		if absf(vertices[index].y-WolfWorldData.height_at(point,0)-0.012)>0.0001 or normals[index].y<0.99:follows_floor=false
	check(matches and follows_floor,"the live 3D trails share exactly the 2D shape and sit on the same upward-facing terrain")
	var rendered_colors: PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	var palette: PackedColorArray=WolfWildernessPaths.vertex_colors(shared,game.world_view.seasonal_color(shared.color))
	var calibrated_palette := rendered_colors.size()==palette.size()
	for index in range(mini(rendered_colors.size(),palette.size())):
		var wanted: Color=game.world_view.painted_colour(palette[index])
		if absf(rendered_colors[index].r-wanted.r)>0.005 or absf(rendered_colors[index].g-wanted.g)>0.005 or absf(rendered_colors[index].b-wanted.b)>0.005 or absf(rendered_colors[index].a-wanted.a)>0.005:calibrated_palette=false
	check(calibrated_palette and trail.material_override is StandardMaterial3D and not trail.material_override.vertex_color_is_srgb and trail.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA and trail.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"3D shoulders use the calibrated soil palette and soft blending without self shadows or stacked intersection ribbons")
	game.set_hud_compact(false,false);game._refresh_status();game.minimap.queue_redraw();await process_frame
	game.show_map();await process_frame
	game.map_panel.set_local(0);await process_frame
	check(game.map_panel.path_mesh.get_surface_count()==1 and game.map_panel.path_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==shared.vertices.size(),"the detailed atlas draws the same current trails rather than a contradictory old road cross")
	check(game.minimap.path_region==0 and game.minimap.path_mesh.get_surface_count()==1 and game.minimap.path_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==shared.vertices.size(),"the live minimap also follows the shared trail geometry")
	game.close_overlay();game.sound.stream_paused=false;game.ambient.stream_paused=false
	await create_timer(0.2).timeout;game._release_audio();await create_timer(0.2).timeout
	root.remove_child(game);game.queue_free();await process_frame;await create_timer(0.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Path expansion failures: ",failures)
	quit(failures)
