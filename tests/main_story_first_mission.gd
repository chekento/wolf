extends SceneTree

var checks := 0
var failures := 0

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func _initialize() -> void:
	call_deferred("run")

func wait(state: WolfState,parent: Dictionary,seconds: float,clear: bool=true,speed: float=0) -> void:
	for index in range(ceili(seconds/.1)):state.tick_main_story(.1,parent,clear,speed)

func write_json(path: String,data: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data));file.close()

func run() -> void:
	var world := WolfWorldData.generate(0)
	var parent: Dictionary={}
	for animal in world.animals:
		if animal.kind=="wolf" and animal.get("role","")=="Mutter":parent=animal.duplicate(true);break
	var navigation := WolfAnimalMotion.new();navigation.configure(0,world.objects)
	var state := WolfState.new()
	state.pos=parent.p+Vector2(80,0)
	check(navigation.walkable(state.pos) and navigation.segment_free(parent.p,state.pos),"the actual native mother's greeting area is traversable with a real unobstructed connection")
	wait(state,parent,3)
	check(not state.main_story_status().started,"physical family presence before accepting the campaign does not fabricate a mission")
	check(state.begin_main_story() and not state.main_story_home_meeting_active(),"accepting the campaign still requires its real mother greeting first")
	check(state.note_main_story_action("greet","",parent) and state.main_story_status().stage==1,"greeting the actual native adult mother reaches the user's first-chapter one-of-two checkpoint")
	var first := state.main_story_status()
	check(first.home_meeting and not first.requires_escort and not state.escort,"the local family meeting uses actual presence instead of a hidden mandatory travel-escort flag")
	check(first.target_pos==Vector2(1580,2320) and navigation.walkable(first.target_pos),"guidance points to real dry ground in front of the south-facing cave entrance")
	check(navigation.segment_free(parent.p,first.target_pos),"the new front-of-cave target is directly reachable from the native mother's original nearby position")
	check(not navigation.segment_free(parent.p,Vector2(1692,2180)),"the old east-side guide really placed the cave wall between the mother and the player")
	check(first.player_in_zone and state.main_story_home_meeting_active(),"standing naturally beside the native mother at the cave is inside the legitimate local meeting area")
	check(not first.objective.contains("Begleitung"),"the first objective explains the real local meeting instead of requiring an unrelated menu switch")
	state.tick_main_story(INF,parent,true);state.tick_main_story(NAN,parent,true);state.tick_main_story(-1,parent,true)
	check(state.main_story_status().seconds==0,"non-finite or negative mission frame durations cannot fabricate family time")
	wait(state,parent,3,false)
	check(state.main_story_status().seconds==0 and not state.main_story_status().companion_ready,"a cave wall or another obstruction prevents false joint presence even without an escort requirement")
	wait(state,parent,3,true,2)
	check(state.main_story_status().seconds==0,"walking beside the mother does not impersonate three quiet shared seconds")
	var distant := parent.duplicate(true);distant.p=state.pos+Vector2(220,0)
	wait(state,distant,3)
	check(state.main_story_status().seconds==0,"the mother must actually arrive within the player's live family distance")
	var father := parent.duplicate(true);father.role="Vater"
	wait(state,father,3)
	check(state.main_story_status().seconds==0,"the father cannot replace the actual mother for this specific opening scene")
	var young := parent.duplicate(true);young.young=true
	wait(state,young,3)
	check(state.main_story_status().seconds==0,"a young wolf cannot satisfy the adult mother requirement")
	var moving := parent.duplicate(true);moving.speed=28
	wait(state,moving,3)
	check(state.main_story_status().seconds==0,"a mother walking past the player cannot be credited as a calm shared stop")
	var original_pos := state.pos
	state.pos=Vector2(2100,2180)
	var remote := parent.duplicate(true);remote.p=state.pos+Vector2(70,0)
	wait(state,remote,3)
	check(state.main_story_status().seconds==0 and not state.main_story_home_meeting_active(),"real proximity elsewhere in the forest cannot replace actually returning to the family cave")
	state.pos=original_pos;state.region=1
	wait(state,parent,3)
	check(state.main_story_status().seconds==0 and not state.main_story_home_meeting_active(),"the accepted home meeting cannot advance in another region")
	state.region=0
	state.tick_main_story(100,parent,true)
	check(is_equal_approx(state.main_story_status().seconds,.1),"a stalled active frame still contributes only a tenth of one real second")
	check(state.main_story_status().player_ready and state.main_story_status().companion_ready and not state.escort,"live HUD readiness agrees with a genuinely quiet nearby mother without enabling travel escort")
	wait(state,parent,1)
	check(is_equal_approx(state.main_story_status().seconds,1.1) and not state.main_story_status().ready,"partial real family time remains partial instead of auto-completing the chapter")
	state.clear_encounter_presence()
	check(is_equal_approx(state.main_story_status().seconds,1.1) and not state.main_story_status().player_ready and not state.main_story_status().companion_ready,"view and foreground resets preserve earned duration while discarding old live presence")
	var path := "user://first-mission-state.json"
	check(state.save_to(path),"the first-chapter one-of-two checkpoint saves normally")
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(raw.version==4 and raw.main_story.stage==1 and not raw.escort and not raw.main_story.has("meeting_center") and not raw.main_story.has("companion_ready"),"the fix adds no save-version change, target coordinates, live flags, or automatic escort mutation")
	for version in [1,2,3,4]:
		var legacy := raw.duplicate(true)
		legacy.version=version
		legacy.pos=[1692.0/2,2180.0/2] if version==1 else [1692,2180]
		write_json(path,legacy)
		var loaded := WolfState.new()
		check(loaded.load_from(path) and loaded.main_story_status().chapter==0 and loaded.main_story_status().stage==1 and is_equal_approx(loaded.main_story_status().seconds,1.1),"save version %d preserves the already-earned first greeting and partial family time"%version)
		check(loaded.pos==Vector2(1692,2180) and loaded.main_story_status().player_in_zone and loaded.main_story_status().target_pos==Vector2(1580,2320) and not loaded.escort,"save version %d retains the old east-side player position inside the legitimate cave area with corrected guidance"%version)
		check(not loaded.main_story_status().companion_ready and not loaded.main_story_status().ready,"save version %d never restores an invented mother arrival or completed chapter"%version)
		loaded.tick_main_story(.1,parent,false)
		check(is_equal_approx(loaded.main_story_status().seconds,1.1),"save version %d keeps earned progress while the mother still has to walk around the actual cave wall"%version)
		var arrived := parent.duplicate(true);arrived.p=loaded.pos+Vector2(0,100);arrived.speed=0
		check(navigation.segment_free(arrived.p,loaded.pos),"save version %d can have a real nearby reachable mother after her detour"%version)
		wait(loaded,arrived,1.9)
		check(loaded.main_story_status().ready and not loaded.escort,"save version %d finishes only after the remaining real quiet seconds with the arrived mother"%version)
		var earned := loaded.xp;var age := loaded.age_weeks();var elapsed := loaded.elapsed
		check(loaded.advance_main_story() and loaded.main_story_status().chapter==1 and loaded.xp==earned+40,"save version %d explicitly remembers the genuinely completed chapter and awards it once"%version)
		check(not loaded.advance_main_story() and loaded.xp==earned+40 and loaded.age_weeks()==age and loaded.elapsed==elapsed,"save version %d cannot duplicate rewards or skip natural aging and world time"%version)
		check(not loaded.main_story_home_meeting_active() and loaded.main_story_status().requires_escort,"save version %d restores the ordinary escort requirement for the later actual water journey"%version)
		loaded.pos=loaded.main_story_status().target_pos
		var water_parent := parent.duplicate(true);water_parent.p=loaded.pos+Vector2(80,0)
		wait(loaded,water_parent,3)
		check(loaded.main_story_status().seconds==0 and loaded.main_story_status().stage==0,"save version %d cannot use the local-home exception to bypass a later escort journey"%version)
	check(state.story_scenes().size()==18 and WolfMainStory.chapters().size()==8 and state.story_step==0,"the targeted fix leaves all eight campaign chapters and eighteen older memories in place")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("First mission state: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
