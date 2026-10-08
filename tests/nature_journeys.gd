extends SceneTree

var failures := 0
var checks := 0

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func _initialize() -> void:
	call_deferred("run")

func deer(region: int) -> Dictionary:
	var animal: Dictionary=WolfWorldData.generate(region).animals[0].duplicate(true)
	animal.mood="grasen";animal.behavior="forage";animal.speed=0.0;animal.alarm=0.0;animal.attention=0.0
	return animal

func tick(state: WolfState,seconds: float,animal: Dictionary={},view: bool=true,speed: float=0,quiet: bool=true,mood: String="ruhen") -> void:
	for index in range(ceili(seconds/0.1)):state.tick_nature_journey(0.1,speed,animal,view,quiet,mood)

func fulfill(state: WolfState) -> bool:
	var before := state.nature_journey_status()
	if not before.accepted or before.ready:return false
	state.region=int(before.target_region);state.pos=before.target_pos
	match str(before.action):
		"site":state.note_action("site",str(before.site_id))
		"track":state.note_nature_journey_action("track",str(before.track_id))
		"watch":
			var animal := deer(state.region);state.pos=animal.p+Vector2(0,230)
			state.note_nature_journey_observation(animal,0,true,true)
			tick(state,float(before.seconds_required),animal)
		"rest_wait":tick(state,float(before.seconds_required))
		_:state.note_action(str(before.action))
	return int(state.nature_journey_status().stage)==int(before.stage)+1

func raw_save(state: WolfState,path: String) -> Dictionary:
	state.save_to(path)
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func write_json(path: String,value: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value));file.close()

func run() -> void:
	var seen := {};var canonical := true;var dry := true;var cache_bounded := true;var count := 0;var steps := 0
	for region in range(WolfWorldData.REGIONS.size()):
		var world := WolfWorldData.generate(region)
		var definitions := WolfNatureJourneys.definitions(region)
		if definitions.size()!=6:canonical=false
		for journey in definitions:
			count+=1
			if seen.has(journey.id) or not WolfNatureJourneys.valid_id(journey.id):canonical=false
			seen[journey.id]=true
			if journey.stages.size()<2 or journey.stages.size()>3:canonical=false
			for goal in journey.stages:
				steps+=1
				if goal.region!=region:canonical=false
				if goal.action!="watch" and (not WolfWorldData.walkable(goal.p,world.objects) or WolfWorldData.water_blocked(goal.p,region)):dry=false
				if goal.action=="site":
					var site: Dictionary=WolfWorldData.nature_sites(region)[int(str(goal.site_id).split(":")[1])]
					if site.site!=goal.site_id or site.p!=goal.p:canonical=false
				if goal.action=="track":
					var track: Dictionary=world.tracks[int(str(goal.track_id).split(":")[1])]
					if track.id!=goal.track_id or track.p!=goal.p:canonical=false
				if goal.action in ["rest","rest_wait"]:
					var actual_den := false
					for object in world.objects:
						if object.kind=="den" and object.p==goal.den_center:actual_den=true
					if not actual_den or goal.p.distance_to(goal.den_center)>=190:canonical=false
		if WolfNatureJourneys._definitions.size()>16 or WolfNatureJourneys._region_order.size()>16:cache_bounded=false
	print("Regional journeys: %d canonical IDs and %d ordered steps checked"%[count,steps])
	check(count==1536 and seen.size()==1536 and canonical,"all 256 regions offer six distinct journeys with two or three actual canonical place, track and shelter goals")
	check(dry,"all physical interaction and lying-rest goals are on actual dry object-free ground")
	check(cache_bounded,"canonical mission caching retains at most sixteen compact region definitions")
	var first: Vector2=WolfNatureJourneys.definitions(0)[0].stages[0].p
	for region in range(20,40):WolfNatureJourneys.definitions(region)
	check(WolfNatureJourneys.definitions(0)[0].stages[0].p==first,"evicting and regenerating a canonical region never moves a nature-journey goal")
	check(WolfNatureJourneys.definitions(-1).is_empty() and WolfNatureJourneys.definitions(256).is_empty(),"invalid region indices do not generate unrelated offers")
	var state := WolfState.new();state.drank=true;state.rested=true;state.story_step=18;state.action_counts.drink=99
	for site in WolfWorldData.nature_sites(0):state.sites.append(site.site)
	state.found.assign(["0:9","0:11"])
	state.note_action("site","0:0");state.note_action("mark");state.note_action("drink")
	check(not state.nature_journey_status().accepted and state.nature_journey_status().completed_count==0,"old actions, known places and optional stories never retroactively start or finish a nature journey")
	check(state.nature_journeys_options().size()==6 and state.nature_journeys_options()[0].available,"a free current region offers six explicit selectable journeys")
	for bad in ["256:scent","-1:water","00:scent","999999999999999:rest","0:unknown","0:watch:extra"]:
		check(not state.begin_nature_journey(bad),"invalid journey identity is rejected: "+bad)
	check(not state.begin_nature_journey("1:scent"),"accepting a journey remotely cannot turn another region's unseen tasks into local goals")
	check(state.begin_nature_journey("0:scent") and state.nature_journey_status().stage==0,"a selected scent journey starts at a fresh exact nature-place check")
	check(not state.begin_nature_journey("0:water") and not state.nature_journeys_options()[1].available,"only one nature journey can be active at a time")
	check(not state.claim_nature_journey(),"claiming an unfinished journey gives no reward")
	state.pos=state.nature_journey_status().target_pos;state.note_action("mark")
	check(state.nature_journey_status().stage==0,"marking before the actual selected place check cannot bypass the first step")
	state.note_action("site","0:1")
	check(state.nature_journey_status().stage==0,"a wrong site identity does not fulfil a nearby different place")
	state.region=1;state.note_action("site","0:0")
	check(state.nature_journey_status().stage==0,"a correct site ID in the wrong live region cannot fulfil the journey")
	state.region=0;state.pos=Vector2(2500,500);state.note_action("site","0:0")
	check(state.nature_journey_status().stage==0,"a remote site action does not pretend to have physically reached the nature place")
	check(fulfill(state) and state.nature_journey_status().action=="mark","a fresh actual check of a previously known place reveals its ordered marking step")
	check(fulfill(state) and state.nature_journey_status().ready and state.nature_journey_status().done,"a fresh mark at the checked place makes the journey ready for explicit claim")
	var earned := state.xp;var bond := state.bond;var nose := int(state.skills.nose)
	check(state.claim_nature_journey() and state.xp==earned+30 and state.bond==bond+1 and int(state.skills.nose)==nose+2,"a claimed scent journey awards exactly thirty experience, two skill points and one bond point")
	check(not state.claim_nature_journey() and state.xp==earned+30,"a repeated claim cannot award a journey twice")
	check(not state.begin_nature_journey("0:scent") and state.nature_journeys_options()[0].completed,"a completed regional journey remains marked and cannot be replayed for duplicate rewards")
	check(state.begin_nature_journey("0:water") and state.nature_journey_status().stage==0,"another journey has fresh stages despite previously drinking")
	state.pos=Vector2(300,300);state.note_action("drink")
	check(state.nature_journey_status().stage==0,"drinking outside the exact bank target cannot fulfil its new water journey")
	check(fulfill(state) and state.nature_journey_status().site_id=="0:2","fresh drinking at the actual dry bank guides the specific next nature place")
	check(state.abandon_nature_journey() and not state.abandon_nature_journey(),"abandoning clears the accepted journey once without marking it completed")
	check(state.begin_nature_journey("0:water") and state.nature_journey_status().stage==0,"reaccepting an abandoned route cannot reuse its earlier drink step")
	check(fulfill(state) and fulfill(state) and state.claim_nature_journey(),"a newly accepted water journey completes only with two fresh actual steps")
	check(state.begin_nature_journey("0:tracks") and state.nature_journey_status().track_id=="0:9","the footprint journey selects the exact first canonical hare clue")
	state.pos=WolfNatureJourneys.definition("0:tracks").stages[1].p
	check(not state.note_nature_journey_action("track","0:11"),"reading the later footprint first cannot skip the earlier clue")
	check(fulfill(state) and state.nature_journey_status().track_id=="0:11","freshly rereading the known exact first clue advances the ordered trail")
	check(fulfill(state) and state.claim_nature_journey() and state.found.size()==2,"reading known story footprints never adds duplicate old discovery entries")
	check(state.begin_nature_journey("0:places") and fulfill(state) and fulfill(state) and state.claim_nature_journey(),"two-place journeys require both exact physical places in their own order")
	check(state.begin_nature_journey("0:watch"),"a regional observation journey can be accepted independently of the main story")
	var animal := deer(0);state.pos=animal.p+Vector2(0,230)
	tick(state,4,animal)
	check(state.nature_journey_status().seconds==0 and not state.nature_journey_status().watch_started,"merely facing a deer before an actual observe action gives no journey time")
	check(not state.note_nature_journey_observation(animal,2,true,true),"a moving player cannot begin the quiet wildlife journey")
	check(not state.note_nature_journey_observation(animal,0,false,true) and not state.note_nature_journey_observation(animal,0,true,false),"quiet attention and actual free sight are both required at observe acceptance")
	state.pos=animal.p+Vector2(0,100)
	check(not state.note_nature_journey_observation(animal,0,true,true),"an overly close deer cannot be counted as a safe quiet observation")
	state.pos=animal.p+Vector2(0,430)
	check(not state.note_nature_journey_observation(animal,0,true,true),"an out-of-range deer cannot start the journey observation")
	state.pos=animal.p+Vector2(0,230);animal.alarm=1
	check(not state.note_nature_journey_observation(animal,0,true,true),"a frightened deer must settle before observation is accepted")
	animal.alarm=0;animal.attention=0.8
	check(not state.note_nature_journey_observation(animal,0,true,true),"high wildlife attention prevents quiet observation acceptance")
	animal.attention=0;animal.behavior="recover"
	check(not state.note_nature_journey_observation(animal,0,true,true),"a deer still recovering from fright is not treated as calm")
	animal.behavior="forage";animal.speed=80
	check(not state.note_nature_journey_observation(animal,0,true,true),"fast animal travel cannot impersonate a calm quiet scene")
	animal.speed=0
	check(state.note_nature_journey_observation(animal,0,true,true),"a genuinely calm visible deer can be selected with the observe action")
	var other := animal.duplicate(true);other.home=animal.home+Vector2(50,0);other.phase=float(animal.phase)+1
	check(not state.note_nature_journey_observation(other,0,true,true),"pressing observe again cannot silently splice another deer into the accepted watch")
	tick(state,4,other)
	check(state.nature_journey_status().seconds==0 and not state.nature_journey_status().watch_ready,"another closer animal cannot provide time for the accepted individual")
	tick(state,4,animal,false);tick(state,4,animal,true,2)
	check(state.nature_journey_status().seconds==0,"blocked sight and player movement do not accumulate calm watch duration")
	state.tick_nature_journey(INF,0,animal,true,true);state.tick_nature_journey(NAN,0,animal,true,true);state.tick_nature_journey(-1,0,animal,true,true)
	check(state.nature_journey_status().seconds==0,"invalid frame durations cannot corrupt wildlife journey time")
	state.tick_nature_journey(100,0,animal,true,true)
	check(is_equal_approx(state.nature_journey_status().seconds,0.1),"a stalled frame contributes at most a tenth of one active second")
	tick(state,1.1,animal)
	check(is_equal_approx(state.nature_journey_status().seconds,1.2),"real partial quiet observation is retained for the exact individual")
	state.clear_encounter_presence()
	check(not state.nature_journey_status().watch_ready and is_equal_approx(state.nature_journey_status().seconds,1.2),"the shared pause/view reset clears live journey visibility while preserving earned time")
	var path := "user://nature-journeys-test.json"
	var data := raw_save(state,path)
	check(data.version==4 and data.has("nature_journeys") and not data.nature_journeys.active.has("watch_ready") and not data.nature_journeys.active.has("target_pos"),"additive version-four saves contain progress but never live visibility or canonical goal coordinates")
	var restored := WolfState.new()
	check(restored.load_from(path) and is_equal_approx(restored.nature_journey_status().seconds,1.2) and restored.nature_journey_status().watch_animal==WolfPackLife.animal_key(animal),"a restart preserves exact watched identity and genuinely earned partial seconds")
	check(not restored.nature_journey_status().watch_ready and restored.story_step==18 and not restored.main_story_status().started,"loading never assumes visible wildlife and retains unrelated optional and main stories")
	tick(restored,2.8,animal)
	check(restored.nature_journey_status().action=="site" and restored.nature_journey_status().seconds==0 and restored.nature_journey_status().watch_animal.is_empty(),"four real quiet seconds guide the next actual site and clear old live watch state")
	check(fulfill(restored) and restored.claim_nature_journey(),"a fresh nature-place check completes the separate wildlife journey")
	check(restored.begin_nature_journey("0:rest") and fulfill(restored) and restored.nature_journey_status().action=="rest","a shelter journey first requires its exact selected place check")
	restored.pos=Vector2(1692,2180);restored.note_action("rest")
	check(restored.nature_journey_status().stage==1,"resting at the family den cannot impersonate the separately selected actual shelter")
	check(fulfill(restored) and restored.nature_journey_status().action=="rest_wait","fresh resting at the actual selected shelter starts the physical lying duration")
	tick(restored,3,{},false,0,false,"lauschen")
	check(restored.nature_journey_status().seconds==0,"standing quietly does not impersonate a lying rest pose")
	tick(restored,3,{},false,2,false,"ruhen")
	check(restored.nature_journey_status().seconds==0,"moving with a stale resting mood cannot count as protected rest")
	restored.pos=Vector2(3000,3000);tick(restored,3)
	check(restored.nature_journey_status().seconds==0,"a rest pose outside the selected shelter is not credited")
	restored.pos=restored.nature_journey_status().target_pos;tick(restored,1.2)
	check(is_equal_approx(restored.nature_journey_status().seconds,1.2) and restored.nature_journey_status().player_ready,"actual stationary lying at the selected shelter records fresh active duration")
	var partial_rest := raw_save(restored,path)
	var waking := WolfState.new();waking.load_from(path)
	check(not waking.nature_journey_status().player_ready and is_equal_approx(waking.nature_journey_status().seconds,1.2),"a shelter restart retains real partial rest but not a fictitious live lying pose")
	tick(waking,3,{},false,0,false,"wandern")
	check(is_equal_approx(waking.nature_journey_status().seconds,1.2),"after restart the player must actually resume lying before rest time continues")
	tick(waking,1.8)
	check(waking.nature_journey_status().ready and waking.claim_nature_journey() and waking.nature_journey_status().completed_count==6,"all six regional journeys conclude after their own real ordered actions and explicit claims")
	check(waking.age_weeks()==16 and waking.elapsed==0 and waking.story_step==18,"six claimed nature journeys never skip natural age, world time, or old story chapters")
	check(waking.begin_main_story() and waking.main_story_status().chapter==0 and not waking.nature_journey_status().accepted,"main-story acceptance remains independent after regional journeys")
	var completed := raw_save(waking,path)
	var reopened := WolfState.new();reopened.load_from(path)
	check(reopened.nature_journey_status().completed_count==6 and not reopened.begin_nature_journey("0:rest") and not reopened.claim_nature_journey(),"completed IDs survive reopening and prevent reward duplication")
	for version in [1,2,3,4]:
		var legacy := partial_rest.duplicate(true);legacy.erase("nature_journeys");legacy.version=version
		if version==1:legacy.pos=[float(legacy.pos[0])/2,float(legacy.pos[1])/2]
		write_json(path,legacy);var old := WolfState.new()
		check(old.load_from(path) and not old.nature_journey_status().accepted and old.nature_journey_status().completed_count==0 and old.story_step==18,"existing save version %d migrates without retroactive nature journeys or lost optional stories"%version)
	var bad := completed.duplicate(true)
	bad.nature_journeys={"version":1,"active":{"id":"256:watch","stage":9000},"completed":["0:scent","0:scent","00:water","-1:rest","255:places",false,123]}
	write_json(path,bad);var damaged := WolfState.new();damaged.load_from(path)
	check(not damaged.nature_journey_status().accepted and damaged.nature_journey_status().completed_count==2,"malformed saved identifiers are rejected and valid completed journeys are deduplicated")
	bad.nature_journeys={"version":1,"active":{"id":"1:places","stage":99999,"target_pos":[-5000,90000],"player_ready":true},"completed":[]}
	write_json(path,bad);damaged.load_from(path)
	check(damaged.nature_journey_status().stage==0 and not damaged.nature_journey_status().ready and damaged.nature_journey_status().target_pos==WolfNatureJourneys.definition("1:places").stages[0].p and not damaged.nature_journey_status().player_ready,"damaged stages, saved coordinates and live flags cannot fabricate goals or earned completion")
	bad.nature_journeys={"version":1,"active":{"id":"1:watch","stage":0,"seconds":9999,"watch_started":true,"watch_animal":"deer:nan:20:inf"},"completed":[]}
	write_json(path,bad);damaged.load_from(path)
	check(not damaged.nature_journey_status().watch_started and damaged.nature_journey_status().seconds==0,"invalid saved wildlife identity discards untrustworthy watch time")
	bad.nature_journeys={"version":1,"active":{"id":"1:scent","stage":2},"completed":["1:scent"]}
	write_json(path,bad);damaged.load_from(path)
	check(not damaged.nature_journey_status().accepted and not damaged.claim_nature_journey(),"a saved already-claimed active journey cannot reclaim its reward")
	bad.nature_journeys={"version":99,"active":{"id":"1:scent","stage":2},"completed":["1:scent"]}
	write_json(path,bad);damaged.load_from(path)
	check(not damaged.nature_journey_status().accepted and damaged.main_story_status().started and damaged.story_step==18,"an unsupported future journey format leaves main story and legacy stories intact")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Nature journeys: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
