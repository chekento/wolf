extends SceneTree

var failures := 0
var checks := 0

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func _initialize() -> void:call_deferred("run")

func button_named(node: Node,prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):return node
	for child in node.get_children():
		var found := button_named(child,prefix)
		if found!=null:return found
	return null

func safe_route(motion: WolfAnimalMotion,points: PackedVector2Array) -> bool:
	if points.size()<2:return false
	for i in range(1,points.size()):
		if not motion.segment_free(points[i-1],points[i]):return false
	return true

func touch(panel: WolfCartography,index: int,position: Vector2,pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index=index;event.position=position;event.pressed=pressed
	panel._gui_input(event)

func drag(panel: WolfCartography,index: int,position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index=index;event.position=position
	panel._gui_input(event)

func run() -> void:
	var motion := WolfAnimalMotion.new()
	motion.configure(0,[{"kind":"rock","p":Vector2(1500,1600),"scale":4.0,"variant":0}])
	var guide := WolfTrailNavigation.new();guide.configure(0,motion)
	var points := guide.route(Vector2(1260,1600),Vector2(1780,1600),0)
	check(safe_route(motion,points) and WolfTrailNavigation.length(points)>520,"atlas route takes a swept safe detour around the boulder")
	check(points[0]==Vector2(1260,1600) and points[-1]==Vector2(1780,1600),"route connects the actual wolf and selected goal")
	var graph: AStar2D=motion.navigation
	var before := guide.builds
	guide.route(Vector2(1270,1600),Vector2(1780,1600),0.2)
	check(guide.builds==before and motion.navigation==graph,"nearby progress reuses one route and regional graph")
	var replanned := guide.route(Vector2(1260,1670),Vector2(1780,1600),0.4)
	check(guide.builds==before+1 and safe_route(motion,replanned),"leaving a drawn route replans from the actual new location")
	var river := WolfAnimalMotion.new();river.configure(2,[])
	guide.configure(2,river)
	var crossing := guide.route(Vector2(740,1120),Vector2(1280,1120),1)
	var used_bridge := false
	for point in crossing:
		if absf(point.x-WolfWorldData.river_x(point.y))<78:used_bridge=true
	check(used_bridge and safe_route(river,crossing) and WolfTrailNavigation.length(crossing)>600,"a river route crosses a real bridge and counts the longer walk")
	var coast := WolfAnimalMotion.new();coast.configure(12,[])
	guide.configure(12,coast)
	var coastal := guide.route(Vector2(700,1200),Vector2(20,1600),2)
	check(safe_route(coast,coastal) and coastal[-1]==Vector2(20,1600),"the coast exit uses the dry sand crossing rather than deep coastal water")
	check(guide.route(Vector2(100,100),Vector2(600,100),3).is_empty(),"an invalid water start does not fabricate a safe route")
	WolfState.save_path="user://wolf_atlas_expansion.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var game = load("res://main.tscn").instantiate()
	game.state.sound_enabled=false
	root.add_child(game)
	await process_frame
	game.close_overlay();game.set_process(false)
	if game.stick==null:check(false,"game starts before atlas checks");quit(1);return
	game.state.sound_enabled=false
	game.show_travel_help()
	var water := button_named(game.overlay,"Zum festen Trinkufer")
	check(water!=null,"survival guide exposes a real water action")
	if water!=null:water.pressed.emit()
	check(not is_instance_valid(game.overlay) and game.state.waypoint_region==game.state.region,"a resource selection returns to gameplay with a saved local goal")
	game.state.pos=game.state.waypoint_pos
	game.interact()
	check(game.state.action_counts.drink==1 and game.can_walk(game.state.pos),"water guidance reaches safe ground in the real drinking radius")
	game.show_travel_help()
	button_named(game.overlay,"Einen geschützten").pressed.emit()
	game.state.pos=game.state.waypoint_pos;game.rest_cooldown=0
	game.rest()
	check(game.state.action_counts.rest==1,"rest guidance reaches a protected place usable by the real rest action")
	game.state.food_cooldown=0
	game.guide_resource("food")
	game.state.pos=game.state.waypoint_pos;game.interact()
	check(game.state.action_counts.feed==1,"food guidance reaches an actual usable food site")
	game.state.pos=WolfWorldData.SPAWN
	game.show_map()
	await process_frame;await process_frame
	check(game.map_places.get_child_count()==WolfWorldData.SITES_PER_REGION+1,"known region has a complete selectable nature-place list")
	var first_site: Dictionary=WolfWorldData.nature_sites(0)[0]
	button_named(game.map_places,"○  "+first_site.title).pressed.emit()
	check(game.map_panel.local_region==0 and game.state.waypoint_pos==first_site.p,"a place-list selection opens its map and sets the real nature location")
	check(game.map_selection.text.contains(first_site.title) and game.map_selection.text.contains("Pfotenschritte"),"selection explains its nature place and practical safe route")
	var panel: WolfCartography=game.map_panel
	panel.set_local(0)
	panel.pan=Vector2(17,-21)
	var anchor := Vector2(150,160)
	var world_before := (anchor-panel.size*0.5-panel.pan)/panel.local_scale()
	panel.zoom_at(1.3,anchor)
	var world_after := (anchor-panel.size*0.5-panel.pan)/panel.local_scale()
	check(world_before.distance_to(world_after)<0.001,"off-centre map zoom holds the point under the fingers")
	var chosen := {"count":0}
	panel.place_selected.connect(func(_region: int,_point: Vector2):chosen.count+=1)
	touch(panel,0,Vector2(100,100),true)
	touch(panel,4,Vector2(200,100),true)
	drag(panel,4,Vector2(220,100))
	touch(panel,0,Vector2(100,100),false)
	var pan_before: Vector2=panel.pan
	drag(panel,4,Vector2(235,110))
	touch(panel,4,Vector2(235,110),false)
	check(panel.pan!=pan_before and panel.pointer==-1 and panel.touches.is_empty(),"pinch continues as a one-finger pan and releases both touch pointers")
	check(chosen.count==0,"pinch and drag never create an accidental destination")
	var mouse := InputEventMouseButton.new()
	mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.button_index=MOUSE_BUTTON_LEFT
	mouse.pressed=true;mouse.position=Vector2(160,160);panel._gui_input(mouse)
	mouse.pressed=false;panel._gui_input(mouse)
	check(chosen.count==0 and not panel.mouse_down,"synthesized mouse events do not duplicate an atlas touch")
	panel.toggle_layer("tracks");panel.toggle_layer("route")
	check(panel.layers.tracks and not panel.layers.route,"atlas lets the player choose known traces and route visibility")
	game.select_map_region(255,true)
	check(game.map_places.get_child_count()==1 and game.find_map_regions(WolfWorldData.REGIONS[255].name).is_empty(),"unexplored places remain undisclosed and absent from search")
	game.state.visited.append(1)
	game.select_map_region(1,true)
	button_named(game.overlay,"Mein Standort").pressed.emit()
	check(game.map_selected==game.state.region and game.map_panel.local_region==game.state.region,"my-location resets the list, selection and detailed map together")
	game.close_overlay()
	game.change_region(2,WolfWorldData.SPAWN)
	game.guide_resource("water")
	game.state.pos=game.state.waypoint_pos;game.interact()
	check(game.state.action_counts.drink==2 and game.can_walk(game.state.pos),"resource guide also finds a usable dry river bank")
	game.set_waypoint(0,Vector2(1580,2025))
	var region_route: Array[int]=game.route_to(0)
	check(not region_route.is_empty() and safe_route(game.world._animal_motion,game.navigation_route()),"interregional guidance starts with a safe route to a real exit")
	game.show_travel_help()
	var time_before: float=game.state.elapsed
	game._process(20)
	check(game.state.elapsed==time_before,"planning safe routes pauses needs and gradual aging")
	game.set_process(false);game._release_audio()
	await create_timer(0.2).timeout
	root.remove_child(game);game.queue_free()
	await process_frame;await create_timer(0.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf atlas expansion suite: %d checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
