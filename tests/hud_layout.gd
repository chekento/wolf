extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1
func settled() -> void:
	for i in range(5):await process_frame
func inside(child: Control,parent: Control) -> bool:
	var box := parent.get_global_rect().grow(.1)
	return box.encloses(child.get_global_rect())
func run() -> void:
	WolfState.save_path="user://wolf_hud_layout.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var game = load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game);await settled()
	game.set_process(false);game.close_overlay()
	game.state.begin_main_story();game.state.main_story_progress.stage=1
	game.notify("Frische Fährten erscheinen im Wind. Nähere dich leise und lass deiner Mutter Zeit, wirklich neben dir anzukommen.")
	for portrait in [Vector2i(540,960),Vector2i(432,768),Vector2i(360,640)]:
		root.size=portrait;root.content_scale_size=portrait
		game.set_hud_compact(true,false);game._refresh_status();await settled()
		game._layout_mission_hud();await settled()
		check(game.header.size.y<=64,"folded header is a single thin ribbon at %s"%portrait)
		check(not game.header_portrait.visible and not game.location_hint.visible and game.compact_needs.visible,"folded header hides portrait, verbose subtitle and large detail rows at %s"%portrait)
		check(not game.quest_hint.is_visible_in_tree() and not game.encounter_button.is_visible_in_tree(),"folded header hides mission shortcuts and encounter button at %s"%portrait)
		check(game.hud_action_controls.size()==6 and game.hud_bottom_controls.size()==4,"all six gameplay actions and four navigation buttons are available at %s"%portrait)
		check(game.hud_action_controls[3].text=="Ruhen" and game.hud_action_controls[4].text=="Rudel","rest and pack have direct bottom actions at %s"%portrait)
		check(game.observation_panel.visible,"joint mission feedback remains visible at %s"%portrait)
		check(game.observation_panel.size.y<=90,"default mission HUD is compact at %s"%portrait)
		check(not game.observation_hint.visible,"long mission instruction is folded by default at %s"%portrait)
		check(not game.quest_hint.text.contains(game.state.main_story_status().objective),"header does not duplicate the long objective at %s"%portrait)
		check(not game.observation_panel.get_global_rect().intersects(game.toast_lane.get_global_rect()),"toast and mission have separate actual rectangles at %s"%portrait)
		check(game.toast_lane.get_global_rect().end.y<game.stick.get_global_rect().position.y,"toast remains above movement controls at %s"%portrait)
		check(game.observation_title.size.y>=18 and game.observation_summary.size.y>=16,"compact text has positive readable line height at %s"%portrait)
		check(inside(game.observation_summary,game.observation_panel) and inside(game.observation_fold,game.observation_panel),"status and fold control fit inside panel at %s"%portrait)
		check(game.observation_panel.get_global_rect().position.y>game.header.get_global_rect().end.y,"mission panel remains below header at %s"%portrait)
		game.observation_fold.pressed.emit();await settled()
		check(game.mission_hud_expanded and game.observation_hint.visible,"fold button opens readable local conditions at %s"%portrait)
		check(game.observation_panel.get_global_rect().position.y>game.header.get_global_rect().end.y,"expanded mission remains below header at %s"%portrait)
		check(inside(game.observation_hint,game.observation_panel),"expanded conditions stay inside mission panel at %s"%portrait)
		check(not game.observation_panel.get_global_rect().intersects(game.toast_lane.get_global_rect()),"expanded panel never overlaps toast at %s"%portrait)
		game.observation_fold.pressed.emit();await settled()
		var action_areas: Array[Rect2]=[]
		for control in game.hud_action_controls+game.hud_bottom_controls:
			check(inside(control,game.ui),"responsive movement/action button fits viewport at %s"%portrait)
			check(control.size.x>=45 and control.size.y>=44,"action or navigation button has a usable touch target at %s"%portrait)
			for area in action_areas:
				check(not area.intersects(control.get_global_rect().grow(-.5)),"independent bottom buttons do not overlap at %s"%portrait)
			action_areas.append(control.get_global_rect())
		check(inside(game.stick,game.ui) and game.stick.size.x>=95,"joystick remains visible and sufficiently wide at %s"%portrait)
		game.set_hud_compact(false,false);game._refresh_status();await settled()
		check(game.header_portrait.visible and game.header_details.visible and not game.compact_needs.visible,"expanded status reveals portrait, minimap and meters at %s"%portrait)
		check(game.header.size.y>100 and game.header.get_global_rect().end.y<game.toast_lane.get_global_rect().position.y,"expanded status remains above the separate toast lane at %s"%portrait)
		if portrait.y<760:
			check(not game.observation_panel.visible,"small-screen expanded status temporarily hides mission strip at %s"%portrait)
		game.set_hud_compact(true,false);game._refresh_status();await settled()
		check(game.header.size.y<=64 and game.observation_panel.visible,"folding restores thin ribbon and mission feedback at %s"%portrait)
	check(game.observation_panel.mouse_filter==Control.MOUSE_FILTER_IGNORE and game.observation_hint.mouse_filter==Control.MOUSE_FILTER_IGNORE and game.observation_summary.mouse_filter==Control.MOUSE_FILTER_IGNORE,"passive mission surfaces leave landscape gestures and stick available")
	check(game.observation_details.mouse_filter==Control.MOUSE_FILTER_STOP,"only explicit details control accepts a tap")
	game.observation_details.pressed.emit();await settled()
	check(is_instance_valid(game.overlay),"details tap opens the full campaign objective")
	check(not game.observation_panel.visible and not game.toast.visible,"modal hides mission HUD and toast completely")
	game.close_overlay();game._refresh_status();await settled()
	check(game.observation_panel.visible and game.toast.visible,"closing details restores mission HUD and active toast")
	check(absf(game.look_area.offset_top-game.header.get_global_rect().end.y-10)<.1,"camera swipe area follows the current folded header immediately")
	game.hud_action_controls[4].pressed.emit();await settled()
	check(is_instance_valid(game.overlay),"the bottom Rudel action opens the actual family menu")
	game.close_overlay();game._refresh_status();await settled()
	game.hud_action_controls[5].pressed.emit();await settled()
	check(is_instance_valid(game.overlay),"the bottom Story action opens the actual campaign menu")
	game.close_overlay();game._refresh_status();await settled()
	check(game.toast.max_lines_visible==3 and game.toast_lane.size.y<=70 and game.toast_lane.clip_contents,"long toasts are bounded to their reserved three-line lane")
	game._release_audio();root.remove_child(game);game.queue_free();await settled();await create_timer(.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf HUD layout: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
