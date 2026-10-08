extends SceneTree
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
func run() -> void:
	WolfState.save_path="user://wolf_nature_controls.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var game = load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game);await process_frame
	game.set_process(false);game.close_overlay();game.show_nature_journeys()
	await process_frame;await process_frame
	var offers: Array=game.state.nature_journeys_options()
	check(offers.size()==6,"six region-specific nature journeys are available")
	for offer in offers:
		var item := find_button(game.overlay,"◌ "+str(offer.title))
		check(item!=null,"each of the six offers has an actual start button")
		check(item!=null and item.global_position.y+item.size.y<game.ui.size.y-60,"each offer is immediately visible in portrait")
	var start := find_button(game.overlay,"◌ "+str(offers[0].title))
	if start!=null:start.pressed.emit()
	check(game.state.nature_journey_status().accepted and not is_instance_valid(game.overlay),"accepting a nature journey resumes real outdoor play")
	check(game.state.waypoint_region==game.state.region,"acceptance sets a physical local scent goal")
	game.show_nature_journeys();await process_frame;await process_frame
	var resume := find_button(game.overlay,"Meine Naturreise fortsetzen")
	check(resume!=null and resume.global_position.y+resume.size.y<game.ui.size.y-60,"active journey action is visible above all offers")
	var elapsed: float=game.state.elapsed
	var stage: int=game.state.nature_journey_status().stage
	game._tick_nature_journey(10)
	check(game.state.elapsed==elapsed and game.state.nature_journey_status().stage==stage,"nature menu cannot advance world time or mission steps")
	if resume!=null:resume.pressed.emit()
	game.set_waypoint(1,Vector2(1500,1500));game._refresh_nature_journey_guide()
	check(game.state.waypoint_region==1 and game.guided_nature_journey.is_empty(),"personal map goal is preserved over journey guidance")
	game.show_nature_journeys()
	var abandon := find_button(game.overlay,"Naturreise zurücklegen")
	if abandon!=null:abandon.pressed.emit()
	check(not game.state.nature_journey_status().accepted,"explicit abandonment releases the active journey")
	check(game.state.story_step==0 and not game.state.main_story_status().started,"nature travel preserves both legacy memories and untouched campaign")
	game.close_overlay();game._release_audio();root.remove_child(game);game.queue_free()
	await process_frame;await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf nature journey controls: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
