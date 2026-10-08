extends SceneTree
var game: Node
var results: Array=[]
var output_stem := "user://wolf-render-profile"
func _initialize() -> void:call_deferred("run")
func geometry(n: Node,counts: Dictionary) -> void:
	if n is MultiMeshInstance3D:
		counts.batches+=1
		counts.instances+=n.multimesh.instance_count
		var kind := "primitive"
		for key in WolfForestMesh.cache:
			if WolfForestMesh.cache[key]==n.multimesh.mesh:kind=key;break
		counts.kinds[kind]=counts.kinds.get(kind,0)+1
	elif n is MeshInstance3D:counts.mesh_nodes+=1
	for child in n.get_children():geometry(child,counts)
func sample(name: String,region: int,three_d: bool,follow: bool) -> void:
	if game.first_person!=three_d:game.toggle_view()
	game.change_region(region,Vector2(1690,1800) if region!=2 else Vector2(1200,1640))
	game.state.facing=Vector2.UP if region!=2 else Vector2.LEFT
	game.state.elapsed=WolfState.DAY_SECONDS*.15
	game.state.sound_enabled=false
	if three_d:
		game.world_view.set_follow_camera(follow)
		game.world_view.yaw=.2 if region!=2 else PI/2
		game.world_view.camera_initialized=false
		game.world_view.update_lighting()
	game.toast.text="";game.toast_time=0
	game._refresh_status()
	for i in range(20):
		game._process(1.0/60.0)
		await process_frame
		await RenderingServer.frame_post_draw
	var samples: Array[float]=[]
	var draws := 0.0
	var primitives := 0.0
	var cpu := 0.0
	for i in range(80):
		var start := Time.get_ticks_usec()
		game._process(1.0/60.0)
		await process_frame
		await RenderingServer.frame_post_draw
		samples.append(float(Time.get_ticks_usec()-start)/1000.0)
		draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		cpu+=Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
	var sum := 0.0
	for value in samples:sum+=value
	samples.sort()
	var distribution := {"batches":0,"instances":0,"mesh_nodes":0,"kinds":{}}
	if three_d:geometry(game.world_view.contents,distribution)
	var record := {"scene":name,"mean_ms":sum/80,"median_ms":samples[40],"p90_ms":samples[72],"draws":draws/80,"primitives":primitives/80,"process_ms":cpu/80,"geometry":distribution}
	results.append(record)
	print(JSON.stringify(record))
	root.get_texture().get_image().save_png(output_stem+"-"+name+".png")
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Rendering profile requires a visible renderer; run without --headless.")
		quit(2)
		return
	if not OS.get_cmdline_user_args().is_empty():output_stem=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output_stem.get_base_dir())
	Engine.max_fps=0
	WolfState.save_path="user://wolf_render_profile_state.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	game=load("res://main.tscn").instantiate()
	game.state.sound_enabled=false
	root.add_child(game)
	await process_frame
	game.close_overlay();game.set_process(false);game.ui.hide()
	await sample("forest-2d",0,false,false)
	await sample("forest-eyes",0,true,false)
	await sample("forest-follow",0,true,true)
	await sample("snow-follow",5,true,true)
	await sample("river-follow",2,true,true)
	var report := FileAccess.open(output_stem+".json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"method":ProjectSettings.get_setting("rendering/renderer/rendering_method"),"engine":Engine.get_version_info().string,"viewport":str(root.size),"sample_frames":80,"warmup_frames":20,"hud_hidden":true,"results":results},"\t"));report.close()
	game.sound.stream_paused=false;game.ambient.stream_paused=false
	await create_timer(.2).timeout
	game._release_audio()
	await create_timer(.2).timeout
	root.remove_child(game);game.queue_free()
	await process_frame
	await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	quit()
