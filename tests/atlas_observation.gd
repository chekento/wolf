extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func button_named(node: Node,prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):return node
	for child in node.get_children():
		var found := button_named(child,prefix)
		if found!=null:return found
	return null

func choose(game: Node,task: String) -> bool:
	game.state.active_encounter={}
	for serial in range(180):
		game.state.encounter_serial=serial
		if game.state.encounter_status().task==task:return game.state.begin_encounter()
	return false

func run() -> void:
	WolfState.save_path="user://wolf_atlas_observation.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var game = load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game)
	await process_frame
	game.close_overlay();game.set_process(false)
	if game.stick==null:check(false,"game starts before atlas and observation checks");quit(1);return
	game.show_map()
	await process_frame;await process_frame;await process_frame
	var small_height: float=game.map_panel.size.y
	game.select_map_region(0,true)
	game.map_panel.zoom_by(2)
	game.map_panel.pan=Vector2(37,-59)
	game.map_panel.toggle_layer("tracks");game.map_panel.toggle_layer("route")
	var old_center: Vector2=game.map_panel.pan/game.map_panel.local_scale()
	game.set_waypoint(0,Vector2(1450,1780))
	var caption: String=game.map_selection.text
	button_named(game.overlay,"Große Karte").pressed.emit()
	await process_frame;await process_frame;await process_frame
	check(game.atlas_expanded and game.map_panel.size.y>small_height+100,"large atlas gives the actual map more vertical space on the portrait viewport")
	check(game.map_panel.local_region==0 and game.map_selected==0 and is_equal_approx(game.map_panel.magnification,2),"expanding preserves detailed region, selection and zoom")
	check((game.map_panel.pan/game.map_panel.local_scale()).distance_to(old_center)<.001,"expanding preserves the same world position at the centre")
	check(game.map_panel.layers.tracks and not game.map_panel.layers.route,"expanding preserves the player's map layers")
	check(game.state.waypoint_pos==Vector2(1450,1780) and game.map_selection.text==caption,"expanding preserves the actual saved goal and its explanation")
	var back := button_named(game.overlay,"Weiter erkunden")
	check(back!=null and back.global_position.y+back.size.y<=game.ui.size.y-12,"large atlas keeps the return to outdoor play within the screen")
	var min_p: Vector2=game.map_panel.size*.5+game.map_panel.pan+(Vector2(1510,1810)-Vector2(1600,1600))*game.map_panel.local_scale()
	game.map_panel._select(min_p)
	check(game.state.waypoint_pos.distance_to(Vector2(1510,1810))<.01,"a large-map tap resolves to the actual detailed world coordinate")
	button_named(game.overlay,"Liste").pressed.emit()
	await process_frame;await process_frame;await process_frame
	check(not game.atlas_expanded and game.map_places.get_child_count()==WolfWorldData.SITES_PER_REGION+1,"returning to the atlas list restores real selectable nature places")
	check((game.map_panel.pan/game.map_panel.local_scale()).distance_to(old_center)<.001,"returning from the large atlas preserves the geographic centre")
	game.select_map_region(255,true)
	game.show_map(true,game.atlas_view_state())
	await process_frame;await process_frame;await process_frame
	var before_goal: Vector2=game.state.waypoint_pos
	game.map_panel._select(game.map_panel.size*.5)
	check(game.state.waypoint_pos==before_goal and game.find_map_regions(WolfWorldData.REGIONS[255].name).is_empty(),"the expanded atlas does not reveal or choose undiscovered nature places")
	game.close_overlay()
	game.state=WolfState.new();game.state.sound_enabled=false
	game.state.pos=Vector2(1600,1800)
	check(choose(game,"quiet_watch"),"a real quiet observation can be accepted")
	var kind: String={"Reh":"deer","Hase":"rabbit","Fuchs":"fox"}[game.state.active_encounter.detail]
	var watched := {"kind":kind,"p":Vector2(1600,1540),"home":Vector2(1600,1540),"phase":0.0,"mood":"lauschen","alarm":0.0,"facing":Vector2.UP,"speed":0.0,"gait":0.0}
	var nearer := watched.duplicate(true);nearer.p=Vector2(1600,1600);nearer.home=nearer.p;nearer.phase=2.0
	game.world.animals=[watched];game.world.objects=[]
	if not game.first_person:game.toggle_view()
	game.world_view.yaw=0;game.world_view.pitch=-.14;game.player_speed=0
	game._refresh_observation_hud()
	check(game.observation_panel.visible and game.observation_hint.text.contains("Beobachten"),"live observation prompts the real start action before counting")
	check(game.observation_panel.mouse_filter==Control.MOUSE_FILTER_IGNORE and game.observation_progress.mouse_filter==Control.MOUSE_FILTER_IGNORE,"live observation leaves look and movement touch gestures available")
	check(game.observe(),"the real observation action starts the selected animal")
	game.world.animals=[nearer,watched]
	check(WolfPackLife.animal_key(game.observation_candidate())==WolfPackLife.animal_key(watched),"a nearer second animal cannot steal the accepted observation identity")
	for i in range(20):game._tick_wildlife_observation(.1)
	game._refresh_observation_hud()
	check(game.observation_progress.value>1.9 and game.observation_hint.text.contains("2.0 / 12"),"live observation displays actual accumulated quiet seconds")
	game.player_speed=5;game._tick_wildlife_observation(.1);game._refresh_observation_hud()
	check(game.observation_hint.text.contains("Bleib stehen") and game.observation_progress.value<2.01,"movement pauses real observation and explains the missing condition")
	game.player_speed=0;watched.alarm=2;game._tick_wildlife_observation(.1);game._refresh_observation_hud()
	check(game.observation_hint.text.contains("aufgeschreckt") and game.observation_progress.value<2.01,"alarm pauses real observation and appears in the live feedback")
	watched.alarm=0;game.world.objects=[{"kind":"tree","p":Vector2(1600,1670),"scale":1.0,"variant":0}]
	game._refresh_observation_hud()
	check(game.observation_hint.text.contains("Suche dasselbe") and game.observation_progress.value<2.01,"blocked line of sight asks for the same animal without advancing time")
	game.world.objects=[];game.guide_encounter()
	check(game.state.waypoint_pos.distance_to(watched.p+Vector2(0,230))<.01,"accepted observation guidance follows its selected animal rather than a nearer one")
	game.toggle_view();game._refresh_observation_hud()
	check(not game.observation_panel.visible,"wildlife observation feedback disappears in overhead play")
	game.state.active_encounter={};game.state.escort=true;game.state.bond=60
	check(choose(game,"pack_walk"),"a real shared pack walk is available with an escort")
	game._refresh_observation_hud()
	check(game.observation_panel.visible and game.observation_title.text.contains("Ruhepunkt 1"),"pack walk guidance also works in the default overhead view")
	game.state.pos=game.state.active_encounter.first_pos
	var parent := {"kind":"wolf","young":false,"companion":true,"p":game.state.pos+Vector2(25,0),"speed":0.0}
	game.state.tick_pack_walk(.1,parent,0)
	game._refresh_observation_hud()
	check(game.observation_hint.text.contains("Gemeinsam lauschen") and game.observation_progress.value>.09,"pack feedback shows joint rest only after the real parent has arrived")
	game.show_map(true);game._refresh_observation_hud()
	check(not game.observation_panel.visible,"open planning menus hide outdoor encounter feedback")
	game._release_audio();await create_timer(.2).timeout
	root.remove_child(game);game.queue_free()
	await process_frame;await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf atlas observation suite: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
