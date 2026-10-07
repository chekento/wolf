extends SceneTree

var errors := 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error("FAIL: "+message)
		errors+=1
	else:print("PASS: "+message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	WolfState.save_path="user://wolf_test_state.json"
	var data := WolfWorldData
	for region in range(data.REGIONS.size()):
		var a := data.generate(region)
		var b := data.generate(region)
		check(a==b,"deterministic region %d"%region)
		for direction in data.REGIONS[region].links:
			var target: int=data.REGIONS[region].links[direction]
			var opposite: String = {"north":"south","south":"north","east":"west","west":"east"}[direction]
			check(data.REGIONS[target].links[opposite]==region,"reciprocal exit %d %s"%[region,direction])
			check(data.walkable(data.entry_point(direction),data.generate(target).objects) and not data.water_blocked(data.entry_point(direction),target),"safe arrival %d %s"%[region,direction])
	var s := WolfState.new()
	s.region=2
	s.pos=Vector2(1120,880)
	s.found.append("2:1")
	s.visited.append(2)
	s.observations.append("Reh")
	s.drank=true
	s.elapsed=198.5
	s.sites.append("2:1")
	s.story_step=2
	s.skills.nose=18
	s.escort=true
	s.waypoint_region=7
	s.waypoint_pos=Vector2(600,500)
	s.reduced_motion=true
	var path := "user://smoke-save.json"
	check(s.save_to(path),"save written")
	var restored := WolfState.new()
	check(restored.load_from(path),"save loaded")
	check(restored.sites==s.sites and restored.story_step==2 and restored.skills.nose==18 and restored.escort and restored.waypoint_pos==s.waypoint_pos and restored.reduced_motion,"new progress and preferences round trip")
	check(restored.pos==s.pos and restored.region==s.region and restored.found==s.found and restored.drank and restored.elapsed==s.elapsed,"progress round trip")
	DirAccess.remove_absolute(path)
	var old := FileAccess.open(path,FileAccess.WRITE)
	old.store_string(JSON.stringify({"version":1,"region":0,"pos":[790,970],"visited":[0,1],"found":["0:0"]}))
	old.close()
	var migrated := WolfState.new()
	check(migrated.load_from(path) and migrated.pos==data.SPAWN and migrated.visited.has(1) and migrated.found.has("0:0"),"old save migration keeps progress")
	DirAccess.remove_absolute(path)
	var version_two := FileAccess.open(path,FileAccess.WRITE)
	version_two.store_string(JSON.stringify({"version":2,"region":14,"pos":[1200,1500],"visited":[0,14],"found":["14:4"],"xp":200}))
	version_two.close()
	var retained := WolfState.new()
	check(retained.load_from(path) and retained.region==14 and retained.pos==Vector2(1200,1500) and retained.xp==200 and retained.found.has("14:4"),"0.2 save keeps region IDs and local positions")
	DirAccess.remove_absolute(path)
	var story := WolfState.new()
	check(story.choose_story(0) and story.story_step==1 and story.skills.nose==7,"natural story choice creates a memory")
	check(not story.choose_story(0) and story.story_step==1,"story cannot skip the water experience")
	story.drank=true
	check(story.choose_story(1) and story.story_step==2,"water unlocks the next chapter")
	check(not story.choose_story(9),"invalid story choice cannot advance")
	story.tick(WolfState.DAY_SECONDS*6,false,false)
	check(story.age_weeks()==16 and story.growth()<0.74,"six days do not cause abrupt aging")
	story.tick(WolfState.DAY_SECONDS,false,false)
	check(story.age_weeks()==17,"age grows after a full week")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.close_overlay()
	game.state=WolfState.new()
	game.change_region(0,data.SPAWN)
	game.sniff()
	game.state.pos=game.world.tracks[0].p
	game.interact()
	check(game.state.found.has("0:0"),"scent track interaction")
	game.state.pos=Vector2(2495,2140)
	game.interact()
	check(game.state.drank and game.state.thirst==100,"drink at bank")
	game.state.pos=Vector2(1580,2020)
	game.howl()
	game.rest()
	check(game.state.howled and game.state.rested,"pack response and rest")
	game.state.facing=Vector2.RIGHT
	game.toggle_view()
	check(game.first_person and game.world_view.camera.current and not game.map_view.visible,"switch to first person")
	check(absf(game.world_view.camera.position.x-game.state.pos.x*WolfWorldView.UNIT)<0.001,"same position in 3D")
	var forward := Vector2(-sin(game.world_view.yaw),-cos(game.world_view.yaw))
	check(forward.distance_to(game.state.facing)<0.001,"first person facing preserved")
	check(Vector2.UP.rotated(-game.world_view.yaw).distance_to(forward)<0.001,"movement follows camera direction")
	game.toggle_view()
	check(not game.first_person and game.map_view.visible,"return to 2D")
	game.state.pos=Vector2(3178,1600)
	game.move_wolf(Vector2(8,0))
	check(game.state.region==1 and game.state.pos==Vector2(55,1600),"walk through connected east exit")
	game.change_region(2,Vector2(800,1600))
	check(game.can_walk(Vector2(WolfWorldData.river_x(1600),1600)),"river ford open")
	check(not game.can_walk(Vector2(WolfWorldData.river_x(1100),1100)),"deep river blocked")
	game.scent_time=0
	for region in range(16):
		game.change_region(region,data.SPAWN)
		game.state.pos=Vector2(2180,1040)
		game.interact()
	check(game.state.visited.size()==16 and game.state.landmarks.size()==16,"exploration quest across regions")
	game.state.pos=Vector2(640,2500)
	game.interact()
	check(game.state.discoveries.has(15),"hidden nature discovery")
	game.mark_territory()
	check(game.state.marked.has(15),"persistent scent mark")
	check(game.state.xp>0 and game.state.level()>1,"experience and ranks")
	game.change_region(0,Vector2(1430,2260))
	game.interact()
	check(game.state.pack_contacts>0 and game.state.bond>40,"pack greeting")
	var reached: Array[int]=[0]
	var frontier: Array[int]=[0]
	while not frontier.is_empty():
		var current: int=frontier.pop_front()
		for target in data.REGIONS[current].links.values():
			if not reached.has(target):
				reached.append(target)
				frontier.append(target)
	check(reached.size()==64,"all 64 regions reachable without teleporting")
	# Test observation with a clear line of sight, then a blocking trunk.
	game.change_region(0,Vector2(800,800))
	game.world.animals[0].p=Vector2(800,580)
	game.world.objects=[]
	game.world_view.yaw=0
	game.world_view.pitch=-0.17
	check(game.observe() and game.state.observations.has("Reh"),"first person animal observation")
	game.state.observations.clear()
	game.world.animals=game.world.animals.slice(0,1)
	game.world.objects=[{"kind":"tree","p":Vector2(800,700),"scale":1.0,"variant":0}]
	check(not game.observe(),"tree blocks animal observation")
	var route: Array[int]=game.route_to(63)
	var previous_region: int=game.state.region
	var valid_route: bool=not route.is_empty()
	for region in route:
		valid_route=valid_route and data.REGIONS[previous_region].links.values().has(region)
		previous_region=region
	check(valid_route and route.back()==63,"atlas routes use connected region exits")
	game.state.escort=true
	game.state.bond=60
	game.change_region(1,Vector2(55,1600))
	var followers: Array=game.world.animals.filter(func(a:Dictionary):return a.get("companion",false))
	check(followers.size()==1 and followers[0].role=="Mutter" and game.can_walk(followers[0].p),"parent accompanies the wolf across region transitions")
	game.change_region(0,data.SPAWN)
	check(game.world.animals.filter(func(a:Dictionary):return a.get("companion",false)).is_empty(),"return home does not duplicate the parent")
	game.set_waypoint(0,Vector2(2220,2140))
	check(game.can_walk(game.state.waypoint_pos),"pond waypoint moves to a reachable bank")
	var animal_model := WolfAnimalModel.new()
	root.add_child(animal_model)
	animal_model.build("wolf")
	animal_model.animate(PI/2,80,"wandern",0)
	var walking_pose: float=animal_model.legs[0].rotation.x
	animal_model.animate(0,0,"ruhen",0)
	check(absf(walking_pose)>0.2 and animal_model.torso.position.y<0.5,"articulated animal changes walking and resting poses")
	animal_model.queue_free()
	var touch := InputEventScreenTouch.new()
	touch.index=4
	touch.pressed=true
	touch.position=game.stick.size*0.5+Vector2(0,-48)
	game.stick._gui_input(touch)
	check(game.stick.vector.y < -0.9,"touch stick supports north")
	touch.pressed=false
	game.stick._gui_input(touch)
	check(game.stick.vector==Vector2.ZERO and game.stick.pointer==-1,"touch stick resets on release")
	game.show_map()
	await process_frame
	var cartography: WolfCartography=game.map_panel
	var pan_before := cartography.pan
	var press := InputEventScreenTouch.new()
	press.index=3;press.pressed=true;press.position=Vector2(150,160)
	cartography._gui_input(press)
	var drag := InputEventScreenDrag.new()
	drag.index=3;drag.position=Vector2(210,160);drag.relative=Vector2(60,0)
	cartography._gui_input(drag)
	check(cartography.pan.x>pan_before.x+50,"touch dragging moves the atlas")
	press.pressed=false;press.position=Vector2(210,160);cartography._gui_input(press)
	cartography.zoom_by(100)
	check(cartography.magnification==4,"atlas zoom is bounded")
	game.close_overlay()
	game.show_story()
	await process_frame
	check(is_instance_valid(game.overlay),"story screen opens cleanly")
	game.show_pack();game.show_settings();game.show_journal()
	await process_frame
	check(is_instance_valid(game.overlay),"journal modal")
	var elapsed_before: float=game.state.elapsed
	game._process(1)
	check(game.state.elapsed==elapsed_before,"menus pause simulation")
	game.close_overlay()
	check(not is_instance_valid(game.overlay),"clean modal close")
	game.sound.stop()
	game.sound.stream=null
	game.ambient.stop()
	game.ambient.stream=null
	game.state=WolfState.new()
	DirAccess.remove_absolute(WolfState.save_path)
	root.remove_child(game)
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("Wolf smoke suite: %d failures"%errors)
	quit(1 if errors>0 else 0)
