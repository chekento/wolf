extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1
func find_button(node: Node,prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):return node
	for child in node.get_children():
		var found := find_button(child,prefix)
		if found!=null:return found
	return null
func checkpoint(game: Node,chapter: int,stage: int) -> void:
	var complete: Array=[]
	for i in range(chapter):complete.append(WolfMainStory.chapters()[i].id)
	game.state.main_story_progress=WolfMainStory.restored({"version":1,"started":true,"chapter":chapter,"stage":stage,"completed_chapters":complete})
	var story: Dictionary=game.state.main_story_status()
	game.change_region(int(story.target_region),story.target_pos)
	game.state.pos=story.target_pos;game.state.escort=true;game._sync_companion()
	for animal in game.world.animals:
		if animal.kind=="wolf" and animal.get("role","")=="Mutter":animal.p=game.state.pos+Vector2(60,0);animal.speed=0
func run() -> void:
	WolfState.save_path="user://wolf_story_controls.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var game = load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game)
	await process_frame
	game.set_process(false);game.close_overlay()
	game.story_button.pressed.emit()
	await process_frame;await process_frame
	var start := find_button(game.overlay,"Die Reise beginnen")
	check(start!=null,"footer opens the new main-story menu")
	check(start!=null and start.global_position.y+start.size.y<game.ui.size.y-60,"story start is visible above the long chapter plan")
	if start!=null:start.pressed.emit()
	check(game.state.main_story_status().started and not is_instance_valid(game.overlay),"beginning the campaign returns to actual outdoor play")
	check(game.state.story_step==0 and game.state.story_scenes().size()==18,"all original memories survive independently")
	check(game.state.waypoint_region==0,"campaign sets a real local scent goal")
	game.show_main_story();await process_frame;await process_frame
	var resume := find_button(game.overlay,"Zurück auf meine Reise")
	check(resume!=null and resume.global_position.y+resume.size.y<game.ui.size.y-60,"active campaign resume is immediately visible")
	var elapsed: float=game.state.elapsed
	var before: String=JSON.stringify(game.state.main_story_progress)
	game._tick_main_story(5)
	check(game.state.elapsed==elapsed and JSON.stringify(game.state.main_story_progress)==before,"open campaign menu cannot earn physical mission time")
	game.close_overlay()
	game.set_waypoint(1,Vector2(1500,1500));game._refresh_main_story_guide()
	check(game.state.waypoint_region==1 and game.guided_main_story.is_empty(),"personal atlas destination is not overwritten by campaign guidance")
	game.guide_main_story()
	var mother: Dictionary={}
	for animal in game.world.animals:
		if animal.kind=="wolf" and animal.get("role","")=="Mutter":mother=animal;break
	check(not mother.is_empty(),"campaign starts with the actual mother model")
	if not mother.is_empty():
		game.state.pos=mother.p+Vector2(0,70);game.last_pack_visit=-30
		game.interact()
		check(game.state.main_story_status().stage>0,"actual nearby mother greeting progresses the first physical step")
	game.show_main_story()
	var legacy := find_button(game.overlay,"Rudelerinnerungen")
	check(legacy!=null,"campaign retains a visible route to the original stories")
	if legacy!=null:legacy.pressed.emit()
	check(find_button(game.overlay,"Rudelerinnerungen")==null,"original memory menu opens separately")
	game.close_overlay();game.show_menu()
	check(find_button(game.overlay,"Hauptgeschichte")!=null,"main menu prominently opens the campaign")
	game.close_overlay()
	game.close_overlay()
	checkpoint(game,1,1)
	check(game.context_action()=="Trinken","selected mission water precedes mother greeting")
	game.interact()
	check(game.state.main_story_status().ready and game.state.thirst==100,"actual drinking completes the selected water step beside mother")
	checkpoint(game,2,0)
	check(game.context_action()=="Ort prüfen","exact mission site precedes mother greeting")
	game.interact()
	check(game.state.main_story_status().stage==1,"actual selected discovery advances the mission beside mother")
	checkpoint(game,2,2)
	check(game.context_action()=="Duft setzen","mission scent mark is reachable beside mother")
	game.interact()
	check(game.state.main_story_status().ready,"actual scent action completes the mission step")
	checkpoint(game,3,1)
	var track_id: String=game.state.main_story_status().track_id
	game.state.found.append(track_id);game.scent_time=10
	var nose: int=game.state.skills.nose
	var tracks: int=game.state.found.size()
	check(game.context_action()=="Spur lesen","a previously found exact mission track remains readable")
	game.interact()
	check(game.state.main_story_status().stage==2,"rereading the actual exact track advances the campaign")
	check(game.state.skills.nose==nose and game.state.found.size()==tracks,"rereading a known mission track cannot duplicate rewards")
	checkpoint(game,4,0)
	game.first_person=true;game.world_view.visible=true;game.map_view.visible=false
	game.state.pos=Vector2(1600,1800);game.player_speed=0;game.world_view.yaw=0;game.world_view.pitch=-.14
	var deer: Dictionary={"kind":"deer","p":Vector2(1600,1540),"home":Vector2(1600,1540),"phase":.0,"mood":"lauschen","attention":0.0,"alarm":0.0,"speed":0.0,"facing":Vector2.LEFT}
	game.world.animals=[deer];game.world.objects=[]
	check(game.observe() and game.state.main_story_status().watch_started,"actual 3D observe locks a real quiet deer")
	game._tick_main_story(.1)
	var earned: float=game.state.main_story_status().seconds
	check(earned>0,"actual unobstructed quiet view earns active seconds")
	game.world.objects=[{"kind":"rock","p":Vector2(1600,1680),"scale":1.0,"variant":0}]
	check(game.observation_candidate(true).is_empty(),"real intervening rock blocks the story observation candidate")
	game._tick_main_story(.1)
	check(game.state.main_story_status().seconds==earned,"blocked LOS cannot earn campaign time")
	game.world.objects=[];game.player_speed=20;game._tick_main_story(.1)
	check(game.state.main_story_status().seconds==earned,"moving player cannot earn quiet campaign time")
	game.player_speed=0;game.app_idle=true;game._tick_main_story(.1)
	check(game.state.main_story_status().seconds==earned,"background state pauses actual campaign ticking")
	game.app_idle=false;game.show_main_story();game._tick_main_story(.1)
	check(game.state.main_story_status().seconds==earned,"mission menu pauses actual observation time")
	game.close_overlay()
	deer.home=Vector2(1640,1540)
	check(game.observation_candidate(true).is_empty(),"a different deer identity cannot replace the accepted individual")
	checkpoint(game,7,1)
	game.rest_cooldown=0
	check(game.context_action()=="Ruhen","cave rest action precedes nearby mother greeting")
	game.interact()
	check(game.player_mood=="ruhen" and game.state.main_story_status().action=="rest_wait","actual rest enters the resting animation and final timed step")
	game.world.objects=[]
	var navigation := WolfAnimalMotion.new();navigation.configure(0,[]);game.world._animal_motion=navigation
	for i in range(40):game._tick_main_story(.1)
	check(game.state.main_story_status().ready,"four real quiet resting seconds beside mother complete the final chapter")
	check(game.state.advance_main_story() and not game.state.advance_main_story(),"final chapter reward can be claimed exactly once")
	game.state.save_to()
	var restored := WolfState.new()
	check(restored.load_from() and restored.main_story_status().started,"campaign survives an actual save and reload")
	check(restored.story_step==game.state.story_step,"campaign save preserves legacy story progress")
	game._release_audio();root.remove_child(game);game.queue_free()
	await process_frame;await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf main-story controls: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
