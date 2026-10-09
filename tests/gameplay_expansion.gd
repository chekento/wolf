extends SceneTree

var failures := 0

func check(value: bool,message: String) -> void:
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func _initialize() -> void:
	call_deferred("run")

func choose_task(state: WolfState,task: String) -> bool:
	for serial in range(18):
		state.encounter_serial=serial
		state.encounter_preview_key=""
		if state.encounter_status().task==task:return state.begin_encounter()
	return false

func destinations_reachable(region: int,data: Dictionary) -> bool:
	# A conservative 50-unit navigation grid checks actual routes, including
	# all three river crossings, rather than merely checking endpoint clearance.
	var navigation := AStarGrid2D.new()
	navigation.region=Rect2i(0,0,64,64)
	navigation.cell_size=Vector2(50,50)
	navigation.offset=Vector2(25,25)
	navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in range(64):
		for x in range(64):
			var point := Vector2(x*50+25,y*50+25)
			if WolfWorldData.water_blocked(point,region):navigation.set_point_solid(Vector2i(x,y))
	for obj in data.objects:
		var radius: float=WolfWorldData.solid_radius(obj)+13
		if radius<=13:continue
		var center: Vector2i=Vector2i(obj.p/50)
		var cells := int(ceil(radius/50))+1
		for y in range(maxi(0,center.y-cells),mini(64,center.y+cells+1)):
			for x in range(maxi(0,center.x-cells),mini(64,center.x+cells+1)):
				if Vector2(x*50+25,y*50+25).distance_to(obj.p)<radius:navigation.set_point_solid(Vector2i(x,y))
	var start: Vector2i=Vector2i(WolfWorldData.SPAWN/50)
	if navigation.is_point_solid(start):return false
	var destinations: Array[Vector2]=[WolfWorldData.water_bank(region)]
	for object in data.objects:
		if object.kind in ["discovery","food","landmark"]:destinations.append(object.p)
		if object.kind=="den":destinations.append(object.p+Vector2(112,0))
	for track in data.tracks:destinations.append(track.p)
	for point in destinations:
		var target: Vector2i=Vector2i(point/50)
		var reached := false
		# A small den or a footprint can sit between grid centers. Connect
		# its exact free endpoint to a reachable adjacent grid center, checking
		# the whole short segment against the game's actual solid radii.
		for y in range(maxi(0,target.y-1),mini(64,target.y+2)):
			for x in range(maxi(0,target.x-1),mini(64,target.x+2)):
				var cell := Vector2i(x,y)
				if navigation.is_point_solid(cell) or navigation.get_id_path(start,cell).is_empty():continue
				var endpoint := Vector2(x*50+25,y*50+25)
				var clear := true
				for step in range(11):
					var sample := endpoint.lerp(point,float(step)/10)
					if not WolfWorldData.walkable(sample,data.objects) or WolfWorldData.water_blocked(sample,region):clear=false;break
				if clear:reached=true;break
			if reached:break
		if not reached:print("NO APPROACH ",region," ",point);return false
	return true

func run() -> void:
	check(WolfWorldData.GRID_SIZE==16 and WolfWorldData.REGIONS.size()==256,"world expands to a 16 by 16 registry")
	for i in range(16):
		check(WolfWorldData.REGIONS[i].name==WolfWorldData.REGION_INFO[i][0] and WolfWorldData.REGIONS[i].coord==WolfWorldData.REGION_INFO[i][3]+Vector2i(6,6),"original region identity and geometry %d"%i)
	check(WolfWorldData.REGIONS[16].name=="Nordkap" and WolfWorldData.REGIONS[63].name=="Südhorizont","all 0.3 generated region IDs remain in place")
	var reached: Array[int]=[0]
	var frontier: Array[int]=[0]
	while not frontier.is_empty():
		var current: int=frontier.pop_front()
		for target in WolfWorldData.REGIONS[current].links.values():
			if not reached.has(int(target)):reached.append(int(target));frontier.append(int(target))
	check(reached.size()==256,"all 256 regions connect through ordinary exits")
	var directed_links := 0
	var sites_safe := true
	var routes_open := true
	var entries_safe := true
	var resources_safe := true
	var species_valid := true
	var nature_count := 0
	var seen_coords := {}
	for index in range(256):
		var info: Dictionary=WolfWorldData.REGIONS[index]
		if seen_coords.has(info.coord):check(false,"duplicate map coordinate")
		seen_coords[info.coord]=true
		var data: Dictionary=WolfWorldData.generate(index)
		if not destinations_reachable(index,data):routes_open=false;print("NO DESTINATION ROUTE ",index)
		if index<64:check(info.seed==41+index*43,"old deterministic region seed %d"%index)
		for direction in info.links:
			directed_links+=1
			var target: int=info.links[direction]
			var opposite: String={"north":"south","south":"north","east":"west","west":"east"}[direction]
			if int(WolfWorldData.REGIONS[target].links.get(opposite,-1))!=index:entries_safe=false
			var border_point: Vector2=WolfWorldData.entry_point(opposite)
			if not WolfWorldData.walkable(border_point,data.objects) or WolfWorldData.water_blocked(border_point,index):entries_safe=false
		var bank: Vector2=WolfWorldData.water_bank(index)
		var bank_valid := WolfWorldData.walkable(bank,data.objects) and not WolfWorldData.water_blocked(bank,index)
		var drink_valid := absf(bank.x-WolfWorldData.river_x(bank.y))<155 if info.biome=="river" else bank.distance_to(Vector2(2220,2140))<190*(1.65 if info.biome=="lake" else 1.2)+90
		if not bank_valid or not drink_valid:resources_safe=false;print("BAD DRINKING GUIDE ",index)
		var food_count := 0
		var den_count := 0
		var water_count := 0
		for obj in data.objects:
			if obj.kind=="discovery":
				nature_count+=1
				if not WolfWorldData.walkable(obj.p,data.objects) or WolfWorldData.water_blocked(obj.p,index):sites_safe=false;print("BAD SITE ",index," ",obj.p)
			if obj.kind=="food":
				food_count+=1
				if not WolfWorldData.walkable(obj.p,data.objects) or WolfWorldData.water_blocked(obj.p,index):resources_safe=false;print("BAD FOOD ",index," ",obj.p)
			if obj.kind=="den":
				den_count+=1
				var edge: Vector2=obj.p+Vector2(112,0)
				if not WolfWorldData.walkable(edge,data.objects) or WolfWorldData.water_blocked(edge,index):resources_safe=false;print("BAD DEN ",index," ",edge)
			if obj.kind=="water":water_count+=1
		if food_count!=3 or den_count!=2 or water_count!=1:resources_safe=false
		for animal in data.animals:
			if not WolfWorldData.walkable(animal.p,data.objects) or WolfWorldData.water_blocked(animal.p,index):species_valid=false
	check(seen_coords.size()==256 and directed_links==960,"complete grid has unique coordinates and reciprocal links")
	check(entries_safe,"every regional entrance remains water-safe and unblocked")
	check(sites_safe and nature_count==1536,"all 1,536 distinct nature sites stand on reachable dry ground")
	check(resources_safe,"every region provides accessible food, water and two rest places")
	check(routes_open,"all discoveries, food, rest places, water banks and clues have navigable regional routes")
	check(species_valid,"all wildlife homes start on dry walkable ground")
	check(WolfWorldData.nature_sites(0)[3].p!=WolfWorldData.nature_sites(1)[3].p,"additional nature sites vary deterministically by region")
	check(WolfWorldData.generate(174)==WolfWorldData.generate(174),"expanded regional content remains deterministic")
	check(not WolfState.new().camera_follow and WolfState.new().smooth_edges,"default presentation preserves wolf view and smooth edges")
	var quest_state := WolfState.new()
	var ids: Array[String]=[]
	var quests_valid := true
	for quest in quest_state.quests():
		if ids.has(quest.id) or not quest.progress is String or not quest.done is bool:quests_valid=false
		ids.append(quest.id)
	check(quests_valid and ids.size()==42,"forty-two playable quests expose unique IDs and valid progress")
	var routine := WolfState.new()
	check(routine.pack_routine().target is Vector2 and routine.pack_routine().speed is float,"pack routines expose local target positions and movement speeds")
	check(WolfPackLife.routine(14,"Mutter").mood=="ruhen" and WolfPackLife.routine(9,"Geschwister").mood=="spielen","pack activity changes between midday rest and young-wolf play")
	check(routine.season_name()=="Frühjahr","new life starts in spring")
	routine.tick(WolfState.DAY_SECONDS*29,false,false)
	check(routine.season_name()=="Frühjahr" and routine.age_weeks()==20,"season and body age advance without abrupt skips")
	routine.tick(WolfState.DAY_SECONDS,false,false)
	check(routine.season_name()=="Sommer" and is_equal_approx(routine.season_progress(),0),"a season changes only after thirty active days")
	var tracks := WolfState.new()
	tracks.found.assign(["0:0","0:1","0:2"])
	check(choose_task(tracks,"tracks") and not tracks.encounter_status().done,"previous tracks cannot complete a newly accepted encounter")
	check(not tracks.begin_encounter(),"only one encounter can be accepted at a time")
	tracks.found.append_array(["0:3","0:4","0:5"])
	check(tracks.encounter_status().done and tracks.complete_encounter(),"three new regional clues complete a track encounter")
	var rewarded_xp: int=tracks.xp
	check(not tracks.complete_encounter() and tracks.xp==rewarded_xp and tracks.completed_encounters.size()==1,"a completed experience awards its reward exactly once")
	var player_games := WolfState.new()
	check(player_games.action_counts.play == 0 and int(player_games.action_counts.play) == 0,"new pack play quest begins unearned")
	for i in range(3):player_games.note_action("play")
	check(player_games.action_counts.play == 3 and player_games.pack_signal.action == "play" and player_games.pack_signal.serial == 3,"pack play invitations are distinct real signals and count persistently")
	var games_earned := false
	for quest in player_games.quests():
		if quest.id == "play3":games_earned = quest.done and quest.progress == "3/3"
	check(games_earned,"three deliberate pack games finish a finite new quest")
	var observer := WolfState.new()
	observer.note_action("observe","Reh")
	check(choose_task(observer,"observe") and not observer.encounter_status().done,"old observations do not fulfil a new wildlife experience")
	observer.note_action("observe",str(observer.active_encounter.detail))
	check(observer.encounter_status().done and observer.complete_encounter(),"a fresh actual species observation fulfils its task")
	var water := WolfState.new()
	water.note_action("drink");water.note_action("rest")
	check(choose_task(water,"water_rest") and not water.encounter_status().done,"old drinks and rest cannot fulfil a new water task")
	water.note_action("rest")
	check(not water.encounter_status().done,"resting before drinking does not satisfy the ordered task")
	water.note_action("drink")
	water.region=1;water.note_action("rest")
	check(not water.encounter_status().done,"a rest in another region does not satisfy the chosen waterside experience")
	water.region=0;water.note_action("rest")
	check(water.encounter_status().done and water.complete_encounter(),"fresh drinking followed by local protected rest completes the task")
	var family := WolfState.new()
	family.note_action("greet");family.note_action("howl")
	check(choose_task(family,"family") and not family.encounter_status().done,"an old pack greeting or howl cannot fulfil a new encounter")
	family.region=1;family.note_action("greet");family.note_action("howl")
	check(not family.encounter_status().done,"a distant howl does not count as a response near the family den")
	family.region=0;family.pos=Vector2(1490,2100);family.note_action("greet")
	var family_status: Dictionary=family.encounter_status()
	check(family_status.target_region==0 and family_status.target_pos==Vector2(1580,2025) and family_status.target_pos.distance_to(Vector2(1600,2240))<460 and WolfWorldData.walkable(family_status.target_pos,WolfWorldData.generate(0).objects),"after greeting the family guide targets safe home den proximity for a howl")
	family.note_action("howl")
	check(family.encounter_status().done and family.complete_encounter(),"a new home greeting and a local howl complete the pack experience")
	var visit := WolfState.new()
	check(choose_task(visit,"visit") and not visit.encounter_status().done,"exploration selects a genuinely unvisited neighbor")
	var selected_region: int=visit.active_encounter.target_region
	check(WolfWorldData.REGIONS[0].links.values().has(selected_region),"new exploration objective is reachable through a direct ordinary exit")
	visit.visited.append(selected_region)
	check(visit.encounter_status().done and visit.complete_encounter(),"entering the chosen neighbor completes its exploration objective")
	var exhausted := WolfState.new()
	for i in range(27):exhausted.found.append("0:%d"%i)
	for i in range(6):exhausted.sites.append("0:%d"%i)
	for neighbor in WolfWorldData.REGIONS[0].links.values():exhausted.visited.append(int(neighbor))
	var impossible_tasks := false
	for serial in range(18):
		exhausted.encounter_serial=serial;exhausted.encounter_preview_key=""
		if exhausted.encounter_status().task in ["tracks","sites","visit"]:impossible_tasks=true
	check(not impossible_tasks,"fully explored regions offer new achievable tasks rather than exhausted clues")
	var continuation := WolfState.new()
	check(continuation.story_scenes().size()==18,"eighteen natural story chapters remain gated by actual experience")
	continuation.story_step=9
	check(not continuation.choose_story(0),"continuation cannot skip its first encounter gate")
	continuation.completed_encounters.append("1:0:0")
	check(continuation.choose_story(0) and continuation.story_step==10,"an actual completed encounter opens the next story chapter")
	var save := WolfState.new()
	check(choose_task(save,"water_rest"),"pending task prepared for persistence")
	save.note_action("drink")
	save.region=220;save.visited.append(220);save.encounter_serial=29
	save.routine_seen.append("Ruhe in der Deckung")
	save.camera_follow=true;save.smooth_edges=false
	var path := "user://wolf-expansion-test.json"
	check(save.save_to(path),"version four progress saves successfully")
	var restored := WolfState.new()
	check(restored.load_from(path),"version four progress loads successfully")
	check(restored.region==220 and restored.visited.has(220) and restored.action_counts.drink==1 and restored.encounter_serial==29,"expanded progress and true action counters survive restart")
	check(restored.camera_follow and not restored.smooth_edges,"camera follow and smooth edge choices survive a version four save")
	check(restored.active_encounter.target_pos is Vector2 and restored.active_encounter.get("drank_after_start",false) and restored.encounter_status().current==1,"accepted task position, baseline and ordered progress survive restart")
	check(not FileAccess.file_exists(path+".pending"),"atomic saves do not leave a pending file after success")
	restored.energy=65
	check(restored.save_to(path) and save.load_from(path) and save.energy==65,"an existing valid save is atomically replaced and readable")
	DirAccess.remove_absolute(path)
	var legacy := FileAccess.open(path,FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"version":3,"region":63,"pos":[1200,1500],"visited":[0,63],"story_step":9,"sites":["63:2"]}))
	legacy.close()
	var migrated := WolfState.new()
	migrated.camera_follow=true;migrated.smooth_edges=false
	migrated.skills.nose=100;migrated.action_counts.drink=99
	migrated.encounter_preview_key="stale";migrated.encounter_preview={"task":"visit"}
	check(migrated.load_from(path) and migrated.region==63 and migrated.pos==Vector2(1200,1500) and migrated.sites.has("63:2") and migrated.story_step==9,"0.3 saves retain all existing region IDs and story progress")
	check(not migrated.camera_follow and migrated.smooth_edges,"old saves restore presentation defaults even when loaded into a reused state")
	check(migrated.skills.nose==0 and migrated.action_counts.drink==0 and migrated.encounter_preview.is_empty() and migrated.encounter_preview_key.is_empty(),"loading an older save clears stale skills, counters and encounter hints")
	DirAccess.remove_absolute(path)
	var malformed := FileAccess.open(path,FileAccess.WRITE)
	malformed.store_string(JSON.stringify({"version":1,"region":0,"pos":[10000,10000],"found":["0:1","0:1","999:1","broken"],"sites":["0:0","0:0","0:9"],"observations":["Reh","fantasy"]}))
	malformed.close()
	var bounded := WolfState.new()
	check(bounded.load_from(path) and bounded.pos==Vector2(3180,3180) and bounded.found.size()==1 and bounded.sites.size()==1 and bounded.observations==["Reh"],"legacy out-of-bounds positions and duplicate or malformed progress are sanitized")
	DirAccess.remove_absolute(path)
	var corrupt := FileAccess.open(path,FileAccess.WRITE)
	corrupt.store_string(JSON.stringify({"version":4,"region":9999,"pos":[100,100],"active_encounter":{"task":"family"}}))
	corrupt.close()
	var safe := WolfState.new()
	check(safe.load_from(path) and safe.region==255 and safe.active_encounter.is_empty(),"invalid stored region bounds and incomplete pending task are handled safely")
	DirAccess.remove_absolute(path)
	var invalid_position := FileAccess.open(path,FileAccess.WRITE)
	invalid_position.store_string(JSON.stringify({"version":4,"region":0,"pos":[{},100]}))
	invalid_position.close()
	var unmodified := WolfState.new()
	unmodified.energy=65
	check(not unmodified.load_from(path) and unmodified.energy==65,"invalid position components reject a save without changing the running life")
	DirAccess.remove_absolute(path)
	var invalid_numbers := FileAccess.open(path,FileAccess.WRITE)
	invalid_numbers.store_string(JSON.stringify({"version":4,"region":{},"pos":[100,100],"facing":[0,0],"skills":{"nose":{}},"action_counts":{"drink":[]},"elapsed":{},"visited":[0,{}]}))
	invalid_numbers.close()
	var sanitized := WolfState.new()
	check(sanitized.load_from(path) and sanitized.region==0 and sanitized.elapsed==0 and sanitized.facing==Vector2.UP and sanitized.skills.nose==0 and sanitized.action_counts.drink==0 and sanitized.visited==[0],"malformed optional numbers do not corrupt movement or progress")
	DirAccess.remove_absolute(path)
	var serials := FileAccess.open(path,FileAccess.WRITE)
	serials.store_string(JSON.stringify({"version":4,"region":0,"pos":[100,100],"completed_encounters":["1:0:29"],"encounter_serial":0}))
	serials.close()
	var unique := WolfState.new()
	check(unique.load_from(path) and unique.encounter_serial==30,"loaded encounter serial cannot reuse a previously rewarded ID")
	DirAccess.remove_absolute(path)
	var active := WolfState.new()
	check(choose_task(active,"observe"),"an observation prepared for corrupt task recovery")
	check(active.save_to(path),"observation save written for validation")
	var task_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	task_data.active_encounter.detail="unknown"
	var invalid_task := FileAccess.open(path,FileAccess.WRITE)
	invalid_task.store_string(JSON.stringify(task_data));invalid_task.close()
	check(sanitized.load_from(path) and sanitized.active_encounter.is_empty(),"an unsupported saved wildlife objective is discarded instead of becoming impossible")
	DirAccess.remove_absolute(path)
	print("Wolf gameplay expansion: %d failures"%failures)
	quit(1 if failures>0 else 0)
