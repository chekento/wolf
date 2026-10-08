extends SceneTree

var failures := 0

func check(value: bool,message: String) -> void:
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func _initialize() -> void:
	call_deferred("run")

func choose_task(state: WolfState,task: String) -> bool:
	var initial := state.encounter_serial
	for serial in range(initial,initial+30):
		state.encounter_serial=serial;state.encounter_preview_key=""
		if state.encounter_status().task==task:return state.begin_encounter()
	return false

func animal(kind: String,point: Vector2,phase: float=0) -> Dictionary:
	return {"kind":kind,"p":point,"home":point,"phase":phase,"facing":Vector2.LEFT,"mood":"grasen","speed":0.0,"gait":0.0,"alarm":0.0}

func ecology(home: Vector2) -> Dictionary:
	return {"forage":home+Vector2(500,0),"other_forage":home+Vector2(110,140),"shelter":home+Vector2(0,-120),"water":home+Vector2(280,200),"has_water":true}

func at_hour(state: WolfState,hour: float) -> void:
	state.elapsed=fposmod(hour-7.5,24)/24*WolfState.DAY_SECONDS

func advance_controller(game: Node,seconds: float) -> bool:
	var safe := true
	for i in range(ceili(seconds/0.05)):
		var points: Array[Vector2]=[]
		for member in game.world.animals:points.append(member.p)
		game.clock+=0.05;game.state.tick(0.05,false,false);game._update_animals(0.05)
		var motion: WolfAnimalMotion=game.world._animal_motion
		for index in range(points.size()):
			if not motion.segment_free(points[index],game.world.animals[index].p) or points[index].distance_to(game.world.animals[index].p)>220*0.05+0.001:safe=false
	return safe

func run() -> void:
	var deer := animal("deer",Vector2(1500,1600));deer._ecology=ecology(deer.home)
	var unchanged := true
	for i in range(700):
		var activity := WolfPackLife.wildlife_activity(deer,8,0.1)
		if activity.target!=deer._ecology.forage:unchanged=false
	check(unchanged and deer._activity_waited==0,"a long unfinished walk keeps its actual feeding destination without spending arrival time")
	deer.p=deer._ecology.forage;deer.behavior="forage"
	for i in range(50):WolfPackLife.wildlife_activity(deer,8,0.1)
	check(deer._activity_step==0 and is_equal_approx(deer._activity_waited,5),"feeding dwell begins only on genuine arrival and advances by active frame time")
	deer.behavior="alert"
	for i in range(50):WolfPackLife.wildlife_activity(deer,8,0.1)
	check(is_equal_approx(deer._activity_waited,5),"a startled pause does not pretend to be a feeding dwell")
	deer.behavior="forage"
	for i in range(140):WolfPackLife.wildlife_activity(deer,8,0.1)
	check(deer._activity_step==1 and WolfPackLife.wildlife_activity(deer,8,0).target==deer._ecology.shelter,"after real feeding time the animal selects its reachable shelter")
	var fox := animal("fox",Vector2(1500,1600));fox._ecology=ecology(fox.home)
	check(WolfPackLife.wildlife_activity(fox,13,0.1).mood=="wandern","an inactive daytime fox first walks to its shelter")
	fox.p=fox._ecology.shelter
	check(WolfPackLife.wildlife_activity(fox,13,0.1).mood=="ruhen","the fox lies down only after reaching shelter")
	check(WolfPackLife.wildlife_activity(fox,18,0.1).target==fox._ecology.forage,"the waking fox starts a real evening feeding route")
	var joined := 0
	var connected := true
	var checked := 0
	for region in range(WolfWorldData.REGIONS.size()):
		var world := WolfWorldData.generate(region)
		var motion := WolfAnimalMotion.new();motion.configure(region,world.objects)
		for member in world.animals:
			if member.kind!="wolf":member._ecology=motion.ecology_targets(member)
		for member in world.animals:
			if member.kind!="deer":continue
			var target := motion.group_forage_target(member,world.animals)
			checked+=1
			if not motion.walkable(target) or not motion.segment_free(member.home,target):connected=false
			if target!=member._ecology.forage:joined+=1
	print("Loose deer groups: %d connected anchors checked, %d grouped destinations"%[checked,joined])
	check(connected and checked==1280,"all deer group destinations retain an actual dry route from their own home")
	check(joined>100,"deer share nearby feeding ground where the landscape leaves a real connection")

	var walk := WolfState.new();walk.escort=true
	check(choose_task(walk,"pack_walk") and walk.encounter_status().current==0,"a new joint walk requires fresh actual visits")
	var parent := animal("wolf",walk.active_encounter.first_pos+Vector2(110,0));parent.role="Mutter";parent.young=false;parent.companion=true
	walk.pos=walk.active_encounter.second_pos
	for i in range(40):walk.tick_pack_walk(0.1,parent,0)
	check(walk.encounter_status().current==0,"visiting the second pack stop first cannot bypass the first stop")
	walk.pos=walk.active_encounter.first_pos
	parent.p=walk.pos+Vector2(300,0)
	for i in range(40):walk.tick_pack_walk(0.1,parent,0)
	check(walk.encounter_status().current==0 and not walk.encounter_status().companion_ready,"the player alone cannot fulfil a joint arrival while the parent is still distant")
	parent.p=walk.pos+Vector2(100,0)
	for i in range(40):walk.tick_pack_walk(0.1,parent,0,false)
	check(walk.encounter_status().joint_seconds==0,"an obstructed nearby parent must really detour before a joint stop counts")
	for i in range(40):walk.tick_pack_walk(0.1,parent,2)
	check(walk.encounter_status().joint_seconds==0,"slow player movement does not impersonate quietly holding a joint stop")
	walk.tick_pack_walk(100,parent,0)
	check(is_equal_approx(walk.encounter_status().joint_seconds,0.1),"a stalled frame cannot skip joint pack observation time")
	for i in range(29):walk.tick_pack_walk(0.1,parent,0)
	check(walk.encounter_status().current==1 and walk.encounter_status().target_pos==walk.active_encounter.second_pos,"a real three-second joint first arrival guides the next stop")
	check(not walk.encounter_status().player_ready and not walk.encounter_status().companion_ready,"switching to the second actual stop immediately clears the first stop's live proximity")
	walk.escort=false
	check(walk.encounter_status().hint.contains("Begleitung"),"an accepted joint walk explains how to resume disabled accompaniment")
	walk.pos=walk.active_encounter.second_pos;parent.p=walk.pos+Vector2(100,0)
	for i in range(40):walk.tick_pack_walk(0.1,parent,0)
	check(walk.encounter_status().current==1,"disabled accompaniment does not fabricate a second joint arrival")
	walk.escort=true
	for i in range(10):walk.tick_pack_walk(0.1,parent,0)
	check(walk.encounter_status().player_ready and walk.encounter_status().companion_ready,"a genuine new nearby arrival supplies live player and parent readiness")
	walk.escort=false
	check(not walk.encounter_status().player_ready and not walk.encounter_status().companion_ready,"disabling accompaniment immediately masks old readiness even before another frame")
	walk.escort=true;walk.region=1
	check(not walk.encounter_status().player_ready and not walk.encounter_status().companion_ready,"another region cannot display the old joint stop's live proximity")
	walk.region=0;walk.clear_encounter_presence()
	check(not walk.encounter_status().player_ready and not walk.encounter_status().companion_ready and is_equal_approx(walk.encounter_status().joint_seconds,1),"a view or foreground reset clears live proximity while retaining real earned duration")
	walk.tick_pack_walk(0,parent,0)
	var save_path := "user://wolf-living-world-state.json"
	check(walk.save_to(save_path),"a joint route saves its genuine partial second stop")
	var restored := WolfState.new()
	check(restored.load_from(save_path) and restored.encounter_status().current==1 and is_equal_approx(restored.encounter_status().joint_seconds,1) and restored.encounter_status().target_pos==walk.active_encounter.second_pos,"joint duration and canonical next nature-place goal survive a version-four restart")
	check(not restored.encounter_status().player_ready and not restored.encounter_status().companion_ready,"loading a joint route requires fresh live proximity rather than saved readiness")
	for i in range(20):restored.tick_pack_walk(0.1,parent,0)
	check(restored.encounter_status().done and restored.complete_encounter(),"two genuine ordered joint arrivals complete the pack walk")
	var earned := restored.xp
	check(not restored.complete_encounter() and restored.xp==earned,"a joint route awards experience exactly once")
	check(choose_task(restored,"pack_walk") and restored.encounter_status().current==0,"a later joint route stays playable but cannot reuse old arrivals")
	var lone := WolfState.new()
	var impossible_pack := false
	for serial in range(30):
		lone.encounter_serial=serial;lone.encounter_preview_key=""
		if lone.encounter_status().task=="pack_walk":impossible_pack=true
	check(not impossible_pack,"a life without active accompaniment offers a feasible family task instead of an impossible joint route")

	var cycle := WolfState.new()
	check(choose_task(cycle,"wildlife_cycle"),"a two-activity experience can be accepted")
	var watched := animal("deer",Vector2(1580,1700));watched.behavior="forage";watched.target_pos=watched.p
	var observer := Vector2(1580,1940)
	for i in range(40):cycle.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	check(cycle.encounter_status().current==0,"past animal activity cannot bypass the deliberate fresh observation gate")
	cycle.note_wildlife_observation("Reh",watched,observer,0,true)
	for i in range(30):cycle.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	check(cycle.encounter_status().current==1 and cycle.encounter_status().first_activity=="forage","three actual arrived feeding seconds record one distinct activity")
	for i in range(60):cycle.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	check(cycle.encounter_status().current==1,"more of the same activity cannot impersonate a second activity")
	watched.behavior="shelter";watched.mood="ruhen";watched.speed=28
	for i in range(30):cycle.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	check(cycle.encounter_status().activity_seconds==0,"a moving animal's decorative rest pose does not count as actual rest")
	watched.speed=0;watched.target_pos=watched.p+Vector2(150,0)
	for i in range(30):cycle.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	check(cycle.encounter_status().activity_seconds==0,"rest before actual arrival at the animal's target cannot count")
	watched.target_pos=watched.p
	var other := watched.duplicate(true);other.phase=2
	for i in range(30):cycle.tick_wildlife_observation(0.1,"Reh",other,observer,0,true)
	check(cycle.encounter_status().activity_seconds==0,"changing individuals cannot complete a two-activity experience")
	for i in range(15):cycle.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	check(cycle.save_to(save_path),"partial actual activity time saves")
	var loaded := WolfState.new()
	check(loaded.load_from(save_path) and loaded.encounter_status().first_activity=="forage" and is_equal_approx(loaded.encounter_status().activity_seconds,1.5) and loaded.encounter_status().watch_animal==WolfPackLife.animal_key(watched),"activity names, original identity and partial second activity survive restart")
	check(loaded.encounter_status().current_activity.is_empty(),"loading an animal experience does not claim the animal is still visibly resting")
	loaded.tick_wildlife_observation(0,"Reh",watched,observer,0,true)
	check(loaded.encounter_status().current_activity=="shelter","a fresh actual visible candidate restores its live activity without adding time")
	loaded.region=1
	check(loaded.encounter_status().current_activity.is_empty(),"a regionswitch immediately masks the old animal's visible activity")
	loaded.region=0;loaded.clear_encounter_presence()
	check(loaded.encounter_status().current_activity.is_empty() and is_equal_approx(loaded.encounter_status().activity_seconds,1.5),"a view reset clears the live activity while retaining actual observation progress")
	loaded.tick_wildlife_observation(5,"Reh",{},observer,0,true)
	check(is_equal_approx(loaded.encounter_status().activity_seconds,1.5),"looking away adds no activity duration")
	for i in range(15):loaded.tick_wildlife_observation(0.1,"Reh",watched,observer,0,true)
	check(loaded.encounter_status().done and loaded.complete_encounter(),"two different real calm activities of one individual fulfil its experience")
	check(choose_task(loaded,"wildlife_cycle") and loaded.encounter_status().current==0 and not loaded.encounter_status().watch_started,"a repeated animal-activity experience requires a fresh gate and fresh activity time")
	loaded.save_to(save_path)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	data.active_encounter.cycle_first=true;data.active_encounter.cycle_second=true;data.active_encounter.first_activity=[]
	var malformed := FileAccess.open(save_path,FileAccess.WRITE);malformed.store_string(JSON.stringify(data));malformed.close()
	check(loaded.load_from(save_path) and loaded.encounter_status().current==0,"malformed saved activity names cannot invent completed activities")
	restored.save_to(save_path);data=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	data.active_encounter.second_pos=[{},0]
	malformed=FileAccess.open(save_path,FileAccess.WRITE);malformed.store_string(JSON.stringify(data));malformed.close()
	check(restored.load_from(save_path) and restored.active_encounter.is_empty(),"a damaged required pack-stop coordinate discards only the impossible task")
	DirAccess.remove_absolute(save_path)

	WolfState.save_path="user://wolf-living-world-controller.json"
	for file in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(file):DirAccess.remove_absolute(file)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game);await process_frame
	if game.stick==null:
		check(false,"living-world controller initializes")
		game.set_process(false);game.queue_free();await process_frame;quit(1);return
	game.close_overlay();game.set_process(false)
	game.state=WolfState.new();at_hour(game.state,8);game.state.pos=Vector2(2800,2800);game.player_speed=0;game.clock=0
	var living := animal("deer",Vector2(1500,1600))
	game.world={"objects":[{"kind":"flowers","p":Vector2(2100,1600),"scale":1.0,"variant":0},{"kind":"bush","p":Vector2(1400,1600),"scale":1.0,"variant":0}],"animals":[living],"tracks":[],"decor":[]}
	game.collision_index.build(game.world.objects)
	check(advance_controller(game,36),"a long actual feeding walk and dwell remain obstruction-safe and bounded")
	check(living.behavior=="forage" and living.p.distance_to(Vector2(2100,1600))<12 and living.mood=="grasen","actual feeding is not interrupted by the former global thirty-five-second interval")
	check(advance_controller(game,5) and living.behavior=="shelter" and living.mood=="wandern","after a genuine meal the deer physically walks toward its cover")
	var seen_rest := false
	for i in range(700):
		advance_controller(game,0.05)
		if living.behavior=="shelter" and living.mood=="ruhen" and living.p.distance_to(living._ecology.shelter)<12:seen_rest=true
	check(seen_rest,"the real feeding-shelter cycle reaches cover and shows actual stationary rest")
	game.state=WolfState.new();game.state.pos=Vector2(1440,1600);game.player_speed=70;game.clock=0
	game.world={"objects":[],"animals":[animal("deer",Vector2(1600,1600)),animal("deer",Vector2(1830,1600),2),animal("fox",Vector2(1830,1600),4)],"tracks":[],"decor":[]}
	game.collision_index.build(game.world.objects);game._update_animals(0.05)
	check(game.world.animals[0].behavior=="flee" and game.world.animals[1].behavior=="flee" and game.world.animals[2].behavior!="flee","a nearby deer's actual fright alerts its loose group while the solitary fox keeps its own response")
	game.state.pos=Vector2(2800,2800);game.player_speed=0
	check(advance_controller(game,14) and game.world.animals.all(func(member: Dictionary):return member.get("alarm",0)==0 and member.behavior!="flee"),"group fright ends after the real threat instead of circulating forever between deer")
	game.state=WolfState.new();at_hour(game.state,10);game.state.pos=Vector2(2800,2800);game.clock=0
	var young_a := animal("wolf",Vector2(1415,2240),2.4);young_a.role="Geschwister";young_a.young=true
	var young_b := animal("wolf",Vector2(1460,2275),3.6);young_b.role="Geschwister";young_b.young=true
	game.world={"objects":[],"animals":[young_a,young_b],"tracks":[],"decor":[]};game.collision_index.build(game.world.objects)
	var played := false
	var paused := false
	var play_safe := true
	for i in range(900):
		if not advance_controller(game,0.05):play_safe=false
		if young_a.mood=="spielen" and young_a.speed>1:played=true
		if young_a.mood=="lauschen" and young_a.speed<1:paused=true
	check(play_safe and played and paused,"siblings take real short play runs and stationary listening pauses without teleporting")
	game.state=WolfState.new();game.state.region=1;game.state.escort=true;choose_task(game.state,"pack_walk")
	game.state.pos=game.state.active_encounter.first_pos;game.state.facing=Vector2.UP;game.clock=0
	var escort := animal("wolf",game.state.pos+Vector2(260,0));escort.role="Mutter";escort.young=false;escort.companion=true
	game.world={"objects":[],"animals":[escort],"tracks":[],"decor":[]};game.collision_index.build(game.world.objects)
	check(advance_controller(game,7) and game.state.encounter_status().current==1,"actual escort movement reaches the first pack stop before its joint timer completes")
	game.state.pos=game.state.active_encounter.second_pos
	game._update_animals(0.05)
	check(game.state.encounter_status().current==1 and not game.state.encounter_status().companion_ready,"a newly reached second stop waits for the genuinely distant companion")
	check(advance_controller(game,22) and game.state.encounter_status().done,"the escort actually walks the second route and then fulfils the joint second stop")
	game.set_process(false);game.sound.stream_paused=false;game.ambient.stream_paused=false
	await create_timer(0.2).timeout;game._release_audio();await create_timer(0.2).timeout
	root.remove_child(game);game.queue_free();await process_frame;await create_timer(0.15).timeout
	for file in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(file):DirAccess.remove_absolute(file)
	print("Wolf living world: %d failures"%failures)
	quit(1 if failures>0 else 0)
