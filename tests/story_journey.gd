extends SceneTree

# Exercise real player exits, companion creation, persistence and pauses.
# The only positional fixtures place the player at an existing border gate;
# movement and region changes use the same controller as normal play.
var checks := 0
var failures := 0
const SAVE := "user://wolf_story_journey.json"

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func parents(game: Node) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for animal in game.world.animals:
		if animal.kind=="wolf" and not animal.get("young",false) and animal.get("role","")=="Mutter":result.append(animal)
	return result

func cross(game: Node,direction: String) -> void:
	var positions := {"north":Vector2(1600,25),"east":Vector2(3175,1600),"south":Vector2(1600,3175),"west":Vector2(25,1600)}
	var vectors := {"north":Vector2.UP,"east":Vector2.RIGHT,"south":Vector2.DOWN,"west":Vector2.LEFT}
	game.state.pos=positions[direction];game.state.facing=vectors[direction]
	var expected: int=WolfWorldData.REGIONS[game.state.region].links[direction]
	var elapsed: float=game.state.elapsed
	game.move_wolf(vectors[direction]*12)
	check(game.state.region==expected,"walking through the %s gate enters the actual neighbor"%direction)
	check(game.can_walk(game.state.pos) and game.state.visited.has(expected),"arrival is on dry traversable ground and records the visited region")
	check(game.state.elapsed==elapsed,"a region crossing never skips age or active play time")
	var mother := parents(game)
	check(mother.size()==1,"the region contains one adult mother after crossing")
	if not mother.is_empty() and game.state.region!=0:
		check(game.can_walk(mother[0].p) and mother[0].p.distance_to(game.state.pos)<220,"the arriving escort starts on real nearby traversable ground")
	var count: int=game.world.animals.size()
	game._sync_companion();game._sync_companion()
	check(game.world.animals.size()==count and parents(game).size()==1,"repeated companion synchronization cannot duplicate the parent")

func clean() -> void:
	for path in [SAVE,SAVE+".pending",SAVE+".wildlife.json",SAVE+".wildlife.json.pending"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)

func dispose(game: Node) -> void:
	game._release_audio();await create_timer(.15).timeout
	root.remove_child(game);game.queue_free();await process_frame

func run() -> void:
	WolfState.save_path=SAVE;clean()
	var game = load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game);game.set_process(false);await process_frame
	game.close_overlay();game.set_process(false)
	check(game.state.region==0 and game.can_walk(game.state.pos),"a new offline game starts safely at the original home spawn")
	game._begin_main_story()
	var home_parent := parents(game)
	if home_parent.is_empty():check(false,"the home contains a real mother before the story greeting");await dispose(game);clean();quit(1);return
	game.state.pos=home_parent[0].p;game.interact()
	check(game.state.main_story_status().action=="joint" and game.state.pack_contacts==1,"greeting the actual mother advances the campaign through the normal gameplay action")
	game.state.escort=true;game._sync_companion()
	game.state.elapsed=WolfState.DAY_SECONDS*2+77
	game.state.story_step=1;game.state.story_choices.append("Neben der Familie ruhen")
	game.state.found.append("0:0")
	game.state.waypoint_region=3;game.state.waypoint_pos=Vector2(1700,1500)
	cross(game,"north");cross(game,"east")
	for i in range(40):game._tick_main_story(.1)
	check(game.state.main_story_status().stage==1 and game.state.main_story_status().seconds==0,"traveling with the mother cannot complete the still-required home meeting remotely")
	var saved_region: int=game.state.region
	var saved_pos: Vector2=game.state.pos
	var saved_elapsed: float=game.state.elapsed
	var animal_key := ""
	var animal_pos := Vector2.ZERO
	for animal in game.world.animals:
		if not animal.get("companion",false):
			animal_key=WolfPackLife.animal_key(animal);animal_pos=animal.p;break
	check(game._save_game(),"the traveling player and actual wildlife cache save successfully")
	check(not FileAccess.file_exists(SAVE+".pending") and not FileAccess.file_exists(SAVE+".wildlife.json.pending"),"both atomic save transactions finish without pending files")
	await dispose(game)
	game=load("res://main.tscn").instantiate();root.add_child(game);game.set_process(false);await process_frame
	game.close_overlay();game.set_process(false)
	check(game.state.region==saved_region and game.state.pos.is_equal_approx(saved_pos),"a fresh process resumes the journey in its actual saved region and position")
	check(game.state.escort and parents(game).size()==1,"resuming outside home restores exactly one real escort")
	check(game.state.elapsed==saved_elapsed and game.state.story_step==1 and game.state.found.has("0:0"),"resuming preserves gradual age, earlier memories and collected tracks")
	check(game.state.main_story_status().chapter==0 and game.state.main_story_status().stage==1 and game.state.main_story_status().started,"campaign greeting progress survives a real journey save without replacing earlier memories")
	check(not game.state.main_story_status().player_ready and not game.state.main_story_status().companion_ready,"a fresh process does not restore stale live campaign proximity")
	check(game.state.waypoint_region==3 and game.state.waypoint_pos==Vector2(1700,1500),"a personal map destination survives the traveling save")
	var restored_wildlife := false
	for animal in game.world.animals:
		if WolfPackLife.animal_key(animal)==animal_key and animal.p.is_equal_approx(animal_pos):restored_wildlife=true
	check(restored_wildlife,"actual wildlife identity and position survive the region reload")
	game.show_menu();game._process(60)
	check(game.state.elapsed==saved_elapsed,"menu planning pauses the journey and natural aging")
	game._tick_main_story(60)
	check(game.state.main_story_status().stage==1 and game.state.main_story_status().seconds==0,"menu planning cannot spend time on the campaign home meeting")
	game.close_overlay();game._notification(Node.NOTIFICATION_APPLICATION_PAUSED);game._process(60)
	check(game.app_idle and game.state.elapsed==saved_elapsed,"Android background pause cannot advance journey time")
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED);game._process(.05)
	check(not game.app_idle and is_equal_approx(game.state.elapsed,saved_elapsed+.05),"foreground play resumes by the actual small active frame without catching up background time")
	cross(game,"south");cross(game,"west")
	var returned_parent := parents(game)
	check(game.state.region==0 and returned_parent.size()==1 and not returned_parent[0].get("companion",false),"returning home reunites with the native mother instead of adding a duplicate escort")
	game.state.escort=false;game._sync_companion();cross_without_parent(game)
	await dispose(game);clean()
	print("Wolf story journey: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)

func cross_without_parent(game: Node) -> void:
	game.state.pos=Vector2(3175,1600);game.state.facing=Vector2.RIGHT;game.move_wolf(Vector2(12,0))
	var companions := 0
	for animal in game.world.animals:
		if animal.get("companion",false):companions+=1
	check(game.state.region==1 and companions==0,"ending escort before departure leaves exploration independent")
