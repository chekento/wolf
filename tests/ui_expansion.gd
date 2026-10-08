extends SceneTree

var errors := 0

func check(value: bool,message: String) -> void:
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);errors+=1

func find_button(node: Node,prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):return node
	for child in node.get_children():
		var result := find_button(child,prefix)
		if result!=null:return result
	return null

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	WolfState.save_path="user://wolf_ui_expansion.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var rng := RandomNumberGenerator.new();rng.seed=417
	for region in [0,2,12,63,255]:
		var world := WolfWorldData.generate(region)
		var index := WolfCollisionIndex.new();index.build(world.objects)
		var equal := true
		for i in range(1500):
			var point := Vector2(rng.randf_range(-20,3220),rng.randf_range(-20,3220))
			if index.walkable(point)!=WolfWorldData.walkable(point,world.objects):equal=false;break
		check(equal,"spatial collision preserves obstacles in region %d"%region)
	var cache := WolfSessionCache.new()
	var original := cache.region_world(0)
	var position := Vector2(1600,1600)
	original.animals[0].p=position
	original.animals[0].mood="lauschen"
	cache.capture(0,original)
	for region in range(1,20):cache.region_world(region)
	check(cache.worlds.size()==WolfSessionCache.MAX_WORLDS and not cache.worlds.has(0),"large journeys keep only sixteen full region worlds")
	var returned := cache.region_world(0)
	check(returned.animals[0].p==position,"animal location survives region eviction")
	check(cache.save_cache(WolfState.save_path+".wildlife.json"),"wildlife cache saved")
	var reloaded := WolfSessionCache.new();reloaded.load_cache(WolfState.save_path+".wildlife.json")
	check(reloaded.region_world(0).animals[0].p==position,"animal location survives app restart")
	var cache_file := FileAccess.open(WolfState.save_path+".wildlife.json",FileAccess.WRITE)
	cache_file.store_string(JSON.stringify({"version":1,"animals":{"0":[{"kind":"deer","p":[{},0],"facing":[0,-1]},{"kind":"deer","p":[1600,1600],"facing":[0,-1]}]}}))
	cache_file.close()
	var damaged := WolfSessionCache.new();damaged.load_cache(WolfState.save_path+".wildlife.json")
	var recovered: Array=damaged.snapshots["0"][1].p
	check(damaged.snapshots["0"][0].is_empty() and Vector2(float(recovered[0]),float(recovered[1]))==position,"damaged wildlife entries preserve later animal indices")
	check(damaged.region_world(0).animals.size()==original.animals.size(),"damaged wildlife cache cannot prevent returning to a region")
	DirAccess.remove_absolute(WolfState.save_path+".wildlife.json")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if game.stick==null:
		check(false,"game initializes before controller tests")
		game.set_process(false)
		quit(1)
		return
	game.close_overlay()
	game.show_encounter()
	await process_frame
	var accept := find_button(game.overlay,"Diesem Duft")
	check(accept!=null,"encounter can be accepted from its menu")
	if accept!=null:accept.pressed.emit()
	check(game.state.encounter_status().accepted and not game.state.encounter_status().done,"new encounter requires new gameplay")
	game.close_overlay()
	game.state.pos=Vector2(1600,1600)
	game.stick.vector=Vector2.RIGHT
	for i in range(110):game._process(0.1)
	game.stick.reset()
	check(game.state.encounter_status().done and game.state.distance_walked>=1200,"walking fulfils a journey through actual controller movement")
	game.show_encounter()
	await process_frame
	var claim := find_button(game.overlay,"Die Erfahrung mitnehmen")
	check(claim!=null,"fulfilled encounter has a reward action")
	if claim!=null:claim.pressed.emit()
	check(game.state.completed_encounters.size()==1 and not game.state.complete_encounter(),"menu claims encounter once")
	game.close_overlay()
	game.state.pos=Vector2(2495,2140)
	game.interact()
	check(game.state.action_counts.drink==1,"drinking is counted from actual interaction")
	for animal in game.world.animals:
		if animal.get("role","")=="Vater":game.state.pos=animal.p+Vector2(10,0);break
	game.interact()
	game.howl()
	check(game.state.action_counts.greet==1 and game.state.action_counts.howl==1,"real pack greeting and near-den howl are counted")
	game.state.pos=Vector2(1580,2020)
	game.rest()
	check(game.state.action_counts.rest==1,"protected rest is counted")
	game.state.pos=Vector2(1380,2040)
	game.interact()
	check(game.state.action_counts.feed==1,"food interaction is counted")
	game.show_map()
	await process_frame
	check(absf(game.map_panel.cell_size()-minf(game.map_panel.size.x,game.map_panel.size.y)/16.0)<0.001,"atlas uses the full sixteen-by-sixteen world")
	check(game.find_map_regions("Rudelhöhle")==[0],"atlas search finds known home")
	check(game.find_map_regions(WolfWorldData.REGIONS[255].name).is_empty(),"atlas search respects unexplored names")
	game.map_panel.set_local(1)
	game.map_panel.center_on_player()
	check(game.map_panel.local_region==game.state.region,"my-location button returns local atlas to current region")
	game.show_menu();await process_frame
	check(find_button(game.overlay,"Zurück in die Wildnis")!=null,"illustrated main menu has a direct resume action")
	var time_before: float=game.state.elapsed
	game._process(30)
	check(game.state.elapsed==time_before,"expanded menus pause world and age")
	game.close_overlay()
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	game._process(30)
	check(game.state.elapsed==time_before and game.stick.vector==Vector2.ZERO,"backgrounding pauses needs, age and input")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	game._process(0.1)
	check(game.state.elapsed>time_before,"returning to the foreground resumes active time")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(is_instance_valid(game.overlay),"Android back opens the in-game menu")
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not is_instance_valid(game.overlay),"Android back closes a menu and returns to play")
	game.change_region(2,WolfWorldData.SPAWN)
	game.state.story_step=1
	game.guide_story()
	game.state.pos=game.state.waypoint_pos
	var drinks_before: int=game.state.action_counts.drink
	game.interact()
	check(game.can_walk(game.state.pos) and game.state.action_counts.drink==drinks_before+1,"story water guidance ends at a drinkable river bank")
	game.change_region(0,Vector2(1620,2240))
	for serial in range(40):
		game.state.encounter_serial=serial
		if game.state.encounter_status().task=="water_rest":game.state.begin_encounter();break
	game.state.note_action("drink")
	game.rest_cooldown=0
	var rests_before: int=game.state.action_counts.rest
	game.interact()
	check(game.state.action_counts.rest==rests_before+1 and game.state.active_encounter.rested_after_drink,"encounter rest remains usable beside family members")
	game.state.active_encounter={}
	game._release_audio()
	root.remove_child(game);game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf UI expansion suite: %d failures"%errors)
	quit(1 if errors>0 else 0)
