extends SceneTree

# Real controller integration. Position fixtures select known interaction
# locations; actions, exits, observation, saves and pause hooks are unmodified.
const SAVE := "user://wolf_nature_journey_integration.json"
var checks := 0
var failures := 0

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func find_button(node: Node,prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):return node
	for child in node.get_children():
		var found := find_button(child,prefix)
		if found!=null:return found
	return null

func has_label_text(node: Node,text: String) -> bool:
	if not is_instance_valid(node):return false
	if node is Label and node.text.contains(text):return true
	for child in node.get_children():
		if has_label_text(child,text):return true
	return false

func clean() -> void:
	for path in [SAVE,SAVE+".pending",SAVE+".wildlife.json",SAVE+".wildlife.json.pending"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)

func launch() -> Node:
	var game = load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game);game.set_process(false)
	await process_frame
	game.close_overlay()
	return game

func dispose(game: Node) -> void:
	game._release_audio();await create_timer(.15).timeout
	root.remove_child(game);game.queue_free();await process_frame

func cross(game: Node,direction: String) -> void:
	var positions := {"north":Vector2(1600,25),"east":Vector2(3175,1600),"south":Vector2(1600,3175),"west":Vector2(25,1600)}
	var vectors := {"north":Vector2.UP,"east":Vector2.RIGHT,"south":Vector2.DOWN,"west":Vector2.LEFT}
	var expected: int=WolfWorldData.REGIONS[game.state.region].links[direction]
	game.state.pos=positions[direction];game.state.facing=vectors[direction]
	game.move_wolf(vectors[direction]*12)
	check(game.state.region==expected and game.can_walk(game.state.pos),"the accepted nature journey uses the actual dry %s region gate"%direction)

func at_goal(game: Node) -> Dictionary:
	var status: Dictionary=game.state.nature_journey_status()
	game.state.pos=status.target_pos;game.player_speed=0
	game.rest_cooldown=0;game.last_pack_visit=-30
	return status

func neighbor_mother(game: Node) -> void:
	for animal in game.world.animals:
		if animal.kind=="wolf" and animal.get("role","")=="Mutter":animal.p=game.state.pos+Vector2(40,0);return

func nature_status(game: Node) -> Dictionary:
	return game.state.nature_journey_status()

func run() -> void:
	WolfState.save_path=SAVE;clean()
	var game: Node=await launch()
	check(game.state.region==0 and game.can_walk(game.state.pos),"nature journeys start from the playable offline home")
	game.state.begin_main_story()
	for animal in game.world.animals:
		if animal.kind=="wolf" and animal.get("role","")=="Mutter":game.state.pos=animal.p;game.interact();break
	check(game.state.main_story_status().action=="joint","the active campaign has a real mother greeting and a visible pending shared-arrival goal")
	game.state.begin_encounter()
	game.state.story_step=1;game.state.story_choices.append("Neben der Familie ruhen")
	game.state.found.append("0:0")
	var main_before: Dictionary=game.state.main_story_progress.duplicate(true)
	var encounter_id: String=game.state.active_encounter.id
	check(game._save_game(),"an existing campaign and local encounter save before nature journeys are used")
	var old_save: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	old_save.erase("nature_journeys")
	var fixture := FileAccess.open(SAVE,FileAccess.WRITE)
	fixture.store_string(JSON.stringify(old_save));fixture.close()
	await dispose(game);game=await launch()
	check(not nature_status(game).accepted and game.state.story_step==1 and game.state.found.has("0:0"),"a version-four save without the new additive field resumes its old memories and tracks with no invented nature journey")
	check(game.state.main_story_progress==main_before and game.state.active_encounter.id==encounter_id,"loading the previous save format preserves both existing story and encounter checkpoints")
	game.show_nature_journeys();await process_frame;await process_frame
	var scent_title := ""
	for offer in game.state.nature_journeys_options():
		if offer.id=="0:scent":scent_title=str(offer.title)
	var accept: Button=find_button(game.overlay,"◌ "+scent_title)
	check(accept!=null and not accept.disabled,"the nature menu exposes an available local scent journey")
	if accept!=null:accept.pressed.emit()
	check(nature_status(game).accepted and nature_status(game).id=="0:scent" and not is_instance_valid(game.overlay),"the actual menu accepts a nature journey beside the existing campaign and encounter and returns outdoors")
	game._refresh_status()
	check(game.quest_hint.text.begins_with("Naturreise · ") and not game.quest_hint.text.contains(str(nature_status(game).objective)) and game.state.waypoint_pos==nature_status(game).target_pos,"selecting the nature guide shows its compact identity and leads to the actual objective without duplicating long instructions")
	game.guide_main_story();game._refresh_status()
	check(game.quest_hint.text.begins_with("Hauptgeschichte · ") and not game.quest_hint.text.contains(str(game.state.main_story_status().objective)) and game.state.waypoint_pos==game.state.main_story_status().target_pos,"explicit main-story guidance restores its compact identity and real destination")
	game.guide_nature_journey()
	game.set_waypoint(3,Vector2(1660,1490))
	game.mark_territory()
	check(nature_status(game).stage==0,"an early scent mark cannot skip the required inspection")
	at_goal(game);neighbor_mother(game);game.interact()
	game._refresh_nature_journey_guide()
	check(nature_status(game).stage==1 and nature_status(game).action=="mark","actual inspection at the selected place works beside the mother and advances the ordered journey")
	check(game.state.waypoint_region==3 and game.state.waypoint_pos==Vector2(1660,1490),"a user's personal map destination survives a nature-stage change without automatic guide takeover")
	check(game.state.main_story_progress==main_before and game.state.active_encounter.id==encounter_id,"a nature inspection keeps the independent main-story checkpoint and active encounter identity")
	game.interact()
	check(nature_status(game).ready,"the actual second context action sets a scent and completes the accepted two-step nature journey")
	var reward_xp: int=game.state.xp
	var reward_skill: int=game.state.skills.nose
	var reward_bond: float=game.state.bond
	game.show_nature_journeys();await process_frame;await process_frame
	var claim: Button=find_button(game.overlay,"Die Erfahrung mitnehmen")
	check(claim!=null,"the completed journey exposes its explicit reward action in the real menu")
	if claim!=null:claim.pressed.emit()
	game.close_overlay()
	check(game.state.xp==reward_xp+30 and game.state.skills.nose==mini(100,reward_skill+2) and is_equal_approx(game.state.bond,minf(100,reward_bond+1)),"claiming awards exactly the documented experience, skill and bond")
	check(not game.state.claim_nature_journey() and game.state.xp==reward_xp+30,"repeating a nature claim cannot duplicate rewards")
	check(not game.state.begin_nature_journey("0:scent"),"a completed local nature journey cannot be restarted for farming")
	check(game.state.begin_nature_journey("0:tracks"),"a distinct ordered track journey remains available after claiming the scent journey")
	var track: Dictionary=nature_status(game)
	game.state.found.append(track.track_id)
	at_goal(game);neighbor_mother(game)
	var found_before: int=game.state.found.size()
	var nose_before: int=game.state.skills.nose
	game.sniff();game.interact()
	check(nature_status(game).stage==1,"the actual gameplay action can reread the journey's previously discovered exact track")
	check(game.state.found.size()==found_before and game.state.skills.nose==nose_before,"rereading the known selected track gives no duplicate track or skill reward")
	game.state.escort=true;game._sync_companion()
	game.set_waypoint(3,Vector2(1660,1490))
	var stage_before: int=nature_status(game).stage
	var progress_before: Dictionary=game.state.main_story_progress.duplicate(true)
	var age_before: float=game.state.elapsed
	cross(game,"north")
	game._tick_nature_journey(.1)
	check(nature_status(game).stage==stage_before and not nature_status(game).player_ready,"entering a neighboring region cannot satisfy an unfinished home track remotely")
	check(game.state.active_encounter.id==encounter_id and game.state.main_story_progress==progress_before,"a nature journey region crossing preserves the separate campaign and encounter")
	check(game._save_game(),"an accepted partially completed nature journey saves with the real traveling game")
	await dispose(game);game=await launch()
	check(game.state.region==3 and nature_status(game).stage==stage_before and nature_status(game).id=="0:tracks","restarting outside the journey region restores its actual accepted identity and earned ordered step")
	check(game.state.elapsed==age_before and game.state.waypoint_region==3 and game.state.waypoint_pos==Vector2(1660,1490),"restarting preserves natural age and the player's independent map destination")
	check(game.state.main_story_progress==progress_before and game.state.active_encounter.id==encounter_id,"restarting the traveling nature journey keeps the campaign and existing encounter intact")
	cross(game,"south");at_goal(game);neighbor_mother(game);game.sniff();game.interact()
	check(nature_status(game).ready,"returning through the real gate lets the exact second track finish the saved journey")
	check(game.state.claim_nature_journey(),"the journey resumed from disk can claim its reward once")
	check(game.state.begin_nature_journey("0:watch"),"a quiet watch journey can start after the completed track journey")
	var original_objects: Array=game.world.objects
	var original_animals: Array=game.world.animals
	game.state.pos=Vector2(1600,1800);game.world.objects=[]
	var watched := {"kind":"deer","p":Vector2(1600,1580),"home":Vector2(1600,1580),"phase":0.2,"mood":"lauschen","behavior":"alert","attention":0.0,"alarm":0.0,"facing":Vector2.UP,"speed":0.0,"gait":0.0}
	game.world.animals=[watched]
	if not game.first_person:game.toggle_view()
	game.world_view.yaw=0;game.world_view.pitch=-.14;game.player_speed=0
	game.guide_nature_journey();game._refresh_status()
	check(game.observation_panel.visible and game.observation_title.text.begins_with("Naturreise · ") and game.observation_progress.max_value==4,"the chosen nature watch owns the live panel instead of the unfinished campaign's mother-arrival panel")
	game.observation_details.pressed.emit();await process_frame;await process_frame
	check(is_instance_valid(game.overlay) and has_label_text(game.overlay,str(nature_status(game).objective)),"the live nature panel details button opens the full currently selected nature objective")
	game.close_overlay()
	game.guide_main_story();game._refresh_status()
	check(not game.observation_title.text.begins_with("Naturreise · ") and game.quest_hint.text.begins_with("Hauptgeschichte · ") and game.state.waypoint_pos==game.state.main_story_status().target_pos,"choosing main-story guidance returns both compact guidance and the live panel to the campaign")
	game.observation_details.pressed.emit();await process_frame;await process_frame
	check(is_instance_valid(game.overlay) and has_label_text(game.overlay,str(game.state.main_story_status().objective)),"the live campaign panel details button opens the full selected story objective")
	game.close_overlay()
	game.guide_nature_journey()
	game._tick_nature_journey(.1)
	check(nature_status(game).seconds==0,"looking alone cannot start a nature watch without the actual observe action")
	check(game.observe() and nature_status(game).watch_started,"the real observe action accepts the visible calm deer for the nature watch")
	for i in range(10):game._tick_nature_journey(.1)
	var watched_seconds: float=nature_status(game).seconds
	check(watched_seconds>.99 and watched_seconds<1.01,"the real visible accepted deer earns exactly one active observation second")
	var other: Dictionary=watched.duplicate(true);other.home=Vector2(1600,1610);other.p=other.home;other.phase=1.1
	game.world.animals=[other];game._tick_nature_journey(.1)
	check(nature_status(game).seconds==watched_seconds,"a closer different deer cannot replace the accepted individual")
	game.world.animals=[watched];game.world.objects=[{"kind":"tree","p":Vector2(1600,1690),"scale":1.0,"variant":0}]
	game._tick_nature_journey(.1)
	check(nature_status(game).seconds==watched_seconds,"an actual intervening trunk stops nature observation time")
	game.world.objects=[];game.show_menu();game._process(30);game._tick_nature_journey(30)
	check(nature_status(game).seconds==watched_seconds and game.state.elapsed==age_before,"menu planning pauses the observation journey and gradual aging")
	game.close_overlay();game._notification(Node.NOTIFICATION_APPLICATION_PAUSED);game._process(30);game._tick_nature_journey(30)
	check(nature_status(game).seconds==watched_seconds and game.app_idle,"Android background pause preserves earned seconds without counting background time")
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	game._tick_nature_journey(30)
	check(nature_status(game).seconds<=watched_seconds+.10001,"a stalled foreground frame contributes at most one short real observation tick")
	for i in range(40):game._tick_nature_journey(.1)
	check(nature_status(game).stage==1 and nature_status(game).action=="site","four real quiet seconds advance to the nature watch's physical follow-up site")
	game.world.objects=original_objects;game.world.animals=original_animals
	at_goal(game);neighbor_mother(game);game.interact()
	check(nature_status(game).ready and game.state.claim_nature_journey(),"the watched deer journey completes only after its actual follow-up place is inspected")
	check(game.state.begin_nature_journey("0:rest"),"a sheltered nature rest journey is available independently of the main campaign")
	at_goal(game);neighbor_mother(game);game.interact()
	check(nature_status(game).action=="rest","actual inspection opens the nature journey's chosen physical shelter")
	at_goal(game);neighbor_mother(game);game.interact()
	check(game.player_mood=="ruhen" and nature_status(game).action=="rest_wait","the contextual shelter action starts a real rest pose before timed rest can count")
	for i in range(10):game._tick_nature_journey(.1)
	var rested_seconds: float=nature_status(game).seconds
	check(rested_seconds>.99 and rested_seconds<1.01,"actual lying at the chosen shelter earns one real active rest second")
	game.player_mood="laufen";game._tick_nature_journey(.1)
	check(nature_status(game).seconds==rested_seconds,"standing or walking cannot substitute for the nature journey's actual resting pose")
	game.player_mood="ruhen";game.state.pos+=Vector2(500,0);game._tick_nature_journey(.1)
	check(nature_status(game).seconds==rested_seconds,"resting far from the selected shelter cannot count remotely")
	at_goal(game);game.player_mood="ruhen"
	for i in range(25):game._tick_nature_journey(.1)
	check(nature_status(game).ready and game.state.claim_nature_journey(),"returning to the actual shelter and completing three lying seconds earns the rest journey reward")
	check(game.state.begin_nature_journey("0:water"),"the actual water journey remains independently available")
	at_goal(game);neighbor_mother(game);game.interact()
	check(game.state.drank and game.state.thirst==100 and nature_status(game).action=="site","drinking at the actual chosen bank works beside the mother and advances the water journey")
	at_goal(game);neighbor_mother(game)
	var water_site_xp: int=game.state.xp
	game.interact()
	check(nature_status(game).ready and game.state.xp==water_site_xp,"revisiting the already inspected follow-up site advances the journey without duplicate site experience")
	check(game.state.claim_nature_journey(),"the physical drink-and-site journey claims its one reward")
	check(game.state.begin_nature_journey("0:places"),"the two-place journey can still be accepted after the other nature journeys")
	at_goal(game);neighbor_mother(game);game.interact()
	check(nature_status(game).stage==1 and not nature_status(game).ready,"the actual first selected place cannot stand in for both ordered place visits")
	at_goal(game);neighbor_mother(game);game.interact()
	check(nature_status(game).ready and game.state.claim_nature_journey(),"the actual second selected place completes the sixth distinct local journey")
	check(nature_status(game).completed_count==6 and game.state.main_story_progress==main_before and game.state.active_encounter.id==encounter_id,"all six actual local journeys complete without replacing the main campaign or active encounter")
	# Establish a separate campaign watch at its canonical chapter checkpoint.
	# Its accepted deer differs from the nearby nature-watch deer: guidance
	# must choose the requested existing identity rather than stealing the other.
	game.change_region(3,Vector2(1600,1800));game.world.objects=[]
	var completed_chapters: Array[String]=[]
	for index in range(4):completed_chapters.append(WolfMainStory.chapters()[index].id)
	game.state.main_story_progress=WolfMainStory.restored({"version":1,"started":true,"chapter":4,"stage":0,"completed_chapters":completed_chapters})
	check(game.state.begin_nature_journey("3:watch"),"another region offers its own independent nature watch beside the campaign watch")
	var story_deer: Dictionary=watched.duplicate(true);story_deer.p=Vector2(1600,1540);story_deer.home=Vector2(1500,1500);story_deer.phase=.2
	var nature_deer: Dictionary=watched.duplicate(true);nature_deer.p=Vector2(1600,1590);nature_deer.home=Vector2(1700,1500);nature_deer.phase=1.1
	game.world.animals=[story_deer,nature_deer];game.player_speed=0
	game.world_view.yaw=0;game.world_view.pitch=-.14
	check(game.state.note_main_story_observation(story_deer,0,true,true),"the campaign fixture accepts its actual distinct visible deer")
	game.guide_nature_journey()
	check(game.observe() and nature_status(game).watch_animal==WolfPackLife.animal_key(nature_deer),"choosing nature guidance accepts its nearest actual deer despite the campaign's different existing lock")
	game.world.animals=[nature_deer]
	check(game.observe(),"with different locks the selected nature observe action works while the campaign's deer is absent")
	game.guide_main_story()
	check(not game.observe(),"choosing campaign guidance cannot replace its missing accepted deer with the nature deer")
	game.world.animals=[story_deer,nature_deer]
	check(game.observe() and game.state.main_story_status().watch_animal==WolfPackLife.animal_key(story_deer) and nature_status(game).watch_animal==WolfPackLife.animal_key(nature_deer),"returning the campaign deer allows its selected action while preserving both independent accepted identities")
	await dispose(game);clean()
	print("Wolf nature-journey integration: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
