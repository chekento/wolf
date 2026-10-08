extends SceneTree

var failures := 0
var checks := 0

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func _initialize() -> void:
	call_deferred("run")

func mother(state: WolfState,offset: Vector2=Vector2(80,0)) -> Dictionary:
	return {"kind":"wolf","role":"Mutter","young":false,"companion":state.region!=0,"p":state.pos+offset,"home":state.pos+offset,"speed":0.0}

func deer() -> Dictionary:
	var animal: Dictionary=WolfWorldData.generate(3).animals[0].duplicate(true)
	animal.speed=0.0;animal.mood="grasen";animal.behavior="forage";animal.alarm=0.0;animal.attention=0.0
	return animal

func wait(state: WolfState,seconds: float,parent: Dictionary,clear: bool=true,speed: float=0,animal: Dictionary={},view: bool=true,quiet: bool=true,mood: String="lauschen") -> void:
	for i in range(ceili(seconds/0.1)):state.tick_main_story(0.1,parent,clear,speed,animal,view,quiet,mood)

func fulfill(state: WolfState) -> bool:
	var before := state.main_story_status()
	if before.ready or before.done:return false
	state.region=int(before.target_region);state.pos=before.target_pos;state.escort=true
	match str(before.action):
		"greet":state.note_main_story_action("greet","",mother(state))
		"joint":wait(state,float(before.seconds_required),mother(state))
		"watch":
			var animal := deer()
			state.pos=animal.p+Vector2(0,230)
			state.note_main_story_observation(animal,0,true,true)
			wait(state,float(before.seconds_required),{},false,0,animal)
		"rest_wait":wait(state,float(before.seconds_required),mother(state),true,0,{},false,false,"ruhen")
		"track":state.note_main_story_action("track",str(before.track_id))
		"site":state.note_action("site",str(before.site_id))
		_:state.note_action(str(before.action))
	return int(state.main_story_status().stage)==int(before.stage)+1

func reach(state: WolfState,chapter: int) -> bool:
	if not state.main_story_status().started:state.begin_main_story()
	while int(state.main_story_status().chapter)<chapter:
		while not state.main_story_status().ready:
			if not fulfill(state):return false
		if not state.advance_main_story():return false
	return true

func write_json(path: String,value: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value));file.close()

func checkpoint(state: WolfState,path: String) -> Dictionary:
	state.save_to(path)
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func run() -> void:
	var classic := WolfState.new()
	classic.story_step=18;classic.drank=true;classic.rested=true;classic.howled=true;classic.pack_contacts=50
	classic.observations.assign(["Reh","Hase","Fuchs"])
	classic.action_counts.drink=100;classic.action_counts.greet=100;classic.action_counts.rest=100
	for region in range(256):classic.visited.append(region)
	for site in WolfWorldData.nature_sites(0):classic.sites.append(site.site)
	check(not classic.main_story_status().started and classic.main_story_status().current==0,"old achievements and eighteen optional chapters cannot start or pre-complete the new main story")
	classic.note_action("drink");classic.note_action("howl");classic.tick_main_story(100,mother(classic),true)
	check(not classic.main_story_status().started and not classic.main_story_status().ready,"ordinary actions before accepting the main story are not retroactive mission credit")
	check(classic.begin_main_story() and classic.main_story_status().chapter==0 and classic.main_story_status().stage==0,"accepting the new campaign starts the actual first greeting")
	check(not classic.begin_main_story() and classic.story_step==18,"accepting twice cannot erase campaign progress or existing optional stories")
	check(classic.main_story_status().chapters_count==8 and WolfMainStory.chapters().size()==8,"the connected main story has eight distinct chapters")
	var total_steps := 0
	var targets_safe := true
	var canonical_ids := true
	for chapter in WolfMainStory.chapters():
		for goal in chapter.stages:
			total_steps+=1
			var world := WolfWorldData.generate(int(goal.region))
			if goal.action!="watch" and (not WolfWorldData.walkable(goal.p,world.objects) or WolfWorldData.water_blocked(goal.p,int(goal.region))):targets_safe=false
			if goal.action=="track":
				var actual: Dictionary=world.tracks[int(str(goal.track_id).split(":")[1])]
				if actual.id!=goal.track_id or actual.p.distance_to(goal.p)>0.001:canonical_ids=false
			if goal.action=="site":
				var actual: Dictionary=WolfWorldData.nature_sites(int(goal.region))[int(str(goal.site_id).split(":")[1])]
				if actual.site!=goal.site_id or actual.p.distance_to(goal.p)>0.001:canonical_ids=false
	check(total_steps==21 and canonical_ids,"twenty-one ordered physical steps use the real existing tracks and nature-place identities")
	check(targets_safe,"all physical campaign goals are on dry accessible object-free ground in the unchanged landscape")
	check(not classic.advance_main_story(),"a locked chapter cannot be skipped by the next-chapter button")
	classic.pos=Vector2(2100,700)
	var parent := mother(classic)
	check(not classic.note_main_story_action("greet") and classic.main_story_status().stage==0,"a greeting without an actual family animal does not satisfy the story")
	parent.role="Vater"
	check(not classic.note_main_story_action("greet","",parent),"greeting the father does not substitute for the mother's opening scene")
	parent.role="Mutter";parent.young=true
	check(not classic.note_main_story_action("greet","",parent),"a pup incorrectly labelled as mother cannot satisfy an adult parent requirement")
	parent.young=false;parent.p=classic.pos+Vector2(200,0)
	check(not classic.note_main_story_action("greet","",parent),"the parent must really be within the live greeting distance")
	parent.p=classic.pos+Vector2(80,0);classic.region=1;parent.companion=true
	check(not classic.note_main_story_action("greet","",parent),"a greeting outside the home region cannot bypass the opening return to family")
	classic.region=0
	check(classic.note_main_story_action("greet","",parent) and classic.main_story_status().stage==1,"a mother genuinely elsewhere on her home routine can be greeted without a fixed den-distance trap")
	classic.pos=classic.main_story_status().target_pos
	parent=mother(classic)
	classic.escort=false
	parent.p=classic.pos+Vector2(300,0)
	wait(classic,3,parent)
	check(classic.main_story_status().seconds==0 and not classic.main_story_status().companion_ready,"a distant mother cannot fulfil the local cave meeting without real arrival")
	classic.escort=true;parent.p=classic.pos+Vector2(250,0)
	wait(classic,3,parent)
	check(classic.main_story_status().seconds==0,"standing at the goal alone cannot pretend the mother has arrived")
	parent=mother(classic)
	wait(classic,3,parent,false)
	check(classic.main_story_status().seconds==0,"a blocked nearby parent must finish her real detour before joint arrival counts")
	wait(classic,3,parent,true,2)
	check(classic.main_story_status().seconds==0,"continued player movement cannot impersonate a quiet shared stop")
	parent.speed=70;wait(classic,3,parent)
	check(classic.main_story_status().seconds==0,"the parent must really stop instead of merely running past the goal")
	parent.speed=0
	classic.tick_main_story(-1,parent,true);classic.tick_main_story(INF,parent,true);classic.tick_main_story(NAN,parent,true)
	check(classic.main_story_status().seconds==0,"negative and non-finite frame times cannot corrupt mission duration")
	classic.tick_main_story(100,parent,true)
	check(is_equal_approx(classic.main_story_status().seconds,0.1),"a stalled frame contributes at most one tenth of an active second")
	wait(classic,2.8,parent)
	check(not classic.main_story_status().ready and classic.main_story_status().seconds>2.89,"a partial genuine joint stop stays incomplete")
	classic.clear_main_story_presence()
	check(not classic.main_story_status().player_ready and not classic.main_story_status().companion_ready and classic.main_story_status().seconds>2.89,"view and background pauses clear live presence but retain time already earned")
	classic.tick_main_story(0.1,parent,true)
	check(classic.main_story_status().ready and not classic.main_story_status().companion_ready,"three real shared seconds make the opening chapter ready and clear old proximity")
	var before_xp := classic.xp
	var before_age := classic.age_weeks()
	var before_elapsed := classic.elapsed
	check(classic.advance_main_story() and classic.main_story_status().chapter==1 and classic.xp==before_xp+40,"an explicitly remembered completed chapter awards its experience once")
	check(not classic.advance_main_story() and classic.xp==before_xp+40,"repeated next-chapter activation cannot duplicate the reward")
	check(classic.story_step==18 and classic.age_weeks()==before_age and classic.elapsed==before_elapsed,"campaign progress preserves optional stories and never fast-forwards natural age or the day")
	check(classic.main_story_status().seconds==0 and classic.main_story_status().stage==0,"the new chapter starts with fresh timing rather than the previous stop")
	classic.pos=classic.main_story_status().target_pos;classic.escort=false
	parent=mother(classic);wait(classic,3,parent)
	check(classic.main_story_status().seconds==0 and not classic.main_story_status().companion_ready,"later shared journeys still require an explicitly accepted escort")
	check(fulfill(classic) and classic.main_story_status().action=="drink","the water chapter first requires an actual second shared arrival")
	classic.region=1;classic.note_action("drink")
	check(classic.main_story_status().stage==1,"drinking in another region cannot fulfil the home-pond objective")
	classic.region=0;classic.pos=Vector2(300,300);classic.note_action("drink")
	check(classic.main_story_status().stage==1,"drinking elsewhere does not reuse an old satisfied thirst or water count")
	check(fulfill(classic) and classic.main_story_status().ready and classic.advance_main_story(),"fresh drinking at the genuinely visited bank completes the water chapter")
	var second: Dictionary=WolfMainStory.chapters()[2].stages[1]
	classic.pos=second.p;classic.note_action("site",second.site_id);classic.note_action("mark")
	check(classic.main_story_status().stage==0,"visiting the second scent-place first and marking cannot bypass the ordered first visit")
	classic.pos=classic.main_story_status().target_pos;classic.note_action("site","0:5")
	check(classic.main_story_status().stage==0,"a nearby different nature-place identity does not satisfy the selected place")
	check(fulfill(classic) and fulfill(classic) and fulfill(classic) and classic.main_story_status().ready,"known places require fresh physical checks and a fresh mark in the new story")
	check(classic.advance_main_story() and classic.main_story_status().chapter==3,"the journey opens the real Bergwiese region after the scent-place chapter")
	classic.region=3;classic.pos=classic.main_story_status().target_pos
	parent=mother(classic);parent.companion=false
	wait(classic,3,parent)
	check(classic.main_story_status().stage==0,"a foreign-region wolf must be the actual accompanying mother")
	parent.companion=true;wait(classic,3,parent)
	check(classic.main_story_status().action=="track" and classic.main_story_status().track_id=="3:9","real meadow arrival reveals a specific first hare clue")
	classic.pos=WolfMainStory.chapters()[3].stages[2].p
	check(not classic.note_main_story_action("track","3:11"),"the later hare clue cannot be read first to skip the first clue")
	check(fulfill(classic) and classic.main_story_status().track_id=="3:11","freshly reading the exact first clue advances to the second physical footprint")
	check(fulfill(classic) and classic.main_story_status().ready and classic.advance_main_story(),"two ordered actual hare clues complete the meadow chapter")
	var watched := deer()
	classic.region=3;classic.pos=watched.p+Vector2(0,230)
	wait(classic,4,{},false,0,watched)
	check(classic.main_story_status().seconds==0 and not classic.main_story_status().watch_started,"merely facing wildlife before choosing Observe gives no story observation credit")
	check(not classic.note_main_story_observation(watched,2,true,true),"observation cannot be accepted while the player is moving")
	check(not classic.note_main_story_observation(watched,0,false,true) and not classic.note_main_story_observation(watched,0,true,false),"quiet attention and an actual clear view are both required to accept observation")
	classic.pos=watched.p+Vector2(0,100)
	check(not classic.note_main_story_observation(watched,0,true,true),"approaching inside the wildlife safety distance cannot begin the calm scene")
	classic.pos=watched.p+Vector2(0,430)
	check(not classic.note_main_story_observation(watched,0,true,true),"a distant out-of-range animal cannot satisfy the observation")
	classic.pos=watched.p+Vector2(0,230);watched.alarm=1
	check(not classic.note_main_story_observation(watched,0,true,true),"a frightened animal cannot be accepted as a calm story observation")
	watched.alarm=0;watched.attention=0.8
	check(not classic.note_main_story_observation(watched,0,true,true),"an intensely alert deer must settle before the quiet story scene starts")
	watched.attention=0;watched.behavior="recover"
	check(not classic.note_main_story_observation(watched,0,true,true),"a deer still recovering from fright does not pose as peacefully grazing")
	watched.behavior="forage";watched.speed=80
	check(not classic.note_main_story_observation(watched,0,true,true),"a rapidly travelling animal cannot be mistaken for calm observation")
	watched.speed=0
	check(classic.note_main_story_observation(watched,0,true,true),"an actual calm visible deer can be accepted with the observe action")
	var other := watched.duplicate(true);other.home=watched.home+Vector2(50,0);other.phase=float(watched.phase)+1
	check(not classic.note_main_story_observation(other,0,true,true),"a later observe press cannot silently replace the accepted deer identity")
	wait(classic,4,{},false,0,other)
	check(classic.main_story_status().seconds==0 and not classic.main_story_status().watch_ready,"a nearer passing deer cannot supply time for the chosen individual")
	wait(classic,4,{},false,0,watched,false)
	check(classic.main_story_status().seconds==0,"trees or rocks breaking the actual view pause observation time")
	wait(classic,4,{},false,2,watched)
	check(classic.main_story_status().seconds==0,"moving during the observation does not earn stationary watch time")
	wait(classic,1.2,{},false,0,watched)
	check(is_equal_approx(classic.main_story_status().seconds,1.2),"a genuinely held calm view records partial active duration")
	var path := "user://wolf-main-story-state.json"
	check(classic.save_to(path),"the campaign saves alongside existing version-four progress")
	var restored := WolfState.new()
	check(restored.load_from(path) and restored.main_story_status().chapter==4 and restored.main_story_status().stage==0 and is_equal_approx(restored.main_story_status().seconds,1.2),"an Android restart preserves real partial watch duration and its current chapter")
	check(restored.main_story_status().watch_animal==WolfPackLife.animal_key(watched) and not restored.main_story_status().watch_ready,"the exact watched individual survives saving while live visibility requires a new measurement")
	check(restored.story_step==18 and restored.sites==classic.sites and restored.found==classic.found,"new campaign saves retain old side-story, nature-place, and clue progress")
	wait(restored,2.8,{},false,0,watched)
	check(restored.main_story_status().action=="site" and restored.main_story_status().seconds==0 and restored.main_story_status().watch_animal.is_empty(),"four actual calm seconds finish the watch and clear identity for the next real place")
	check(fulfill(restored) and restored.advance_main_story(),"a fresh check of the actual deer crossing completes the patience chapter")
	check(fulfill(restored) and fulfill(restored) and fulfill(restored) and restored.main_story_status().ready,"river chapter requires a new joint bank visit, fresh drink, and the actual opposite-bank place")
	check(restored.advance_main_story() and restored.main_story_status().target_region==1,"the return journey deliberately opens the real Kiefernwald scent-place")
	check(fulfill(restored) and fulfill(restored) and restored.main_story_status().target_region==0,"fresh pine-place inspection and marking lead back to the real family den")
	restored.region=0;restored.pos=restored.main_story_status().target_pos
	parent=mother(restored,Vector2(300,0));wait(restored,3,parent)
	check(not restored.main_story_status().ready,"the homecoming waits for the mother instead of treating player arrival as joint return")
	check(fulfill(restored) and restored.advance_main_story(),"the actual joint homecoming opens the final family chapter")
	restored.note_action("rest")
	check(restored.main_story_status().stage==0,"old rest flags and an out-of-order rest action cannot replace the fresh family call")
	check(fulfill(restored) and fulfill(restored) and restored.main_story_status().action=="rest_wait","a fresh family howl and protected rest start the actual final rest duration")
	parent=mother(restored)
	wait(restored,4,parent,true,0,{},false,false,"lauschen")
	check(restored.main_story_status().seconds==0,"standing still does not impersonate a real lying rest pose")
	wait(restored,4,parent,false,0,{},false,false,"ruhen")
	check(restored.main_story_status().seconds==0,"resting on opposite sides of an obstacle does not fabricate nearby family rest")
	wait(restored,1.6,parent,true,0,{},false,false,"ruhen")
	check(is_equal_approx(restored.main_story_status().seconds,1.6),"real protected family rest records only active time")
	var final_data := checkpoint(restored,path)
	check(final_data.version==4 and not final_data.main_story.has("player_ready") and not final_data.main_story.has("companion_ready"),"the additive checkpoint stays version four and never persists live family readiness")
	var final_rest := WolfState.new()
	check(final_rest.load_from(path) and final_rest.main_story_status().chapter==7 and is_equal_approx(final_rest.main_story_status().seconds,1.6),"the final partial rest safely survives an app restart")
	parent=mother(final_rest)
	wait(final_rest,4,parent,true,0,{},false,false,"wandern")
	check(is_equal_approx(final_rest.main_story_status().seconds,1.6),"a restart does not keep an old lying pose active without actually resuming rest")
	wait(final_rest,2.4,parent,true,0,{},false,false,"ruhen")
	check(final_rest.main_story_status().ready and final_rest.advance_main_story() and final_rest.main_story_status().done,"all eight chapters conclude only after the final genuine family rest and explicit remembrance")
	var total_xp := final_rest.xp
	check(not final_rest.advance_main_story() and not final_rest.begin_main_story() and final_rest.xp==total_xp,"a completed campaign cannot be restarted to farm duplicate chapter rewards")
	check(final_rest.main_story_progress.completed_chapters.size()==8 and final_rest.age_weeks()==16 and final_rest.elapsed==0,"the full actual campaign has eight earned chapters while natural age and the day remain untouched by mission code")
	check(final_rest.save_to(path),"the completed connected campaign saves its contiguous chapter history")
	var ended := WolfState.new()
	check(ended.load_from(path) and ended.main_story_status().done and ended.xp==total_xp,"completed campaign and exact experience survive reopening without awarding again")
	var legacy := final_data.duplicate(true);legacy.erase("main_story")
	write_json(path,legacy)
	var legacy_state := WolfState.new()
	check(legacy_state.load_from(path) and not legacy_state.main_story_status().started and legacy_state.story_step==18,"all existing version-four saves without a campaign field migrate without losing or auto-completing anything")
	for version in [1,2,3]:
		var old_format := legacy.duplicate(true)
		old_format.version=version
		if version==1:old_format.pos=[float(legacy.pos[0])/2.0,float(legacy.pos[1])/2.0]
		write_json(path,old_format)
		var old_state := WolfState.new()
		check(old_state.load_from(path) and not old_state.main_story_status().started and old_state.pos.distance_to(restored.pos)<0.001 and old_state.story_step==18,"version %d existing saves retain their coordinates and optional stories without a retroactive campaign"%version)
	var invalid := final_data.duplicate(true)
	invalid.main_story={"version":1,"started":true,"chapter":999999,"stage":999999,"completed_chapters":[],"seconds":999999,"target_pos":[-5000,90000],"player_ready":true,"companion_ready":true}
	write_json(path,invalid)
	var damaged := WolfState.new()
	check(damaged.load_from(path) and damaged.main_story_status().chapter==0 and damaged.main_story_status().stage==0 and not damaged.main_story_status().ready,"corrupted out-of-range campaign indices cannot forge completed chapters or an earned step")
	check(damaged.main_story_status().target_pos==WolfMainStory.chapters()[0].stages[0].p and not damaged.main_story_status().companion_ready,"malicious saved coordinates and live flags cannot move canonical goals or invent parent arrival")
	invalid.main_story={"version":1,"started":true,"chapter":4,"stage":0,"completed_chapters":["circle","water","memory","wind"],"seconds":9000,"watch_started":true,"watch_animal":"deer:nan:0:inf"}
	write_json(path,invalid);damaged.load_from(path)
	check(damaged.main_story_status().chapter==4 and not damaged.main_story_status().watch_started and damaged.main_story_status().seconds==0,"an invalid saved animal identity loses untrustworthy watch time while keeping legitimately finished chapters")
	invalid.main_story={"version":1,"started":true,"chapter":2,"stage":1000,"completed_chapters":["circle","water"]}
	write_json(path,invalid);damaged.load_from(path)
	check(damaged.main_story_status().chapter==2 and damaged.main_story_status().stage==0 and not damaged.main_story_status().ready,"a damaged stage does not turn the current chapter into an instant reward")
	invalid.main_story={"version":1,"started":true,"chapter":2,"stage":2,"completed_chapters":["circle","memory"]}
	write_json(path,invalid);damaged.load_from(path)
	check(damaged.main_story_status().chapter==1 and damaged.main_story_status().stage==0,"only an ordered contiguous list of finished chapter identities is accepted")
	invalid.main_story={"version":99,"started":true,"chapter":8,"completed_chapters":WolfMainStory.chapters().map(func(entry: Dictionary):return entry.id)}
	write_json(path,invalid);damaged.load_from(path)
	check(not damaged.main_story_status().started and damaged.story_step==18,"an unknown future campaign format cannot damage or fabricate current story progress")
	var optional := WolfState.new();optional.begin_main_story()
	check(optional.choose_story(0) and optional.story_step==1 and optional.main_story_status().stage==0,"legacy optional story choices remain playable independently of the new main mission")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Main story: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
