extends SceneTree

var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,msg: String) -> void:
	checks+=1
	if ok:print("PASS: "+msg)
	else:push_error("FAIL: "+msg);failures+=1
func settle() -> void:
	for i in range(5):await process_frame
func count_kind(game: Node,key: String,kind: String) -> int:
	var result := 0
	for item in game.world[key]:
		var matching: bool=bool(item.get("guardian",false)) if kind=="guardian" else str(item.get("kind",""))==kind
		if matching:result+=1
	return result

func run() -> void:
	WolfState.save_path="user://wolf_guardian_collection_tests.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	for sector in range(9):
		var home := WolfGuardianLore.home_region(sector)
		var relic := WolfGuardianLore.relic_region(sector)
		check(home>=0 and relic>=0 and home!=relic,"sector %d has a distinct guardian home and relic square"%sector)
		check(WolfRegionGates.zone(home)==sector and WolfRegionGates.zone(relic)==sector,"sector %d keeps the unique quest completely within its territory"%sector)
		check(not WolfGuardianLore.data(sector).token.is_empty(),"sector %d offers a specific named one-off find"%sector)
	var every_quest := WolfState.new()
	for sector in range(9):
		check(every_quest.meet_guardian(sector) and every_quest.accept_guardian_quest(sector) and every_quest.take_guardian_relic(sector) and every_quest.complete_guardian_quest(sector),"the nine distinct state-machine quests each permit one and only one delivery")
	check(every_quest.guardian_completed.size()==9 and every_quest.guardian_met.size()==9 and every_quest.provisions==8 and every_quest.tonics==5,"every chief offers its own stable reward without repeats")
	var saved_state := WolfState.new()
	saved_state.region=2
	saved_state.visited=[0,1,2,3]
	check(saved_state.unreported_regions().size()==3,"new discoveries remain pending away from home")
	check(saved_state.report_discoveries()==0,"wild provinces cannot grant pack homecoming rewards")
	saved_state.region=0
	check(saved_state.report_discoveries()==3 and saved_state.pack_points==30 and saved_state.xp==36,"all new squares award pack points and real xp exactly once")
	check(saved_state.report_discoveries()==0 and saved_state.pack_points==30,"returning again never re-awards previously reported discoveries")
	check(saved_state.meet_guardian(4) and not saved_state.meet_guardian(4),"one collectible encounter per special animal")
	check(not saved_state.accept_guardian_quest(5) and saved_state.accept_guardian_quest(4),"only actually met guardian can start its quest")
	check(not saved_state.take_guardian_relic(5) and saved_state.take_guardian_relic(4),"only accepted unique relic can enter inventory")
	check(saved_state.complete_guardian_quest(4) and saved_state.tonics==1,"delivering relic awards proper tonic exactly once")
	check(not saved_state.complete_guardian_quest(4) and saved_state.tonics==1,"no repeated potion farming")
	saved_state.energy=20;saved_state.thirst=50
	check(saved_state.consume_tonic() and saved_state.energy==75 and saved_state.thirst==80 and saved_state.tonics==0,"potion consumes inventory and restores actual needs")
	check(not saved_state.consume_tonic(),"empty inventory cannot restore needs")
	check(saved_state.meet_guardian(7) and saved_state.accept_guardian_quest(7) and saved_state.take_guardian_relic(7) and saved_state.complete_guardian_quest(7),"the food-reward guardian quest is also finishable")
	check(saved_state.provisions==2,"completed food quest awards two stored provisions")
	saved_state.hunger=30
	check(saved_state.consume_provision() and saved_state.hunger==75 and saved_state.provisions==1,"provisions are spendable and never conjure extra food")
	check(saved_state.save_to(),"new collection inventory is saved")
	var restored := WolfState.new()
	check(restored.load_from() and restored.reported_regions.size()==4 and restored.pack_points==30,"reported map cells and pack score persist")
	check(restored.guardian_met.has(4) and restored.guardian_met.has(7) and restored.guardian_completed.has(4) and restored.guardian_completed.has(7),"main animal collection and completed quests persist")
	check(restored.provisions==1 and restored.tonics==0,"unique quest rewards persist correctly")
	var old_file := FileAccess.open(WolfState.save_path,FileAccess.WRITE)
	old_file.store_string(JSON.stringify({"version":4,"region":2,"pos":[1050,2000],"visited":[0,2,3],"xp":30}))
	old_file.close()
	var migrated := WolfState.new()
	check(migrated.load_from() and migrated.reported_regions.size()==3 and migrated.unreported_regions().is_empty(),"old 0.13 saves migrate without retroactive unearned rewards")
	var game=load("res://main.tscn").instantiate()
	game.state.sound_enabled=false
	root.add_child(game);await settle()
	game.close_overlay();game.set_process(false)
	game.state=WolfState.new()
	for sector in [4]:
		var home: int=WolfGuardianLore.home_region(sector)
		game.change_region(home,WolfGuardianLore.home_pos(sector))
		check(count_kind(game,"animals","guardian")==1,"exactly one static chief NPC in sector %d"%sector)
		game._sync_guardian_entities()
		check(count_kind(game,"animals","guardian")==1,"cached area reload does not duplicate guardian %d"%sector)
		check(game._interact_guardian() and game.state.guardian_met.has(sector),"physically meeting sector %d chief adds it to collection"%sector)
		game.close_overlay();await settle()
		check(game.state.accept_guardian_quest(sector),"sector %d grants its own unique search task"%sector)
		var relic_region: int=WolfGuardianLore.relic_region(sector)
		game.change_region(relic_region,WolfGuardianLore.relic_pos(sector))
		check(count_kind(game,"objects","guardian_relic")==1,"sector %d has exactly one collectible relic in separate map square"%sector)
		check(game._collect_guardian_relic() and game.state.guardian_relics.has(sector),"relic in sector %d can be picked up once"%sector)
		check(count_kind(game,"objects","guardian_relic")==0,"collected relic cannot respawn locally")
		game.change_region(home,WolfGuardianLore.home_pos(sector))
		check(game.state.complete_guardian_quest(sector),"relic delivery to sector %d completes unique assignment"%sector)
		check(not game.state.complete_guardian_quest(sector),"sector %d cannot be farmed repeatedly"%sector)
	check(game.state.guardian_met.size()==1 and game.state.guardian_completed.size()==1,"actual in-world NPC encounter, unique find and hand-in complete without duplication")
	game.state.visited=[0,1,2]
	game.state.reported_regions=[0]
	game.change_region(0,Vector2(900,900))
	game.clock=50
	game._maybe_pack_welcome()
	check(game.state.pack_points==0,"family does not celebrate while wolf is away from its den")
	game.state.pos=Vector2(1580,1940)
	game._maybe_pack_welcome()
	check(game.state.pack_points==20 and game.pack_celebration_until>game.clock and game.state.unreported_regions().is_empty(),"actual return near pack launches visible celebration and scores two maps")
	game._maybe_pack_welcome()
	check(game.state.pack_points==20,"repeat proximity creates no additional pack points")
	game._release_audio();root.remove_child(game);game.queue_free();await settle()
	game=null
	saved_state=null;restored=null;migrated=null;every_quest=null
	WolfWildernessPaths.cache.clear()
	WolfWildernessPaths.recent.clear()
	await create_timer(.25).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf guardian collection: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
