extends SceneTree

# No player/animal position assignment and no campaign checkpoint assignment.
# The 0.9 recovery fixture is produced by this same controller journey run
# against the unchanged 0.9 project with --fixture-only, after its real greeting.
const FRESH_SAVE := "user://wolf_first_mission_controller.json"
const OLD_SAVE := "user://wolf_first_mission_09_controller.json"
const RECOVERY_FIXTURE := "res://tests/fixtures/first_mission_09.json"
const DT := .05
var checks := 0
var failures := 0
var active_ticks := 0
var motion_safe := true
var observed_joint_seconds := 0.0
var joint_gates_safe := true
var blocked_intent_ticks := 0
var blocked_intent_safe := true

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func find_button(node: Node,prefix: String) -> Button:
	if not is_instance_valid(node):return null
	if node is Button and node.text.begins_with(prefix):return node
	for child in node.get_children():
		var found := find_button(child,prefix)
		if found!=null:return found
	return null

func mother(game: Node) -> Dictionary:
	for animal in game.world.animals:
		if animal.kind=="wolf" and animal.get("role","")=="Mutter" and not animal.get("young",false):return animal
	return {}

func tick(game: Node,direction: Vector2=Vector2.ZERO) -> void:
	var parent := mother(game)
	var before: Vector2=parent.p if not parent.is_empty() else Vector2.ZERO
	var previous: Dictionary=game.state.main_story_status()
	game.stick.vector=direction
	game._process(DT);active_ticks+=1
	var current: Dictionary=game.state.main_story_status()
	if previous.chapter==0 and previous.stage==1 and not previous.ready:
		if direction.length()>.01 and game.player_speed<=1:
			blocked_intent_ticks+=1
			blocked_intent_safe=blocked_intent_safe and not current.ready and float(current.seconds)<=float(previous.seconds)+.00001 and game.player_mood=="laufen" and game._quiet_player_speed()>1
		var added: float=DT if current.ready else maxf(0,float(current.seconds)-float(previous.seconds))
		if added>0:
			observed_joint_seconds+=added
			joint_gates_safe=joint_gates_safe and game.player_speed<=1 and parent.get("speed",INF)<=1 and parent.p.distance_to(game.state.pos)<150 and parent.p.distance_to(Vector2(1580,2180))<300 and game.world._animal_motion.segment_free(game.state.pos,parent.p)
			if current.ready:print("FIRST-MISSION SHARED-COMPLETE player=",game.state.pos," mother=",parent.p," mother_speed=",parent.get("speed",0)," player_speed=",game.player_speed," observed_seconds=",observed_joint_seconds)
	if not parent.is_empty():
		var navigation: WolfAnimalMotion=game.world._animal_motion
		if before.distance_to(parent.p)>220*DT+.01 or not navigation.segment_free(before,parent.p):motion_safe=false

func walk(game: Node,goal: Vector2,stop: float=5,max_frames: int=2400,moving_parent: bool=false) -> bool:
	tick(game)
	var navigation: WolfAnimalMotion=game.world._animal_motion
	var route := PackedVector2Array()
	var planned := Vector2(INF,INF)
	var stalled := 0
	var detour := Vector2(INF,INF)
	for index in range(max_frames):
		var target: Vector2=mother(game).p if moving_parent else goal
		if game.state.pos.distance_to(target)<stop and navigation.segment_free(game.state.pos,target):game.stick.reset();return true
		# The player still steers through the actual controller. Static terrain
		# routes cannot anticipate a live escort body occupying their next turn.
		if detour.is_finite() and game.state.pos.distance_to(detour)<8:
			detour=Vector2(INF,INF);route.clear()
		var free_target := navigation.nearest_free(detour if detour.is_finite() else target)
		if not free_target.is_finite():game.stick.reset();return false
		if not moving_parent and game.state.pos.distance_to(free_target)<stop:game.stick.reset();return true
		while not route.is_empty() and game.state.pos.distance_to(route[0])<3:route.remove_at(0)
		if route.is_empty() or planned.distance_to(free_target)>45 or not navigation.segment_free(game.state.pos,route[0]):
			route=navigation.route(game.state.pos,free_target);planned=free_target
		if route.is_empty():game.stick.reset();return false
		var delta: Vector2=route[0]-game.state.pos
		var before: Vector2=game.state.pos
		tick(game,delta.normalized()*minf(1,delta.length()/(120*DT)))
		stalled=stalled+1 if before.distance_to(game.state.pos)<.05 else 0
		if stalled>=12:
			var members := WolfPackInteractions.cohort(game.world.animals)
			var found := false
			for angle in [PI/2,-PI/2,PI*.75,-PI*.75,PI]:
				var candidate: Vector2=before+delta.normalized().rotated(angle)*100
				if navigation.segment_free(before,candidate) and navigation.player_step_free(before,candidate,members):
					detour=candidate;route.clear();found=true;break
			if not found:detour=Vector2(INF,INF);route.clear()
			stalled=0
	game.stick.reset();return false

func dispose(game: Node) -> void:
	game._release_audio();await create_timer(.15).timeout
	root.remove_child(game);game.queue_free();await process_frame

func clean(path: String) -> void:
	for item in [path,path+".pending",path+".wildlife.json",path+".wildlife.json.pending"]:
		if FileAccess.file_exists(item):DirAccess.remove_absolute(item)

func launch(path: String) -> Node:
	WolfState.save_path=path
	var game = load("res://main.tscn").instantiate()
	root.add_child(game);game.set_process(false);await process_frame
	game.state.sound_enabled=false
	return game

func greet_from_spawn(game: Node) -> bool:
	check(game.state.pos==WolfWorldData.SPAWN and game.state.elapsed==0,"the first mission begins at the original fresh spawn without a position or age shortcut")
	var start: Button=find_button(game.overlay,"Hauptgeschichte beginnen")
	check(start!=null,"the actual introduction exposes the campaign-start button")
	if start==null:return false
	start.pressed.emit()
	check(game.state.main_story_status().action=="greet","the real start button opens the first actual mother greeting")
	check(walk(game,Vector2.ZERO,95,1600,true),"the wolf walks along actual navigation from spawn to the moving native mother")
	var contacts_before: int=game.state.pack_contacts
	game.interact()
	check(game.state.pack_contacts==contacts_before+1 and game.state.main_story_status().stage==1,"the normal gameplay action really greets the mother and earns the saved 1/2 checkpoint")
	return game.state.main_story_status().stage==1

func complete_first_chapter(game: Node,label: String,manual_escort: bool=false) -> void:
	game.close_overlay()
	observed_joint_seconds=0; joint_gates_safe=true; blocked_intent_ticks=0; blocked_intent_safe=true
	var age_before: float=game.state.elapsed
	var ticks_before := active_ticks
	var legacy_before: int=game.state.story_step
	var xp_before: int=game.state.xp
	var skill_before: int=game.state.skills.pack
	if manual_escort:
		game.show_pack();await process_frame;await process_frame
		var escort: Button=find_button(game.overlay,"Mit der Mutter")
		check(escort!=null and not escort.disabled,label+": real pack controls permit escort after the greeting")
		var parent_before: Vector2=mother(game).p
		if escort!=null and not escort.disabled:escort.pressed.emit()
		check(game.state.escort and mother(game).p==parent_before,label+": escort starts through its real button without moving or replacing the mother")
	else:check(not game.state.escort,label+": the first shared home arrival requires no hidden escort-menu setting")
	game.story_button.pressed.emit();await process_frame;await process_frame
	var resume: Button=find_button(game.overlay,"Zurück auf meine Reise")
	check(resume!=null,label+": the actual story footer offers a return to the unfinished home meeting")
	if resume!=null:resume.pressed.emit()
	else:game.close_overlay()
	var goal: Vector2=game.state.waypoint_pos
	check(walk(game,goal),label+": actual controller movement reaches the guided dry home meeting approach")
	print("FIRST-MISSION ARRIVAL ",label," player=",game.state.pos," goal=",game.state.main_story_status().target_pos," mother=",mother(game).p," mother_speed=",mother(game).get("speed",0))
	check(game.can_walk(game.state.pos) and game.state.pos.distance_to(game.state.main_story_status().target_pos)<125,label+": the physically reached approach satisfies the genuine player arrival radius")
	var seconds_before: float=game.state.main_story_status().seconds
	var menu_age: float=game.state.elapsed
	game.show_menu();game._process(12)
	check(game.state.main_story_status().seconds==seconds_before and game.state.elapsed==menu_age,label+": a menu cannot spend the three shared-arrival seconds or natural age")
	game.close_overlay()
	for index in range(1200):
		tick(game)
		if game.state.main_story_status().ready:break
	var status: Dictionary=game.state.main_story_status()
	print("FIRST-MISSION WAIT ",label," ready=",status.ready," seconds=",status.seconds," player_ready=",status.player_ready," companion_ready=",status.companion_ready," player=",game.state.pos," mother=",mother(game).p," speed=",mother(game).get("speed",0)," clear=",game.world._animal_motion.segment_free(game.state.pos,mother(game).p))
	check(status.ready,label+": the real moving mother settles and three active shared seconds finish the first chapter")
	check(observed_joint_seconds>=2.999 and joint_gates_safe,label+": every earned shared second has actual still bodies, mother proximity and a clear path")
	print("FIRST-MISSION HELD-STICK ",label," blocked_active_ticks=",blocked_intent_ticks," no_quiet_reward=",blocked_intent_safe)
	check(blocked_intent_ticks>0 and blocked_intent_safe,label+": a genuinely held stick blocked by terrain or a body never earns quiet mission seconds")
	check(motion_safe,label+": all mother updates stay on swept safe ground without catch-up teleports")
	check(is_equal_approx(game.state.elapsed,age_before+(active_ticks-ticks_before)*DT),label+": arrival and waiting advance only actual small active ticks, without age jumps")
	game.show_main_story();await process_frame;await process_frame
	var next: Button=find_button(game.overlay,"Das nächste Kapitel")
	check(next!=null,label+": the completed first chapter exposes its actual confirmation button")
	# Escort activation can legitimately earn the separate older achievement.
	# Measure the chapter reward at the physical confirmation, after travel.
	xp_before=game.state.xp;skill_before=game.state.skills.pack
	if next!=null:next.pressed.emit()
	check(game.state.main_story_status().chapter==1 and game.state.story_step==legacy_before,label+": the real confirmation enters the water chapter while retaining earlier memories")
	check(game.state.xp==xp_before+40 and game.state.skills.pack==mini(100,skill_before+3),label+": completing the real first chapter awards its documented reward exactly once")
	check(not game.state.advance_main_story() and game.state.xp==xp_before+40,label+": a repeated chapter claim cannot award another reward")
	game.close_overlay();check(game._save_game(),label+": the completed real controller journey saves successfully")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var fixture_only := args.has("--fixture-only")
	var baseline := args.has("--baseline-repro")
	var path := OLD_SAVE if fixture_only or baseline else FRESH_SAVE
	clean(path)
	var game: Node=await launch(path)
	var greeted := await greet_from_spawn(game)
	if not greeted:
		await dispose(game);print("Wolf first mission controller: %d checks, %d failures"%[checks,failures]);quit(1);return
	check(game._save_game(),"the actual greeting creates a real recoverable version-four 1/2 save")
	if baseline:
		game.close_overlay()
		var entrance := Vector2.ZERO
		for obj in game.world.objects:
			if obj.kind=="den" and int(obj.variant)==0:entrance=obj.p+Vector2(0,140);break
		check(entrance!=Vector2.ZERO and walk(game,entrance),"baseline controller physically walks to the visible southern home entrance")
		for index in range(300):tick(game)
		var stuck: Dictionary=game.state.main_story_status()
		print("FIRST-MISSION-09-BASELINE player=",game.state.pos," target=",stuck.target_pos," player_to_target=",game.state.pos.distance_to(stuck.target_pos)," mother=",mother(game).p," escort=",game.state.escort," seconds=",stuck.seconds," clear=",game.world._animal_motion.segment_free(game.state.pos,mother(game).p))
		check(not game.state.escort and not stuck.ready and stuck.stage==1 and stuck.seconds==0,"unchanged 0.9 reproduces the stuck 1/2 mission after actual greeting, southern arrival and active waiting")
		await dispose(game);print("Wolf first mission baseline reproduction: %d checks, %d failures"%[checks,failures]);quit(1 if failures>0 else 0);return
	if fixture_only:
		print("FIRST-MISSION-09-FIXTURE=",ProjectSettings.globalize_path(OLD_SAVE))
		await dispose(game);print("Wolf first mission controller fixture: %d checks, %d failures"%[checks,failures]);quit(1 if failures>0 else 0);return
	await complete_first_chapter(game,"fresh start",args.has("--manual-fresh"))
	await dispose(game)
	game=await launch(FRESH_SAVE);game.close_overlay()
	check(game.state.main_story_status().chapter==1 and game.state.main_story_status().stage==0,"reloading the physically completed first mission retains the water chapter instead of requiring another greeting")
	await dispose(game);clean(FRESH_SAVE)
	var recovery_source := args[args.find("--fixture")+1] if args.has("--fixture") else RECOVERY_FIXTURE
	if FileAccess.file_exists(recovery_source):
		var original := FileAccess.get_file_as_string(recovery_source)
		clean(OLD_SAVE)
		var output := FileAccess.open(ProjectSettings.globalize_path(OLD_SAVE),FileAccess.WRITE)
		output.store_string(original);output.close()
		if FileAccess.file_exists(recovery_source+".wildlife.json"):
			output=FileAccess.open(ProjectSettings.globalize_path(OLD_SAVE+".wildlife.json"),FileAccess.WRITE)
			output.store_string(FileAccess.get_file_as_string(recovery_source+".wildlife.json"));output.close()
		game=await launch(OLD_SAVE);game.close_overlay()
		check(game.state.main_story_status().stage==1 and game.state.main_story_status().chapter==0 and not game.state.escort,"the actual unchanged 0.9 save resumes its earned greeting without inventing escort or progress")
		await complete_first_chapter(game,"0.9 saved 1/2",true)
		var saved_xp: int=game.state.xp
		var saved_pack: int=game.state.skills.pack
		await dispose(game)
		game=await launch(OLD_SAVE);game.close_overlay()
		check(game.state.main_story_status().chapter==1 and game.state.main_story_status().stage==0 and game.state.xp==saved_xp and game.state.skills.pack==saved_pack,"the physically recovered 0.9 save reloads in the water chapter with exactly its earned rewards")
		await dispose(game);clean(OLD_SAVE)
	else:check(false,"the genuine 0.9 controller-produced recovery fixture is available")
	print("Wolf first mission controller: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
