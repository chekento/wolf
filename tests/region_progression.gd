extends SceneTree

var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1
func settle() -> void:
	for i in range(4):await process_frame

func run() -> void:
	WolfState.save_path="user://wolf_region_pass_tests.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var sectors := {}
	var total_links := 0
	for i in range(WolfWorldData.REGIONS.size()):
		var zone := WolfRegionGates.zone(i)
		sectors[zone]=int(sectors.get(zone,0))+1
		for d in WolfWorldData.REGIONS[i].links:
			total_links+=1
			var j: int=WolfWorldData.REGIONS[i].links[d]
			var reverse: String={"north":"south","south":"north","west":"east","east":"west"}[d]
			check(WolfWorldData.REGIONS[j].links.get(reverse,-1)==i,"regional exit remains reciprocal")
			check(WolfRegionGates.border_open(WolfWorldData.REGIONS[i].coord,WolfWorldData.REGIONS[j].coord),"all exits obey narrowed physical map topology")
	check(sectors.size()==9,"the world contains nine coherent large sectors")
	check(total_links<720 and total_links>375,"inter-region chokepoints replace the fully connected 16x16 mesh")
	check(WolfWorldData.REGIONS[14].links.size()==2 and WolfWorldData.REGIONS[14].links.has("west") and WolfWorldData.REGIONS[14].links.has("east"),"the human village has one west entrance and one east exit")
	check(WolfWorldData.REGIONS[15].links.size()==2,"the area behind the village cannot be entered from the north or south")
	var reached: Dictionary={0:true}
	var frontier: Array[int]=[0]
	while not frontier.is_empty():
		var current: int=frontier.pop_front()
		for destination in WolfWorldData.REGIONS[current].links.values():
			if not reached.has(destination):
				reached[destination]=true;frontier.append(destination)
	check(reached.size()==256,"all 256 areas are structurally connected once required items are collected")
	var fresh := WolfState.new()
	check(not fresh.can_enter_region(WolfWorldData.index_at(Vector2i(7,4))),"snow zone is blocked before collecting the required pass")
	check(fresh.can_enter_region(1),"original central home area remains open")
	check(fresh.collect_region_item("frostfeder") and fresh.can_enter_region(WolfWorldData.index_at(Vector2i(7,4))),"earning the frost feather opens the entire northern sector")
	check(not fresh.collect_region_item("frostfeder"),"a pass cannot be awarded twice")
	fresh.region_items.append("invalid item")
	var saved := fresh.save_to()
	var loaded := WolfState.new()
	check(saved and loaded.load_from() and loaded.region_items.has("frostfeder") and not loaded.region_items.has("invalid item"),"new inventory saves, restores and validates through save v4")
	var game=load("res://main.tscn").instantiate()
	game.state.sound_enabled=false
	root.add_child(game);await settle()
	game.close_overlay();game.set_process(false)
	game.state=WolfState.new()
	game.change_region(0,WolfWorldData.SPAWN)
	var north: int=WolfWorldData.index_at(Vector2i(7,5))
	game.change_region(north,Vector2(1600,80))
	var blocked_target: int=WolfWorldData.REGIONS[north].links.get("north",-1)
	check(blocked_target>=0 and WolfRegionGates.requires(blocked_target)=="frostfeder","selected north gateway leads into the locked frost province")
	game.state.pos=Vector2(1600,17)
	game.move_wolf(Vector2(0,-25))
	check(game.state.region==north,"physical wolf movement cannot cross the locked pass")
	game.state.collect_region_item("frostfeder")
	game.state.pos=Vector2(1600,17)
	game.move_wolf(Vector2(0,-25))
	check(game.state.region==blocked_target,"equipped regional item unlocks actual physical passage")
	game.state=WolfState.new()
	game.change_region(2,Vector2(1380,2025))
	var food: Dictionary={}
	for obj in game.world.objects:
		if obj.kind=="food":food=obj;break
	check(not food.is_empty() and not game.state.food_visible(food),"forage is hidden outside the tutorial region")
	if not food.is_empty():
		game.state.pos=food.p
		game.sniff()
		check(game.state.food_visible(food),"scent search physically reveals a local cached food source")
		game.state.hunger=40
		game.interact()
		check(game.state.hunger>40,"food needs actual search and interaction before feeding")
	var person := {"p":Vector2(1400,1600),"facing":Vector2.RIGHT}
	check(WolfVillageStealth.sees(person,Vector2(1580,1600),false,[]),"human patrol sees wolf inside forward cone")
	check(not WolfVillageStealth.sees(person,Vector2(1220,1600),false,[]),"human cannot detect the wolf from behind")
	check(not WolfVillageStealth.sees(person,Vector2(1750,1600),true,[],30),"slow sneaking reduces effective sight radius")
	check(not WolfVillageStealth.sees(person,Vector2(1580,1600),false,[{"kind":"house","p":Vector2(1510,1600),"scale":1}]),"actual building walls occlude guard vision")
	game.change_region(14,Vector2(145,1600))
	check(WolfWorldData.REGIONS[14].biome=="village","village uses human passage and houses")
	var exposed := WolfVillageStealth.guards(0)[0]
	game.state.pos=exposed.p+exposed.facing*90
	game.clock=0
	game.sneak_button.button_pressed=false
	game.player_speed=120
	for i in range(5):game._check_human_patrols(.13)
	check(game.state.pos==WolfVillageStealth.START,"sustained detection resets the wolf to the village entrance")
	game.change_region(15,Vector2(55,1600))
	check(game.state.village_cleared and game.state.region_items.has("dorfpass"),"surviving the human passage awards the exclusive eastern pass")
	var pass_count: int=game.state.region_items.size()
	game.change_region(14,Vector2(3145,1600))
	game.change_region(15,Vector2(55,1600))
	check(game.state.region_items.size()==pass_count,"crossing the village again cannot farm rewards")
	game.state=WolfState.new()
	game.state.found=["0:0","0:1","0:2","0:3","0:4","0:5"]
	game.state.distance_walked=1900
	check(WolfRegionGates.trial_ready(WolfRegionGates.ITEMS[1],game.state.found.size(),game.state.distance_walked),"real Fährten and travel can unlock a medium scent trial")
	game.start_gate_trial(1)
	check(game.active_gate_trial==1 and game.gate_trial_stage==0,"eligible scent trial opens at its first puzzle")
	for step in range(3):
		var q: Dictionary=WolfRegionGates.question(1,step)
		game.answer_gate_trial(int(q.correct))
	check(game.state.region_items.has("frostfeder") and game.active_gate_trial==-1,"three consecutive correct scent decisions award one real item")
	game.close_overlay()
	game._release_audio();root.remove_child(game);game.queue_free()
	await settle()
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf region progression: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
