extends SceneTree

var failures := 0

func check(value: bool,message: String) -> void:
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func _initialize() -> void:
	call_deferred("run")

func choose_task(state: WolfState,task: String) -> bool:
	for serial in range(40):
		state.encounter_serial=serial
		state.encounter_preview_key=""
		if state.encounter_status().task==task:return state.begin_encounter()
	return false

func wildlife(kind: String,point: Vector2,phase: float=0) -> Dictionary:
	return {"kind":kind,"p":point,"home":point,"phase":phase,"facing":Vector2.LEFT,"mood":"grasen","speed":0.0,"gait":0.0,"alarm":0.0}

func at_hour(state: WolfState,hour: float) -> void:
	state.elapsed=fposmod(hour-7.5,24)/24*WolfState.DAY_SECONDS

func controller_steps(game: Node,seconds: float) -> bool:
	var safe := true
	for i in range(ceili(seconds/0.05)):
		var before: Array[Vector2]=[]
		for animal in game.world.animals:before.append(animal.p)
		game.clock+=0.05;game.state.tick(0.05,false,false);game._update_animals(0.05)
		var motion: WolfAnimalMotion=game.world._animal_motion
		for index in range(before.size()):
			var after: Vector2=game.world.animals[index].p
			if not motion.segment_free(before[index],after) or before[index].distance_to(after)>220*0.05+0.001:safe=false
	return safe

func run() -> void:
	var anchors_safe := true
	var anchors_connected := true
	var covers := 0
	var feeding_places := 0
	var drinkers := 0
	var checked := 0
	var started := Time.get_ticks_msec()
	for region in range(WolfWorldData.REGIONS.size()):
		var world := WolfWorldData.generate(region)
		var motion := WolfAnimalMotion.new();motion.configure(region,world.objects)
		for animal in world.animals:
			if animal.kind=="wolf":continue
			var places := motion.ecology_targets(animal)
			for field in ["forage","other_forage","shelter","water"]:
				checked+=1
				if not motion.walkable(places[field]):anchors_safe=false
				if not motion.segment_free(animal.home,places[field]):anchors_connected=false
			if places.shelter!=animal.home:covers+=1
			if places.forage!=animal.home:feeding_places+=1
			if places.has_water:drinkers+=1
	print("Ecology anchors: %d checked, %d cover, %d vegetation feeding, %d bank users; %d ms"%[checked,covers,feeding_places,drinkers,Time.get_ticks_msec()-started])
	check(anchors_safe,"all wildlife ecology destinations across 256 regions stand on dry unobstructed ground")
	check(anchors_connected,"every wildlife feeding, cover and water anchor has an actual connection to its original home")
	check(covers>3000 and feeding_places>2000,"most wildlife uses actual vegetation for shelter and feeding instead of arbitrary circles")
	check(drinkers>100,"wildlife near real accessible banks has a distinct drinking destination")
	check(WolfPackLife.wildlife_profile("deer").loud_flee>WolfPackLife.wildlife_profile("rabbit").loud_flee and WolfPackLife.wildlife_profile("rabbit").loud_flee>WolfPackLife.wildlife_profile("fox").loud_flee,"species have different attention and escape thresholds")
	var night := WolfState.new();at_hour(night,2)
	check(choose_task(night,"quiet_watch") and night.active_encounter.detail=="Fuchs","a night encounter selects an active nocturnal species")
	var day_watch := WolfState.new();at_hour(day_watch,13)
	check(choose_task(day_watch,"quiet_watch") and day_watch.active_encounter.detail=="Reh","a daytime encounter selects a suitable daytime species")

	var care := WolfState.new();care.region=2
	care.note_action("drink");care.note_action("feed");care.note_action("rest")
	check(choose_task(care,"care_route") and care.encounter_status().current==0,"old care actions do not satisfy a new three-place route")
	var care_world := WolfWorldData.generate(2)
	check(WolfWorldData.walkable(care.active_encounter.food_pos,care_world.objects) and care.active_encounter.rest_pos.distance_to(care.active_encounter.rest_pos-Vector2(112,0))<190,"care route guides to real food and reachable den interaction ground")
	care.pos=care.active_encounter.food_pos;care.note_action("feed")
	check(care.encounter_status().current==0,"food before the chosen waterside drink does not skip the first care step")
	care.pos=Vector2(2800,2900);care.note_action("drink")
	check(care.encounter_status().current==0,"a drink far from the selected bank does not fulfil an anchored care route")
	care.pos=care.active_encounter.water_pos;care.note_action("drink")
	check(care.encounter_status().current==1 and care.encounter_status().target_pos==care.active_encounter.food_pos,"a fresh chosen-bank drink leads to the actual selected food place")
	care.pos=Vector2(1380,2040)
	if care.pos==care.active_encounter.food_pos:care.pos=Vector2(2710,1520)
	care.note_action("feed")
	check(care.encounter_status().current==1,"feeding at another place does not fulfil the chosen food step")
	care.food_cooldown=120
	check(care.encounter_status().hint.contains("120"),"an already accepted food route explains a real remaining food cooldown")
	care.food_cooldown=0;care.pos=care.active_encounter.food_pos;care.note_action("feed")
	check(care.encounter_status().current==2 and care.encounter_status().target_pos==care.active_encounter.rest_pos,"actual selected feeding moves the guide to protected rest")
	care.pos=Vector2(2500,800)
	if care.pos.distance_to(care.active_encounter.rest_pos-Vector2(112,0))<190:care.pos=Vector2(710,1010)
	care.note_action("rest")
	check(care.encounter_status().current==2,"resting near another den cannot replace the selected protected stop")
	care.pos=care.active_encounter.rest_pos-Vector2(212,0);care.note_action("rest")
	check(care.encounter_status().done and care.complete_encounter(),"rest on either safe side of the selected den completes the true ordered route")
	var cooling := WolfState.new();cooling.food_cooldown=300
	var unavailable := false
	for serial in range(26):
		cooling.encounter_serial=serial;cooling.encounter_preview_key=""
		if cooling.encounter_status().task=="care_route":unavailable=true
	check(not unavailable,"new food-dependent encounters are replaced while actual food is on cooldown")

	var pair := WolfState.new();pair.note_action("observe","Reh");pair.note_action("observe","Hase")
	check(choose_task(pair,"edge_pair") and pair.encounter_status().current==0,"old observations cannot fulfil a new local two-species experience")
	pair.region=1;pair.note_action("observe",pair.active_encounter.detail);pair.region=0
	check(pair.encounter_status().current==0,"a two-species encounter only counts observations in its selected region")
	pair.note_action("observe",pair.active_encounter.detail)
	check(pair.encounter_status().current==1 and pair.encounter_status().detail==pair.active_encounter.second_detail,"the first actual species switches guidance to the other species")
	pair.note_action("observe",pair.active_encounter.detail)
	check(pair.encounter_status().current==1,"repeated observations of one species cannot impersonate two species")
	pair.note_action("observe",pair.active_encounter.second_detail)
	check(pair.encounter_status().done and pair.complete_encounter(),"two distinct new local observations complete their encounter")

	var site := WolfState.new()
	check(choose_task(site,"site_mark"),"a fresh nature-place and scent experience is available")
	site.pos=site.active_encounter.target_pos
	site.sites.append(site.active_encounter.site_id)
	site.note_action("mark")
	check(site.encounter_status().current==0,"a mark before personally rechecking the selected nature place does not count")
	site.note_action("site","0:5" if site.active_encounter.site_id!="0:5" else "0:4")
	check(site.encounter_status().current==0,"checking another known nature place does not replace the selected place")
	site.note_action("site",site.active_encounter.site_id)
	check(site.encounter_status().current==1,"an actual repeat visit can recheck an already known selected nature place")
	site.pos+=Vector2(400,0);site.note_action("mark")
	check(site.encounter_status().current==1,"a later mark elsewhere does not fulfil the anchored scent step")
	site.pos=site.active_encounter.target_pos;site.note_action("mark")
	check(site.encounter_status().done and site.complete_encounter(),"rechecking and then personally marking the chosen nature place completes its encounter")

	var watch := WolfState.new()
	check(choose_task(watch,"quiet_watch"),"a true timed wildlife encounter is available")
	var watched := wildlife("deer",Vector2(1580,1700))
	var observer := Vector2(1580,1940)
	for i in range(20):watch.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	check(watch.encounter_status().current==0,"looking alone cannot bypass the fresh deliberate observation start")
	watch.note_wildlife_observation("Reh",watched,observer,0,true)
	check(watch.active_encounter.watch_started and watch.encounter_status().current==0,"one observation action starts the timed experience without granting any elapsed time")
	watch.tick_wildlife_observation(99,"Reh",watched,observer,0,true)
	check(is_equal_approx(watch.active_encounter.watch_seconds,0.1),"a long frame cannot jump wildlife observation time")
	for invalid in ["empty","moving","running","alarmed","other","near","far","notquiet"]:
		var candidate := watched.duplicate(true)
		var position := observer
		var speed := 0.0
		var quiet := true
		if invalid=="empty":candidate={}
		elif invalid=="moving":speed=2
		elif invalid=="running":candidate.mood="fliehen"
		elif invalid=="alarmed":candidate.alarm=1
		elif invalid=="other":candidate.phase=2
		elif invalid=="near":position=watched.p+Vector2(50,0)
		elif invalid=="far":position=watched.p+Vector2(500,0)
		elif invalid=="notquiet":quiet=false
		watch.tick_wildlife_observation(0.1,"Reh",candidate,position,speed,quiet)
	check(is_equal_approx(watch.active_encounter.watch_seconds,0.1),"movement, alarm, flight, looking away, changing animal and wrong distance count no watch time")
	watch.region=1;watch.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true);watch.region=0
	check(is_equal_approx(watch.active_encounter.watch_seconds,0.1),"watch time remains tied to the accepted region")
	for i in range(59):watch.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	var path := "user://wolf-ecology-state.json"
	check(watch.save_to(path),"partial timed wildlife progress writes an atomic version-four save")
	var restored := WolfState.new()
	check(restored.load_from(path) and is_equal_approx(restored.active_encounter.watch_seconds,6.0) and restored.active_encounter.watch_animal==WolfPackLife.animal_key(watched),"partial watch duration and actual animal identity survive restart")
	for i in range(60):restored.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	check(restored.encounter_status().done and restored.complete_encounter(),"twelve real valid observation seconds complete the wildlife experience")
	var earned := restored.xp
	check(not restored.complete_encounter() and restored.xp==earned,"a timed wildlife experience grants its reward exactly once")
	for task in ["care_route","edge_pair","site_mark"]:
		var original := WolfState.new()
		check(choose_task(original,task),task+" can be prepared for persistence")
		if task=="care_route":original.pos=original.active_encounter.water_pos;original.note_action("drink")
		elif task=="edge_pair":original.note_action("observe",original.active_encounter.detail)
		else:original.pos=original.active_encounter.target_pos;original.note_action("site",original.active_encounter.site_id)
		check(original.save_to(path),task+" saves its genuine first step")
		var loaded := WolfState.new()
		check(loaded.load_from(path) and loaded.encounter_status().task==task and loaded.encounter_status().current==1,task+" restores progress and actual next-place guidance")
	var damaged := WolfState.new();choose_task(damaged,"quiet_watch")
	damaged.note_wildlife_observation("Reh",watched,observer,0,true)
	for i in range(10):damaged.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	damaged.save_to(path)
	var damaged_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	damaged_data.active_encounter.watch_seconds={"invalid":true}
	var malformed := FileAccess.open(path,FileAccess.WRITE);malformed.store_string(JSON.stringify(damaged_data));malformed.close()
	var recovered := WolfState.new()
	check(recovered.load_from(path) and recovered.encounter_status().current==0,"malformed optional watch duration restores safely without fabricated progress")
	damaged_data.active_encounter.watch_animal="fox:bad:coordinate:unknown"
	damaged_data.active_encounter.watch_seconds=9
	malformed=FileAccess.open(path,FileAccess.WRITE);malformed.store_string(JSON.stringify(damaged_data));malformed.close()
	check(recovered.load_from(path) and not recovered.active_encounter.watch_started and recovered.encounter_status().current==0,"invalid saved animal identity clears its start gate and duration")
	var damaged_care := WolfState.new();choose_task(damaged_care,"care_route");damaged_care.save_to(path)
	damaged_data=JSON.parse_string(FileAccess.get_file_as_string(path))
	damaged_data.active_encounter.food_pos=[{},0]
	malformed=FileAccess.open(path,FileAccess.WRITE);malformed.store_string(JSON.stringify(damaged_data));malformed.close()
	check(recovered.load_from(path) and recovered.active_encounter.is_empty(),"a damaged required care-place coordinate discards only the impossible task")
	damaged_care.save_to(path);damaged_data=JSON.parse_string(FileAccess.get_file_as_string(path))
	damaged_data.active_encounter.care_rest=true;damaged_data.active_encounter.care_feed=true
	malformed=FileAccess.open(path,FileAccess.WRITE);malformed.store_string(JSON.stringify(damaged_data));malformed.close()
	check(recovered.load_from(path) and recovered.encounter_status().current==0,"corrupt ordered care flags cannot skip their required first step")
	damaged.save_to(path);damaged.pack_signal={"action":"greet","at":999}
	check(damaged.load_from(path) and damaged.pack_signal.is_empty(),"loading a life clears transient pack reactions instead of replaying an old greeting")
	DirAccess.remove_absolute(path)

	WolfState.save_path="user://wolf-ecology-controller.json"
	for file in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(file):DirAccess.remove_absolute(file)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game);await process_frame
	if game.stick==null:
		check(false,"ecology controller initializes")
		game.set_process(false);game.queue_free();await process_frame;quit(1);return
	game.close_overlay();game.set_process(false)
	var vegetation := [{"kind":"bush","p":Vector2(1620,1480),"scale":1.0,"variant":0},{"kind":"flowers","p":Vector2(1650,1600),"scale":1.0,"variant":0},{"kind":"bush","p":Vector2(1830,1530),"scale":1.0,"variant":0}]
	game.state=WolfState.new();game.state.pos=Vector2(1440,1600);game.player_speed=70
	game.world={"objects":vegetation,"animals":[wildlife("deer",Vector2(1600,1600)),wildlife("rabbit",Vector2(1600,1600),2),wildlife("fox",Vector2(1600,1600),4)],"tracks":[],"decor":[]}
	game.collision_index.build(game.world.objects);game.clock=0;game._update_animals(0.05)
	check(game.world.animals[0].behavior=="flee" and game.world.animals[1].behavior=="flee" and game.world.animals[2].behavior=="alert","actual deer and hare retreat sooner than a fox under the same approach")
	game.state.pos=Vector2(2600,2600);game.player_speed=0
	check(controller_steps(game,15),"actual wildlife retreat and return walks stay bounded and obstruction-safe")
	check(game.world.animals.all(func(animal: Dictionary):return animal.get("alarm",0)==0 and animal.behavior!="flee"),"wildlife settles and resumes its own places when the wolf leaves")
	game.state=WolfState.new();game.state.pos=Vector2(1435,1600);game.player_speed=0
	game.world={"objects":vegetation,"animals":[wildlife("deer",Vector2(1600,1600))],"tracks":[],"decor":[]};game.clock=0
	game.collision_index.build(game.world.objects);game._update_animals(0.05)
	check(game.world.animals[0].get("alarm",0)==0 and game.world.animals[0].behavior!="flee","a still wolf at observation distance permits calm actual wildlife behavior")
	game.state.pos=Vector2(1440,1600);game.player_speed=70
	game.world={"objects":[{"kind":"rock","p":Vector2(1520,1600),"scale":1.4,"variant":0}],"animals":[wildlife("deer",Vector2(1600,1600))],"tracks":[],"decor":[]};game.clock=0
	game.collision_index.build(game.world.objects);game._update_animals(0.05)
	check(game.world.animals[0].get("alarm",0)==0 and game.world.animals[0].attention==0,"real rock cover blocks visual attention rather than triggering distant flee through it")
	game.state=WolfState.new();at_hour(game.state,13);game.state.pos=Vector2(2700,2700);game.player_speed=0
	game.world={"objects":vegetation,"animals":[wildlife("fox",Vector2(1600,1600))],"tracks":[],"decor":[]};game.clock=0
	game.collision_index.build(game.world.objects)
	check(controller_steps(game,12),"daytime fox walks safely toward genuine nearby cover")
	var fox: Dictionary=game.world.animals[0]
	check(fox._ecology.shelter!=fox.home and fox.p.distance_to(fox._ecology.shelter)<14 and fox.mood=="ruhen" and fox.speed==0,"a resting fox reaches actual vegetation shelter before lying down")
	game.state=WolfState.new();at_hour(game.state,23);game.state.pos=Vector2(1580,2070);game.state.bond=100
	var parent := wildlife("wolf",Vector2(1500,2070));parent.role="Mutter";parent.young=false
	game.world={"objects":[],"animals":[parent],"tracks":[],"decor":[]};game.clock=0
	game.collision_index.build(game.world.objects);game.state.note_action("greet");game._update_animals(0.05)
	check(parent.mood=="begrüßen" and parent.behavior=="greet","a new actual nearby greeting elicits a brief friendly parent response")
	check(controller_steps(game,5) and parent.behavior=="routine" and parent.target_pos==game.state.pack_routine().target,"the parent returns to its real night routine after the friendly response")
	game.state.pos=Vector2(1810,2070)
	check(controller_steps(game,3) and parent.behavior=="routine","high bond alone does not cause permanent unrequested pursuit")
	game.state.pack_signal={}
	game.set_process(false);game.sound.stream_paused=false;game.ambient.stream_paused=false
	await create_timer(0.2).timeout;game._release_audio();await create_timer(0.2).timeout
	root.remove_child(game);game.queue_free();await process_frame;await create_timer(0.15).timeout
	for file in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(file):DirAccess.remove_absolute(file)
	print("Wolf ecology expansion: %d failures"%failures)
	quit(1 if failures>0 else 0)
