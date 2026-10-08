extends SceneTree

var failures := 0
func check(value: bool,message: String) -> void:
	if not value:push_error("FAIL: "+message);failures+=1
	else:print("PASS: "+message)

func _initialize() -> void:call_deferred("run")

func mesh_count(n: Node) -> int:
	var total := 1 if n is MeshInstance3D else 0
	for child in n.get_children():total+=mesh_count(child)
	return total

func first_mesh(n: Node) -> Mesh:
	for child in n.get_children():
		if child is MeshInstance3D:return child.mesh
	return null

func run() -> void:
	var heights := {}
	for species in ["wolf","fox","deer","rabbit"]:
		var animal := WolfAnimalModel.new()
		root.add_child(animal)
		animal.build(species)
		check(animal.legs.size()==4 and animal.knees.size()==4 and animal.ears.size()==2 and animal.eyes.size()==2,"articulated anatomy "+species)
		check(mesh_count(animal)<=18,"merged joint surfaces "+species)
		heights[species]=animal.body_height*animal.body_scale
		animal.animate(PI/2,80,"laufen",0)
		check(absf(animal.legs[0].rotation.x)>0.2,"visible movement "+species)
		animal.animate(0,0,"schnüffeln",0)
		check(animal.neck.rotation.x<-.4,"nose lowers to ground "+species)
		animal.animate(0,0,"heulen",0)
		check(animal.neck.rotation.x>0.4 and animal.jaw.rotation.x<-.1,"raised muzzle and opening jaw "+species)
		animal.animate(0,0,"ruhen",0)
		var resting_height: float=animal.torso.position.y
		animal.animate(0,0,"lauschen",.02)
		check(animal.torso.position.y>resting_height and animal.torso.position.y<animal.body_height,"soft transition from rest "+species)
		for i in range(40):animal.animate(0,0,"lauschen",.04+float(i)*.02)
		check(absf(animal.torso.position.y-animal.body_height)<.01,"standing pose restored "+species)
		var duplicate := WolfAnimalModel.new()
		root.add_child(duplicate)
		duplicate.build(species)
		check(first_mesh(animal.torso)==first_mesh(duplicate.torso),"shared species mesh "+species)
		animal.free();duplicate.free()
	check(heights.deer>heights.wolf*1.3 and heights.wolf>heights.fox and heights.fox>heights.rabbit,"species heights differ naturally")
	for kind in ["pine","leaf","trunk","stone","grass","fern","reed","flower","log","ridge","track_deer","track_rabbit","track_wolf"]:
		var mesh := WolfForestMesh.get_mesh(kind)
		check(mesh.get_surface_count()==1 and mesh.surface_get_array_len(0)>10 and mesh==WolfForestMesh.get_mesh(kind),"cached botanical mesh "+kind)
	WolfState.save_path="user://wolf_graphics_test.json"
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.close_overlay()
	game.state=WolfState.new()
	game.change_region(0,WolfWorldData.SPAWN)
	check(game.world_view.contents==null,"3D remains lazy in top-down view")
	game.toggle_view()
	var terrain_safe := true
	for i in range(3):terrain_safe=terrain_safe and game.world_view.contents.get_child(i).cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	check(terrain_safe and game.world_view.sun.shadow_enabled,"soil and paths receive wildlife shadows without self-shadow acne")
	check(game.world_view.animal_nodes.size()==game.world.animals.size(),"all wildlife appears in 3D")
	check(game.world_view.food_nodes.size()==3,"all three food sites have 3D nodes")
	var compact_tracks := true
	for n in game.world_view.track_nodes.values():compact_tracks=compact_tracks and n is MeshInstance3D and n.get_child_count()==0 and n.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	check(compact_tracks,"species footprints use one flat shared mesh per clue")
	game.state.food_cooldown=80
	game.world_view.sync_camera()
	var hidden := true
	for n in game.world_view.food_nodes:hidden=hidden and not n.visible
	check(hidden,"shared cooldown hides every food site")
	check(game.world_view.decorative_nodes.size()>0,"spatially batched understory exists")
	check(game.world_view.material_cache.size()<90,"terrain materials reused across spatial chunks")
	check(not game.world_view.follow_camera and not game.world_view.player_model.visible,"default wolf eye view hides own body")
	game.world_view.set_follow_camera(true)
	check(game.world_view.follow_camera and game.world_view.player_model.visible,"follow mode reveals articulated player")
	check(game.world_view.player_model.position==game.world_view.world_pos(game.state.pos) and is_equal_approx(game.world_view.player_model.scale.x,game.state.growth()),"player model shares movement and gradual growth")
	var camera_point := Vector2(game.world_view.camera.position.x,game.world_view.camera.position.z)/WolfWorldView.UNIT
	check(game.collision_index.walkable(camera_point) and game.world_view.camera.position.y>=game.world_view.height_at(camera_point)+0.84,"orbit avoids solids and terrain")
	var original_objects: Array=game.world.objects
	game.world.objects=original_objects.duplicate(true)
	game.world.objects.append({"kind":"tree","p":game.state.pos+Vector2(0,64),"scale":1.5,"variant":0})
	game.collision_index.build(game.world.objects)
	game.world_view.yaw=0
	game.world_view.camera_initialized=false
	game.world_view.sync_camera()
	camera_point=Vector2(game.world_view.camera.position.x,game.world_view.camera.position.z)/WolfWorldView.UNIT
	check(game.collision_index.walkable(camera_point) and camera_point.distance_to(game.state.pos)<25,"obstructed orbit safely shortens")
	game.world.objects=original_objects
	game.collision_index.build(game.world.objects)
	game.world_view.look(Vector2(400,-20000))
	check(game.world_view.pitch<=-.08 and game.world_view.pitch>=-.88,"follow orbit pitch remains above player")
	game.world_view.set_follow_camera(false)
	game.world_view.sync_camera()
	check(not game.world_view.player_model.visible and absf(game.world_view.camera.position.x-game.state.pos.x*WolfWorldView.UNIT)<.001 and absf(game.world_view.camera.position.z-game.state.pos.y*WolfWorldView.UNIT)<.001,"return to eye view preserves exact world position")
	game.state.elapsed=WolfState.DAY_SECONDS*65
	game.world_view.sync_camera()
	check(game.world_view.built_season=="Herbst","season change refreshes 3D landscape")
	game.sound.stream_paused=false;game.ambient.stream_paused=false
	game.sound.stop();game.sound.stream=null;game.ambient.stop();game.ambient.stream=null
	root.remove_child(game);game.queue_free()
	await process_frame
	await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Graphics failures: ",failures)
	quit(failures)
