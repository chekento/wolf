extends SceneTree

var errors := 0

func check(value: bool,message: String) -> void:
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);errors+=1

func _initialize() -> void:
	call_deferred("run")

func animal(point: Vector2,companion: bool=false) -> Dictionary:
	return {"kind":"wolf","p":point,"home":point,"phase":0.0,"facing":Vector2.RIGHT,"mood":"lauschen","speed":0.0,"gait":0.0,"role":"Mutter","young":false,"companion":companion}

func simulate(motion: WolfAnimalMotion,member: Dictionary,target: Vector2,ticks: int,speed: float=140) -> Dictionary:
	var safe := true
	var bounded := true
	var crossed_bridge := false
	var highest_offset := 0.0
	for i in range(ticks):
		var before: Vector2=member.p
		member.p=motion.advance(member,target,speed,0.035,float(i)*0.035)
		if not motion.walkable(member.p) or not motion.segment_free(before,member.p):safe=false
		if before.distance_to(member.p)>speed*0.035+0.001:bounded=false
		highest_offset=maxf(highest_offset,absf(member.p.y-target.y))
		if absf(member.p.x-WolfWorldData.river_x(member.p.y))<78:crossed_bridge=true
	return {"safe":safe,"bounded":bounded,"offset":highest_offset,"crossed_bridge":crossed_bridge}

func run() -> void:
	var motion := WolfAnimalMotion.new()
	motion.configure(0,[{"kind":"rock","p":Vector2(1500,1600),"scale":4.0,"variant":0}])
	var member := animal(Vector2(1260,1600))
	var started := Time.get_ticks_msec()
	var result := simulate(motion,member,Vector2(1780,1600),260)
	print("Navigation obstacle scenario: %d ms"%(Time.get_ticks_msec()-started))
	check(result.safe and result.bounded,"animal movement sweeps obstacles and never teleports through a boulder")
	check(member.p.distance_to(Vector2(1780,1600))<8 and result.offset>135,"an animal actually walks around a large obstacle to its goal")
	var local := WolfAnimalMotion.new();local.configure(0,[{"kind":"tree","p":Vector2(1360,1600),"scale":1.3,"variant":0}])
	var small := animal(Vector2(1260,1600))
	var local_safe := true
	for i in range(300):
		var before: Vector2=small.p
		small.p=local.advance(small,Vector2(1420,1600),50,0.035,float(i)*0.035,false)
		if not local.segment_free(before,small.p):local_safe=false
	check(local_safe and local.navigation==null,"small wildlife detours stay safe without constructing a regional navigation network")
	var river := WolfAnimalMotion.new();river.configure(2,[])
	var river_member := animal(Vector2(740,1120))
	var river_result := simulate(river,river_member,Vector2(1280,1120),480)
	check(river_result.safe and river_result.bounded,"animals respect deep river water along every movement segment")
	check(river_result.crossed_bridge and river_member.p.distance_to(Vector2(1280,1120))<8,"river detours use a genuine existing bridge opening")
	var blocked := WolfAnimalMotion.new();blocked.configure(0,[{"kind":"rock","p":Vector2(1600,1600),"scale":8.0,"variant":0}])
	var free := blocked.nearest_free(Vector2(1600,1600))
	check(free.is_finite() and blocked.walkable(free) and free.distance_to(Vector2(1600,1600))<=360,"blocked destination resolves to nearby actual free ground")
	var pref := WolfState.new()
	check(pref.compact_hud,"new games use a compact HUD")
	var path := "user://wolf-animal-behavior.json"
	pref.compact_hud=false
	check(pref.save_to(path),"expanded HUD preference saves")
	var restored := WolfState.new()
	check(restored.load_from(path) and not restored.compact_hud,"expanded HUD preference survives restart")
	DirAccess.remove_absolute(path)
	var legacy := FileAccess.open(path,FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"version":3,"region":0,"pos":[1580,1940]}));legacy.close()
	restored.compact_hud=false
	check(restored.load_from(path) and restored.compact_hud,"old saves load the compact default without changing progress")
	DirAccess.remove_absolute(path)
	check(WolfPackLife.wildlife_routine("fox",2,3).rest==false and WolfPackLife.wildlife_routine("fox",13,3).rest,"foxes investigate at night and rest during the day")
	check(WolfPackLife.wildlife_routine("rabbit",8,3).rest==false and WolfPackLife.wildlife_routine("rabbit",13,3).rest,"hares alternate morning foraging and midday shelter")
	WolfState.save_path="user://wolf-animal-controller.json"
	for file in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(file):DirAccess.remove_absolute(file)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if game.stick==null:
		check(false,"game initializes before animal controller tests")
		game.set_process(false);game.queue_free()
		await process_frame
		quit(1)
		return
	game.close_overlay();game.set_process(false)
	game.state=WolfState.new();game.state.escort=true
	game.state.pos=Vector2(1780,1600);game.state.facing=Vector2.RIGHT
	game.world={"objects":[{"kind":"rock","p":Vector2(1500,1600),"scale":4.0,"variant":0}],"animals":[animal(Vector2(1260,1600),true)],"tracks":[],"decor":[]}
	game.collision_index.build(game.world.objects)
	var follow_safe := true
	var follow_bounded := true
	for i in range(330):
		var before: Vector2=game.world.animals[0].p
		game.clock+=0.035
		game._update_animals(0.035)
		var after: Vector2=game.world.animals[0].p
		if not game.can_walk(after):follow_safe=false
		if before.distance_to(after)>220*0.035+0.001:follow_bounded=false
	check(follow_safe and follow_bounded and game.world.animals[0].p.distance_to(game.state.pos)<135,"actual parent controller detours around a boulder and reunites without a catch-up teleport")
	game.state.pos=Vector2(1560,1600)
	game.world={"objects":[{"kind":"rock","p":Vector2(1500,1600),"scale":1.4,"variant":0}],"animals":[animal(Vector2(1440,1600),true)],"tracks":[],"decor":[]}
	game.collision_index.build(game.world.objects)
	for i in range(160):game.clock+=0.035;game._update_animals(0.035)
	var occluded: Dictionary=game.world.animals[0]
	var occluded_navigation: WolfAnimalMotion=game.world._animal_motion
	check(occluded.p.distance_to(Vector2(1440,1600))>30 and occluded_navigation.segment_free(occluded.p,game.state.pos),"a nearby parent across a rock keeps detouring until the pup is actually reachable")
	game.state.escort=false;game.state.bond=100
	game.state.elapsed=(23.0-7.5)/24.0*WolfState.DAY_SECONDS
	game.state.pos=Vector2(2600,2600)
	game.world={"objects":[{"kind":"rock","p":Vector2(1620,2440),"scale":2.0,"variant":0}],"animals":[animal(Vector2(1770,2480))],"tracks":[],"decor":[]}
	game.collision_index.build(game.world.objects)
	var original: Vector2=game.world.animals[0].p
	var night_target: Vector2=game.state.pack_routine().target
	game.clock+=0.035;game._update_animals(0.035)
	check(game.world.animals[0].p.distance_to(original)>0 and game.world.animals[0].mood=="wandern","at night the family walks toward its protected rest place before lying down")
	for i in range(1200):game.clock+=0.035;game._update_animals(0.035)
	check(game.world.animals[0].p.distance_to(night_target)<18 and game.world.animals[0].mood=="ruhen" and game.world.animals[0].speed==0,"the family returns to its home routine instead of freezing at an arbitrary night position")
	game.state=WolfState.new();game.state.region=2;game.state.escort=true
	game.state.pos=Vector2(1600,3145);game.state.facing=Vector2.UP
	game.world=WolfWorldData.generate(2);game.collision_index.build(game.world.objects)
	game._sync_companion()
	var companions: Array=game.world.animals.filter(func(a:Dictionary):return a.get("companion",false))
	check(companions.size()==1 and game.can_walk(companions[0].p) and companions[0].p.y<=3180,"a northward region arrival creates one companion on valid nearby ground inside the boundary")
	var entry_navigation: WolfAnimalMotion=game.world._animal_motion
	check(companions.size()==1 and entry_navigation.body_step_free(companions[0].p,companions[0].p,companions[0],WolfPackInteractions.cohort(game.world.animals),game.state.pos,40.0*game.state.growth()),"the first region-entry frame leaves the pup and mother's real bodies separate")
	game._sync_companion()
	check(game.world.animals.filter(func(a:Dictionary):return a.get("companion",false)).size()==1,"companion synchronization never duplicates a parent")
	game.state.elapsed=WolfState.DAY_SECONDS*100
	game._sync_companion()
	companions=game.world.animals.filter(func(a:Dictionary):return a.get("companion",false))
	check(companions.size()==1 and entry_navigation.body_step_free(companions[0].p,companions[0].p,companions[0],WolfPackInteractions.cohort(game.world.animals),game.state.pos,40.0*game.state.growth()),"a grown wolf also enters with a nearby mother on free ground and no torso overlap")
	game.set_process(false)
	game.sound.stream_paused=false;game.ambient.stream_paused=false
	await create_timer(0.2).timeout
	game._release_audio()
	await create_timer(0.2).timeout
	root.remove_child(game);game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	for file in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(file):DirAccess.remove_absolute(file)
	print("Wolf animal behavior suite: %d failures"%errors)
	quit(1 if errors>0 else 0)
