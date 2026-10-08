extends SceneTree

var failures := 0
var checks := 0

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

func choose(game: Node,task: String) -> bool:
	game.state.active_encounter={}
	game.state.food_cooldown=0
	for serial in range(150):
		game.state.encounter_serial=serial
		if game.state.encounter_status().task==task:return true
	return false

func run() -> void:
	WolfState.save_path="user://wolf_encounter_controls.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var game = load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game)
	await process_frame
	game.close_overlay();game.set_process(false)
	if game.stick==null:check(false,"game starts before encounter controls");quit(1);return
	check(choose(game,"care_route"),"a real local care journey is available")
	game.show_encounter();await process_frame;await process_frame
	var accept := find_button(game.overlay,"Diesem Duft")
	check(accept!=null and accept.global_position.y+accept.size.y<game.ui.size.y-60,"encounter start action is visible before the long story")
	if accept!=null:accept.pressed.emit()
	check(not is_instance_valid(game.overlay) and game.state.active_encounter.task=="care_route","accepting the care journey returns to real outdoor play")
	game.state.pos=game.state.waypoint_pos;game.interact();game._refresh_encounter_guide()
	check(game.state.active_encounter.get("care_drink",false) and game.state.waypoint_pos==game.state.encounter_status().target_pos,"actual drinking advances guidance to the chosen food source")
	game.state.pos=game.state.waypoint_pos;game.interact();game._refresh_encounter_guide()
	check(game.state.active_encounter.get("care_feed",false),"actual feeding at the chosen food source advances the care journey")
	game.state.pos=game.state.waypoint_pos;game.rest_cooldown=0
	check(game.context_action()=="Ruhen","care guidance offers rest at the protected third step")
	game.interact()
	check(game.state.encounter_status().done and game.state.active_encounter.get("care_rest",false),"the context action completes actual drink, feed and protected rest in order")
	game.show_encounter();await process_frame;await process_frame
	var reward := find_button(game.overlay,"Die Erfahrung mitnehmen")
	check(reward!=null and reward.global_position.y+reward.size.y<game.ui.size.y-60,"completed encounter reward is visible without scrolling")
	var completed_before: int=game.state.completed_encounters.size()
	if reward!=null:reward.pressed.emit()
	check(game.state.completed_encounters.size()==completed_before+1 and not game.state.complete_encounter(),"the new encounter menu claims its reward exactly once")
	game.close_overlay()
	check(choose(game,"site_mark"),"a local nature-place and scent journey is available")
	game.state.begin_encounter();game.guide_encounter()
	game.state.pos=game.state.waypoint_pos
	check(game.context_action()=="Ort prüfen","the selected nature inspection takes priority near a protected den")
	game.interact()
	check(game.state.active_encounter.get("site_checked",false),"actual inspection marks the chosen nature place as checked")
	check(game.context_action()=="Duft setzen","the next nature-place step appears directly on the gameplay action")
	game.interact()
	check(game.state.encounter_status().done and game.state.active_encounter.get("site_marked",false),"the actual contextual scent mark completes the second step at that place")
	game.state=WolfState.new();game.state.sound_enabled=false
	game.state.pos=Vector2(1600,1800)
	check(choose(game,"quiet_watch"),"a quiet wildlife observation is available")
	game.state.begin_encounter()
	var species: String=game.state.active_encounter.detail
	var kind: String={"Reh":"deer","Hase":"rabbit","Fuchs":"fox"}[species]
	var animal := {"kind":kind,"p":Vector2(1600,1580),"home":Vector2(1600,1580),"phase":0.0,"mood":"lauschen","alarm":0.0,"facing":Vector2.UP,"speed":0.0,"gait":0.0}
	game.world.animals=[animal];game.world.objects=[]
	if not game.first_person:game.toggle_view()
	game.world_view.yaw=0;game.world_view.pitch=-.14;game.player_speed=0
	game._tick_wildlife_observation(.1)
	check(float(game.state.active_encounter.get("watch_seconds",0))==0,"looking alone cannot start a quiet observation before the real observe action")
	check(game.observe() and game.state.active_encounter.get("watch_started",false),"the real observation action opens the quiet-view gate")
	for i in range(20):game._tick_wildlife_observation(.1)
	var watched: float=game.state.active_encounter.watch_seconds
	check(watched>1.9 and watched<2.1,"visible still wildlife accumulates actual short observation ticks")
	game.world_view.yaw=PI;game._tick_wildlife_observation(.1)
	check(game.state.active_encounter.watch_seconds==watched,"looking away from the selected animal stops observation time")
	game.world_view.yaw=0
	game.world.objects=[{"kind":"tree","p":Vector2(1600,1690),"scale":1.0,"variant":0}]
	game._tick_wildlife_observation(.1)
	check(game.state.active_encounter.watch_seconds==watched,"a real trunk between wolf and animal stops observation time")
	game.world.objects=[];game.player_speed=20;game.sneak_button.button_pressed=true
	game._tick_wildlife_observation(.1)
	check(game.state.active_encounter.watch_seconds==watched,"slow sneaking movement still cannot substitute for standing observation")
	game.player_speed=0;game.sneak_button.button_pressed=false
	game.show_menu();game._process(20)
	check(game.state.active_encounter.watch_seconds==watched,"menu planning never counts as wildlife observation")
	game.close_overlay();game.toggle_view();game._tick_wildlife_observation(.1)
	check(game.state.active_encounter.watch_seconds==watched,"returning to the overhead view stops the observation timer")
	game.toggle_view();game.world_view.yaw=0;game.world_view.pitch=-.14
	game._tick_wildlife_observation(10)
	check(game.state.active_encounter.watch_seconds<watched+.11,"a long stalled frame cannot fulfil many observation seconds at once")
	for i in range(100):game._tick_wildlife_observation(.1)
	check(game.state.encounter_status().done,"twelve real visible quiet seconds complete the new observation")
	game._release_audio();await create_timer(.2).timeout
	root.remove_child(game);game.queue_free()
	await process_frame;await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf encounter controls suite: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
