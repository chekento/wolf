extends SceneTree

var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1
func settle() -> void:
	for i in range(5):await process_frame

func run() -> void:
	WolfState.save_path="user://wolf_family_lessons_test.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	check(WolfFamilyLessons.LESSONS.size()==6,"three meaningful lessons per parent")
	for role in ["Mutter","Vater"]:
		var options := WolfFamilyLessons.available(role,[])
		check(options.size()==3,"each adult offers three conversations and practice assignments: "+role)
	var state := WolfState.new()
	check(state.start_family_lesson("m_pack"),"mother's pack-language conversation starts measurable practice")
	check(not state.start_family_lesson("f_hunt"),"a second adult lesson cannot override active practice")
	state.note_action("greet")
	check(not state.family_lesson_status().ready,"mother's lesson is not won by speaking alone")
	check(state.family_affection("Geschwister","wolf:1","cuddle"),"close sibling cuddle rewards the pack")
	check(state.family_lesson_status().ready,"mother's family lesson needs real greeting and cuddle")
	check(not state.claim_family_lesson("Vater"),"the father cannot claim mother's finished lesson")
	check(state.claim_family_lesson("Mutter"),"mother awards completed practice with actual XP and pack points")
	check(not state.claim_family_lesson("Mutter") and not state.start_family_lesson("m_pack"),"one-time family lesson cannot pay twice")
	check(state.family_lessons_completed.size()==1 and state.pack_points>=7 and state.xp==30,"unique parent lesson and sibling affection contribute to real progression")
	check(not state.family_affection("Geschwister","wolf:1","cuddle"),"same-family cuddle has cooldown")
	state.elapsed+=17
	check(state.family_affection("Geschwister","wolf:1","cuddle"),"cuddling resumes after a real pause")
	var bond_before := state.bond
	check(state.family_affection("Vater","wolf:2","cuddle") and state.bond==bond_before+1,"parent cuddling is possible but gives less affection than sibling cuddling")
	check(not state.family_affection("Vater","wolf:2","play"),"special play is restricted to siblings")
	check(state.start_family_lesson("m_nose"),"mother opens real scent lesson")
	state.note_action("sniff");state.note_action("sniff")
	check(not state.family_lesson_status().ready,"two sniffs without a discovered trail cannot complete scent training")
	state.found.append("0:0")
	check(state.family_lesson_status().ready and state.claim_family_lesson("Mutter"),"fresh track observation completes mother's sniffing lesson")
	check(state.start_family_lesson("m_play"),"mother teaches sibling play")
	check(state.family_affection("Geschwister","wolf:1","play"),"first sibling game creates actual affection event")
	check(not state.family_lesson_status().ready,"one play session does not finish two-turn practice")
	state.elapsed+=25
	check(state.family_affection("Geschwister","wolf:1","play") and state.family_lesson_status().ready and state.claim_family_lesson("Mutter"),"two separately timed games finish mother's play lesson")
	check(state.start_family_lesson("f_path"),"father opens orientation practice")
	state.visited.append(1)
	check(not state.family_lesson_status().ready,"a new area without a scent marking is not sufficient")
	state.note_action("mark")
	check(state.family_lesson_status().ready and state.claim_family_lesson("Vater"),"actual visit plus scent mark completes orientation lesson")
	check(state.start_family_lesson("f_hunt"),"father offers tracking rather than automatic food spawning")
	state.found.append("0:1")
	check(not state.family_lesson_status().ready,"single fresh trail is not a completed hunt lesson")
	state.found.append("0:2")
	check(state.family_lesson_status().ready and state.claim_family_lesson("Vater"),"two independent tracking discoveries complete hunt preparation")
	check(state.start_family_lesson("f_mission"),"father requires a real finished encounter")
	state.completed_encounters.append("1:0:0")
	check(state.family_lesson_status().ready and state.claim_family_lesson("Vater"),"finished encounter, not an accepted one, completes father's job lesson")
	check(state.family_lessons_completed.size()==6 and WolfFamilyLessons.available("Mutter",state.family_lessons_completed).is_empty(),"all six unique lessons can be completed once")
	check(state.save_to(),"family lessons and affection can be saved")
	var restored := WolfState.new()
	check(restored.load_from() and restored.family_lessons_completed.size()==6,"completed tutorials persist through restart")
	check(restored.family_cooldowns.size()>0 and restored.pack_points==state.pack_points,"social cooldowns and pack score restore")
	var old := FileAccess.open(WolfState.save_path,FileAccess.WRITE)
	old.store_string(JSON.stringify({"version":4,"region":0,"pos":[1500,2200],"visited":[0],"xp":0}))
	old.close()
	var migrated := WolfState.new()
	check(migrated.load_from() and migrated.family_lessons_completed.is_empty() and migrated.family_lesson.is_empty(),"legacy Wolf 0.14 saves load without losing progress or invented lessons")
	var game=load("res://main.tscn").instantiate()
	game.state.sound_enabled=false
	root.add_child(game);await settle()
	game.close_overlay();game.set_process(false)
	game.state=WolfState.new()
	game.change_region(0,WolfWorldData.SPAWN)
	game.state.pos=Vector2(3000,3000)
	game._refresh_family_buttons();await settle()
	check(not game.family_cuddle_button.visible and not game.family_play_button.visible,"two added family buttons stay hidden away from the pack")
	var mother: Dictionary={}
	var father: Dictionary={}
	var sibling: Dictionary={}
	for wolf in game.world.animals:
		if wolf.kind!="wolf" or wolf.get("guardian",false):continue
		if wolf.role=="Mutter" and mother.is_empty():mother=wolf
		if wolf.role=="Vater" and father.is_empty():father=wolf
		if wolf.role=="Geschwister" and sibling.is_empty():sibling=wolf
	check(not mother.is_empty() and not father.is_empty() and not sibling.is_empty(),"family still consists of parents and real siblings")
	if not sibling.is_empty():
		game.state.pos=sibling.p+Vector2(75,0)
		game._refresh_family_buttons();await settle()
		check(game.family_cuddle_button.visible and game.family_play_button.visible and game.hud_actions_grid.columns==3,"both extra touch actions appear near siblings and folded buttons reflow")
		var points := game.state.pack_points
		game._family_play()
		check(game.state.pack_points>points and game.state.pack_signal.action=="play" and not str(game.state.pack_signal.get("target","")).is_empty(),"sibling play targets the exact wolf and awards pack points")
		game._family_cuddle()
		check(game.state.pack_signal.action=="cuddle" and game.state.action_counts.cuddle==1,"cuddle is separate physical social event with actual selected wolf")
	if not mother.is_empty():
		game.state.pos=mother.p+Vector2(70,0)
		game._refresh_family_buttons();await settle()
		check(game.family_cuddle_button.visible and not game.family_play_button.visible,"parent supports gentler cuddling but no sibling-only play")
		game.show_parent_lesson("Mutter");await settle()
		check(is_instance_valid(game.overlay),"mother speaks in a real scrollable lesson dialog when close")
		game.close_overlay()
	if not father.is_empty():
		game.state.pos=father.p+Vector2(70,0)
		game.show_parent_lesson("Vater");await settle()
		check(is_instance_valid(game.overlay),"father talks about navigation, tracks and responsible quests")
		game.close_overlay()
	game.state.pos=Vector2(3000,3000);game._refresh_family_buttons();await settle()
	check(not game.family_cuddle_button.visible and not game.family_play_button.visible,"far-away controls disappear without stealing mobile HUD space")
	game._release_audio();root.remove_child(game);game.queue_free();await settle()
	await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	state=null;restored=null;migrated=null;game=null
	WolfWildernessPaths.cache.clear();WolfWildernessPaths.recent.clear()
	print("Wolf parent lessons and family bonding: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
