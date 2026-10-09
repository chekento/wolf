extends Node

var state := WolfState.new()
var world: Dictionary
var map_view: WolfMapView
var world_view: WolfWorldView
var ui: Control
var stick: WolfTouchStick
var title: Label
var location_hint: Label
var stats: Label
var quest_hint: Label
var toast: Label
var toast_lane: Control
var mode_button: Button
var sprint_button: Button
var overlay: Control
var look_area: Control
var first_person := false
var scent_time := 0.0
var clock := 0.0
var save_timer := 0.0
var toast_time := 0.0
var howl_cooldown := 0.0
var status_timer := 0.0
var look_pointer := -1
var touch_owners: Dictionary = {}
var previous_touch_mouse_emulation := true
var looking_mouse := false
var sneak_button: Button
var minimap: WolfMinimap
var need_bars: Dictionary = {}
var need_labels: Dictionary = {}
var level_label: Label
var last_pack_visit := -30.0
var last_pack_play := -100.0
var sound: AudioStreamPlayer
var ambient: AudioStreamPlayer
var world_cache: Dictionary = {}
var world_memory := WolfSessionCache.new()
var collision_index := WolfCollisionIndex.new()
var encounter_button: Button
var camera_button: Button
var header: PanelContainer
var header_details: VBoxContainer
var header_portrait: TextureRect
var compact_needs: Label
var fold_button: Button
var menu_button: Button
var atlas_button: Button
var action_button: Button
var story_button: Button
var player_speed := 0.0
var player_gait := 0.0
var player_mood := "lauschen"
var action_timer := 0.0
var rest_cooldown := 0.0
var app_idle := false
var map_panel: WolfCartography
var map_selection: Label
var map_selected := -1
var guided_encounter_id := ""
var guided_progress := -1
var guided_main_story := ""
var guided_nature_journey := ""
var nature_journey_ready_notice := ""
var main_story_ready_notice := ""
var trail_navigation := WolfTrailNavigation.new()
var navigation_points := PackedVector2Array()
var map_places: VBoxContainer
var atlas_expanded := false
var observation_panel: PanelContainer
var observation_title: Label
var observation_hint: Label
var observation_progress: ProgressBar
var observation_summary: Label
var observation_fold: Button
var observation_details: Button
var mission_hud_expanded := false
var hud_action_controls: Array[Button]=[]
var hud_bottom_controls: Array[Button]=[]
var hud_layout_width_mode := -1
var serif: Font=preload("res://assets/fonts/DejaVuSerif.ttf")


func _ready() -> void:
	var resumed := state.load_from()
	if resumed:world_memory.load_cache(WolfState.save_path+".wildlife.json")
	world=world_memory.region_world(state.region)
	world_cache=world_memory.worlds
	collision_index.build(world.objects)
	_sync_companion()
	if not can_walk(state.pos):state.pos=WolfWorldData.SPAWN
	world_view=WolfWorldView.new()
	world_view.game=self
	add_child(world_view)
	world_view.visible=false
	map_view=WolfMapView.new()
	map_view.game=self
	add_child(map_view)
	sound=AudioStreamPlayer.new()
	add_child(sound)
	previous_touch_mouse_emulation=Input.emulate_mouse_from_touch
	Input.emulate_mouse_from_touch=false
	_build_ui()
	_apply_quality()
	_build_ambient()
	_refresh_status()
	if not resumed:
		show_intro()
	else:
		notify("Willkommen zurück. Dein Rudel ist noch hier.")
	_sync_audio()

func panel_style(color: Color, radius: int=18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color=Color("#869c78")
	style.shadow_color=Color(0.02,0.06,0.04,0.25)
	style.shadow_size=6
	style.shadow_offset=Vector2(0,3)
	style.content_margin_left=16
	style.content_margin_right=16
	style.content_margin_top=12
	style.content_margin_bottom=12
	return style

func _save_game() -> bool:
	if not world.is_empty():world_memory.capture(state.region,world)
	var saved := state.save_to()
	if saved:world_memory.save_cache(WolfState.save_path+".wildlife.json")
	return saved

func _release_audio() -> void:
	for player in [sound,ambient]:
		if is_instance_valid(player):
			player.stream_paused=false
			player.stop()
			player.stream=null

func _sync_audio() -> void:
	# Stop menu/background playbacks rather than parking paused mixer objects.
	# A fresh outdoor loop keeps repeated modal changes and teardown reliable.
	var audible := state.sound_enabled and not app_idle and not is_instance_valid(overlay)
	if is_instance_valid(ambient):
		if audible:
			if not ambient.playing:ambient.play()
		else:ambient.stop()
	if is_instance_valid(sound) and not audible:sound.stop()

func _exit_tree() -> void:
	_cancel_touch_inputs()
	Input.emulate_mouse_from_touch=previous_touch_mouse_emulation
	_release_audio()

func label(text_value: String,font_size: int=18) -> Label:
	var l := Label.new()
	l.text=text_value
	l.add_theme_font_size_override("font_size",font_size)
	if font_size>=24:l.add_theme_font_override("font",serif)
	l.add_theme_color_override("font_color",Color("#eeebd5"))
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func button(text_value: String,callback: Callable) -> Button:
	var b := Button.new()
	b.text=text_value
	b.clip_text=false
	b.tooltip_text=text_value
	b.custom_minimum_size=Vector2(0,54)
	b.add_theme_font_size_override("font_size",17)
	b.add_theme_color_override("font_color",Color("#eee9cc"))
	b.add_theme_stylebox_override("normal",panel_style(Color("#284c43"),14))
	b.add_theme_stylebox_override("hover",panel_style(Color("#3f6553"),14))
	b.add_theme_stylebox_override("pressed",panel_style(Color("#787353"),14))
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	b.focus_mode=Control.FOCUS_NONE
	b.pressed.connect(callback)
	return b

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui=Control.new()
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var weather_layer := WolfAtmosphere.new()
	weather_layer.game=self
	ui.add_child(weather_layer)
	weather_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header=PanelContainer.new()
	ui.add_child(header)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left=8
	header.offset_right=-8
	header.offset_top=6
	# The default HUD must be a true single-line ribbon, not a tall
	# panel with hidden details beneath permanent quest shortcuts.
	var ribbon_style := panel_style(Color(0.035,0.12,0.10,0.90),12)
	ribbon_style.content_margin_left=7
	ribbon_style.content_margin_right=7
	ribbon_style.content_margin_top=4
	ribbon_style.content_margin_bottom=4
	ribbon_style.set_border_width_all(1)
	ribbon_style.shadow_size=2
	header.add_theme_stylebox_override("panel",ribbon_style)
	var stack := VBoxContainer.new()
	header.add_child(stack)
	stack.add_theme_constant_override("separation",3)
	var top := HBoxContainer.new()
	stack.add_child(top)
	header_portrait=TextureRect.new()
	header_portrait.texture=WolfAtlas.sprite(15)
	header_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	header_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_portrait.custom_minimum_size=Vector2(38,38)
	header_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	top.add_child(header_portrait)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(titles)
	title=label("",16)
	title.clip_text=true
	title.max_lines_visible=1
	title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	title.autowrap_mode=TextServer.AUTOWRAP_OFF
	titles.add_child(title)
	location_hint=label("",12)
	titles.add_child(location_hint)
	compact_needs=label("",11)
	compact_needs.autowrap_mode=TextServer.AUTOWRAP_OFF
	compact_needs.clip_text=true
	compact_needs.mouse_filter=Control.MOUSE_FILTER_IGNORE
	top.add_child(compact_needs)
	fold_button=button("⌄",func():set_hud_compact(not state.compact_hud))
	menu_button=button("☰",show_menu)
	for control in [fold_button,menu_button]:
		control.custom_minimum_size=Vector2(39,39)
		control.add_theme_font_size_override("font_size",17)
		for key in ["normal","hover","pressed"]:
			var control_style := panel_style(Color("#284c43"),9)
			control_style.set_border_width_all(1)
			control_style.content_margin_left=4
			control_style.content_margin_right=4
			control_style.content_margin_top=2
			control_style.content_margin_bottom=2
			control.add_theme_stylebox_override(key,control_style)
		top.add_child(control)
	header_details=VBoxContainer.new()
	stack.add_child(header_details)
	var row := HBoxContainer.new()
	header_details.add_child(row)
	row.add_theme_constant_override("separation",12)
	var meters := GridContainer.new()
	meters.columns=2
	meters.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	meters.add_theme_constant_override("h_separation",10)
	row.add_child(meters)
	for item in [["hunger","Nahrung","#ceac69"],["thirst","Wasser","#72c4d4"],["energy","Kraft","#91c387"],["bond","Rudel","#cf9292"]]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		meters.add_child(column)
		var text_label := label(item[1],12)
		column.add_child(text_label)
		need_labels[item[0]]=text_label
		var bar := ProgressBar.new()
		bar.custom_minimum_size=Vector2(68,8)
		bar.show_percentage=false
		bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var background := panel_style(Color("#142d24"),4)
		background.content_margin_top=0;background.content_margin_bottom=0
		background.set_border_width_all(0)
		bar.add_theme_stylebox_override("background",background)
		var fill := background.duplicate()
		fill.bg_color=Color(item[2])
		bar.add_theme_stylebox_override("fill",fill)
		column.add_child(bar)
		need_bars[item[0]]=bar
	minimap=WolfMinimap.new()
	minimap.game=self
	minimap.custom_minimum_size=Vector2(83,83)
	row.add_child(minimap)
	level_label=label("",12)
	header_details.add_child(level_label)
	var shortcuts := HBoxContainer.new()
	header_details.add_child(shortcuts)
	encounter_button=button("Neue Begegnung",show_encounter)
	encounter_button.custom_minimum_size.y=32
	encounter_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	encounter_button.add_theme_font_size_override("font_size",12)
	shortcuts.add_child(encounter_button)
	camera_button=button("Folgekamera",switch_camera)
	camera_button.custom_minimum_size=Vector2(100,32)
	camera_button.add_theme_font_size_override("font_size",12)
	camera_button.hide()
	shortcuts.add_child(camera_button)
	quest_hint=label("",13)
	quest_hint.max_lines_visible=2;quest_hint.clip_text=true;quest_hint.custom_minimum_size.y=20
	header_details.add_child(quest_hint)
	stats=label("",12)
	stats.hide()
	header_details.add_child(stats)
	look_area=Control.new()
	ui.add_child(look_area)
	look_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	look_area.offset_top=220
	look_area.offset_bottom=-242
	look_area.mouse_filter=Control.MOUSE_FILTER_STOP
	look_area.gui_input.connect(_look_input)
	observation_panel=PanelContainer.new()
	ui.add_child(observation_panel)
	observation_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	observation_panel.offset_left=28;observation_panel.offset_right=-28
	observation_panel.offset_top=-406;observation_panel.offset_bottom=-328
	observation_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	observation_panel.add_theme_stylebox_override("panel",panel_style(Color(0.08,0.19,0.15,0.92),16))
	var observation_stack := VBoxContainer.new()
	observation_stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
	observation_stack.add_theme_constant_override("separation",3)
	observation_panel.add_child(observation_stack)
	var observation_row := HBoxContainer.new()
	observation_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	observation_stack.add_child(observation_row)
	observation_title=label("",14)
	observation_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	observation_title.max_lines_visible=1;observation_title.clip_text=true;observation_title.custom_minimum_size.y=20
	observation_row.add_child(observation_title)
	observation_fold=button("⌄",func():
		mission_hud_expanded=not mission_hud_expanded
		_layout_mission_hud()
	)
	observation_fold.custom_minimum_size=Vector2(34,30)
	observation_fold.add_theme_font_size_override("font_size",14)
	observation_fold.tooltip_text="Kurze Missionshinweise öffnen oder einklappen"
	observation_row.add_child(observation_fold)
	observation_details=button("?",_show_hud_mission_details)
	observation_details.custom_minimum_size=Vector2(34,30)
	observation_details.add_theme_font_size_override("font_size",14)
	observation_details.tooltip_text="Die ganze Aufgabe und ihre Bedingungen lesen"
	observation_row.add_child(observation_details)
	for control in [observation_fold,observation_details]:
		for key in ["normal","hover","pressed"]:
			var style := panel_style(Color("#284c43"),10)
			style.content_margin_top=2;style.content_margin_bottom=2
			style.content_margin_left=6;style.content_margin_right=6
			control.add_theme_stylebox_override(key,style)
	observation_summary=label("",13);observation_summary.max_lines_visible=1
	observation_summary.clip_text=true;observation_summary.custom_minimum_size.y=18;observation_stack.add_child(observation_summary)
	observation_hint=label("",13);observation_hint.custom_minimum_size.y=44;observation_hint.max_lines_visible=3;observation_hint.clip_text=false;observation_hint.hide();observation_stack.add_child(observation_hint)
	observation_progress=ProgressBar.new()
	observation_progress.custom_minimum_size.y=7
	observation_progress.show_percentage=false
	observation_progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
	observation_stack.add_child(observation_progress)
	observation_panel.minimum_size_changed.connect(func():_fit_mission_panel.call_deferred())
	observation_panel.hide()
	toast_lane=Control.new()
	toast_lane.clip_contents=true;toast_lane.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(toast_lane)
	toast_lane.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast_lane.offset_left=30;toast_lane.offset_right=-30
	toast_lane.offset_top=-316;toast_lane.offset_bottom=-246
	toast=label("",16)
	toast_lane.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast.max_lines_visible=3;toast.clip_text=false
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_shadow_color",Color("#102b23"))
	toast.add_theme_constant_override("shadow_outline_size",6)
	var lower := HBoxContainer.new()
	ui.add_child(lower)
	lower.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	lower.offset_left=14;lower.offset_right=-14
	lower.offset_top=-234;lower.offset_bottom=-90
	lower.add_theme_constant_override("separation",12)
	stick=WolfTouchStick.new()
	lower.add_child(stick)
	var actions := GridContainer.new()
	actions.columns=3
	actions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation",7)
	actions.add_theme_constant_override("v_separation",7)
	lower.add_child(actions)
	# Six permanent actions remain usable even during an active mission.
	# Context action still selects water, food, tracks, greetings and watching.
	for item in [["Schnüffeln",sniff,"Zeigt frische Fährten"],["Aktion",interact,"Interagiert mit dem nächsten Tier oder Naturort"],["Heulen",howl,"Rufe das Rudel"],["Ruhen",rest,"Ruhen an einer sicheren Höhle"],["Rudel",show_pack,"Rudel, Begleitung und gemeinsames Spielen"],["Geschichte",show_main_story,"Hauptgeschichte und aktive Missionsziele"]]:
		var b := button(item[0],item[1])
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.tooltip_text=item[2]
		actions.add_child(b)
		hud_action_controls.append(b)
		if item[0]=="Aktion":action_button=b
		if item[0]=="Geschichte":story_button=b
	var bottom := HBoxContainer.new()
	ui.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left=14;bottom.offset_right=-14
	bottom.offset_top=-76;bottom.offset_bottom=-18
	bottom.add_theme_constant_override("separation",7)
	mode_button=button("3D · Wolfsblick",toggle_view)
	mode_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bottom.add_child(mode_button)
	sprint_button=button("Trab",func():pass)
	sprint_button.toggle_mode=true
	bottom.add_child(sprint_button)
	sneak_button=button("Leise",func():pass)
	sneak_button.toggle_mode=true
	bottom.add_child(sneak_button)
	atlas_button=button("Karte",show_map)
	bottom.add_child(atlas_button)
	hud_bottom_controls=[mode_button,sprint_button,sneak_button,atlas_button]
	# Do not let the short labels turn the three right-hand navigation
	# controls into 35px slivers on a narrow phone.
	for control in [sprint_button,sneak_button,atlas_button]:
		control.custom_minimum_size.x=52
	set_hud_compact(state.compact_hud,false)

func set_hud_compact(compact: bool,persist: bool=true) -> void:
	state.compact_hud=compact
	_apply_header_display()
	if persist:_save_game()

func _apply_header_display() -> void:
	if not is_instance_valid(header) or not is_instance_valid(ui):return
	# On small screens the player can still open the status ribbon.
	# The mission strip temporarily yields space and returns when folded.
	var expanded := not state.compact_hud
	header_details.visible=expanded
	header_portrait.visible=expanded
	location_hint.visible=expanded
	compact_needs.visible=not expanded
	fold_button.text="⌃" if expanded else "⌄"
	fold_button.tooltip_text="Status, Minikarte und Aufgaben einklappen" if expanded else "Status und Minikarte aufklappen"
	header.queue_sort()
	_fit_header.call_deferred()

func _fit_header() -> void:
	if is_instance_valid(header):
		header.size=Vector2(header.size.x,header.get_combined_minimum_size().y)
	if is_instance_valid(look_area):
		look_area.offset_top=header.position.y+header.size.y+10

func _update_bottom_labels() -> void:
	if hud_action_controls.size()!=6 or not is_instance_valid(mode_button):return
	var narrow := ui.size.x<440
	hud_action_controls[0].text="Nase" if narrow else "Schnüffeln"
	hud_action_controls[5].text="Story" if narrow else "Geschichte"
	mode_button.text=("2D" if first_person else "3D") if narrow else ("2D · Draufsicht" if first_person else "3D · Folgekamera" if state.camera_follow else "3D · Wolfsblick")
	var interaction := context_action()
	action_button.tooltip_text=interaction
	action_button.text={"Ort prüfen":"Prüfen","Spur lesen":"Spur","Duft setzen":"Duft","Beobachten":"Sehen"}.get(interaction,interaction) if narrow else interaction

func _process(dt: float) -> void:
	if app_idle or is_instance_valid(overlay):return
	clock+=dt
	if state.waypoint_region==state.region and state.pos.distance_to(state.waypoint_pos)<55:
		state.waypoint_region=-1
		notify("Dein Duftziel ist erreicht. Schau dich um und schnüffle nach neuen Spuren.")
	look_area.offset_top=header.position.y+header.size.y+10
	action_timer=maxf(0,action_timer-dt)
	rest_cooldown=maxf(0,rest_cooldown-dt)
	if action_timer<=0:player_mood="lauschen"
	scent_time=maxf(0,scent_time-dt)
	howl_cooldown=maxf(0,howl_cooldown-dt)
	var v := stick.vector
	var keys := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if keys.length()>0:v=keys.limit_length(1)
	if first_person:
		var look := Vector2(float(Input.is_physical_key_pressed(KEY_L))-float(Input.is_physical_key_pressed(KEY_J)),float(Input.is_physical_key_pressed(KEY_K))-float(Input.is_physical_key_pressed(KEY_I)))
		world_view.look(look*dt*220)
		v=v.rotated(-world_view.yaw)
	var sprint := (sprint_button.button_pressed or Input.is_physical_key_pressed(KEY_SHIFT)) and state.energy>5
	var speed := 190.0 if sprint else 120.0
	if sneak_button.button_pressed:speed=65.0
	if sneak_button.button_pressed:sprint=false
	if state.thirst<10 or state.hunger<10:speed*=0.65
	player_speed=0
	var before := state.pos
	if v.length()>0.01:
		player_mood="laufen"
		action_timer=0
		state.facing=v.normalized()
		var movement_dt := minf(dt,0.20)
		var steps := maxi(1,ceili(movement_dt/0.035))
		for step in range(steps):move_wolf(v*speed*movement_dt/steps)
	player_speed=state.pos.distance_to(before)/maxf(dt,0.0001) if state.pos.distance_to(before)<100 else 0
	player_gait+=state.pos.distance_to(before)/22.0 if state.pos.distance_to(before)<100 else 0
	if player_speed>1 and (state.pawsteps.is_empty() or state.pawsteps.back().p.distance_to(state.pos)>22):
		state.pawsteps.append({"p":state.pos,"facing":state.facing,"time":state.elapsed})
		if state.pawsteps.size()>32:state.pawsteps.pop_front()
	if player_mood=="ruhen":state.energy=minf(100,state.energy+dt*3)
	state.tick(dt,player_speed>1,sprint)
	_update_animals(minf(dt,0.08))
	_tick_wildlife_observation(dt)
	_tick_main_story(dt)
	_tick_nature_journey(dt)
	if first_person:world_view.sync_camera()
	map_view.queue_redraw()
	minimap.queue_redraw()
	if toast_time>0:
		toast_time-=dt
		if toast_time<=0:toast.text=""
	status_timer+=dt
	if status_timer>0.25:
		status_timer=0
		check_quests()
		_refresh_encounter_guide()
		_refresh_main_story_guide()
		_refresh_nature_journey_guide()
		_refresh_status()
	save_timer+=dt
	if save_timer>20:
		save_timer=0
		_save_game()

func can_walk(p: Vector2) -> bool:
	if WolfWorldData.water_blocked(p,state.region):return false
	return collision_index.walkable(p)

func move_wolf(delta: Vector2) -> void:
	# Axis separation permits sliding around trees without cutting through them.
	var before := state.pos
	var members := WolfPackInteractions.cohort(world.animals)
	var navigation: WolfAnimalMotion=world.get("_animal_motion")
	var p := state.pos+Vector2(delta.x,0)
	if can_walk(p) and (navigation==null or navigation.player_step_free(state.pos,p,members,40.0*state.growth())):state.pos=p
	p=state.pos+Vector2(0,delta.y)
	if can_walk(p) and (navigation==null or navigation.player_step_free(state.pos,p,members,40.0*state.growth())):state.pos=p
	state.distance_walked+=state.pos.distance_to(before)
	var direction := WolfWorldData.exit_at(state.pos,state.region)
	if direction!="":
		change_region(WolfWorldData.REGIONS[state.region].links[direction],WolfWorldData.entry_point(direction))
	else:
		state.pos=state.pos.clamp(Vector2(14,14),WolfWorldData.SIZE-Vector2(14,14))

func change_region(index: int,entry: Vector2) -> void:
	state.clear_encounter_presence()
	if not world.is_empty():world_memory.capture(state.region,world)
	state.region=index
	state.pos=entry
	world=world_memory.region_world(index)
	world_cache=world_memory.worlds
	collision_index.build(world.objects)
	state.pawsteps.clear()
	_sync_companion()
	if not state.visited.has(index):
		state.visited.append(index)
		state.record("Neues Gebiet · "+WolfWorldData.REGIONS[index].name+". "+WolfWorldData.REGIONS[index].subtitle)
	if first_person:world_view.rebuild()
	else:world_view.region_built=-1
	last_pack_visit=-30
	notify(WolfWorldData.REGIONS[index].name+" · Ein neuer Duft liegt in der Luft.")
	_save_game()

func _sync_companion() -> void:
	world.animals=world.animals.filter(func(a:Dictionary):return not a.get("companion",false))
	if not state.escort or state.region==0:return
	if not world.has("_animal_motion"):
		var motion := WolfAnimalMotion.new()
		motion.configure(state.region,world.objects)
		world._animal_motion=motion
	var navigation: WolfAnimalMotion=world._animal_motion
	# New region entries put the parent just behind the arriving wolf, inside
	# a real free area. An existing animal is never moved to catch the player.
	var parent := {"kind":"wolf","phase":0.0,"facing":state.facing,"young":false,"role":"Mutter","companion":true,"mood":"begleiten","speed":0.0,"gait":0.0}
	var members := WolfPackInteractions.cohort(world.animals)
	var candidates: Array[Vector2]=[navigation.nearest_free(state.pos-state.facing*70+Vector2(25,20),160)]
	for radius in [100.0,140.0,180.0]:
		for angle in [0.0,.6,-.6,1.2,-1.2,PI/2,-PI/2,PI]:
			candidates.append(state.pos-state.facing.rotated(angle)*radius)
	for p in candidates:
		if not p.is_finite() or not navigation.walkable(p) or not navigation.segment_free(state.pos,p):continue
		if not navigation.body_step_free(p,p,parent,members,state.pos,40.0*state.growth()):continue
		parent.p=p;parent.home=p
		world.animals.append(parent)
		return

func _update_animals(dt: float) -> void:
	# A missing or disabled escort must not retain yesterday's live proximity.
	state.tick_pack_walk(0.0,{},player_speed)
	if not world.has("_animal_motion"):
		var motion := WolfAnimalMotion.new()
		motion.configure(state.region,world.objects)
		world._animal_motion=motion
	var navigation: WolfAnimalMotion=world._animal_motion
	var pack_members := WolfPackInteractions.cohort(world.animals)
	var player_radius := 40.0*state.growth()
	var meeting := state.main_story_home_meeting_active()
	var meeting_goal := WolfMainStory.current_stage(state.main_story_progress)
	var pack_context := {"region":state.region,"hour":state.hour(),"now":clock,"elapsed":state.elapsed,"escort":state.escort,"player_pos":state.pos,"player_facing":state.facing,"player_speed":player_speed,"player_mood":player_mood,"signal":state.pack_signal,"player_radius":player_radius,"meeting":meeting,"meeting_center":meeting_goal.get("meeting_center",Vector2(INF,INF)) if meeting else Vector2(INF,INF),"meeting_radius":300.0,"howling":action_timer>0 and player_mood=="heulen"}
	for member in world.animals:
		if member.kind!="wolf" and not member.has("_ecology"):member._ecology=navigation.ecology_targets(member)
	for member in world.animals:
		if member.kind=="deer" and not member._ecology.has("group_forage"):member._ecology.group_forage=navigation.group_forage_target(member,world.animals)
	for a in world.animals:
		var distance: float=a.p.distance_to(state.pos)
		var target: Vector2=a.home
		var speed := 20.0
		var mood := "wandern"
		if a.kind!="wolf":
			var ecology: Dictionary=a._ecology
			var previous_behavior: String=a.get("behavior","")
			var activity: Dictionary=WolfPackLife.wildlife_activity(a,state.hour(),dt)
			var profile: Dictionary=WolfPackLife.wildlife_profile(a.kind)
			target=activity.target;speed=activity.speed;mood=activity.mood;a.behavior=activity.behavior
			var quiet := sneak_button.button_pressed or player_speed<=35
			var visible: bool=distance<float(profile.notice) and navigation.segment_free(a.p,state.pos)
			var awareness := clampf(1.0-distance/float(profile.notice),0,1)*(0.75 if quiet else 1.7) if visible else 0.0
			var loud_call: bool=action_timer>0 and player_mood=="heulen" and distance<270
			if loud_call:awareness=1.0
			a.attention=lerpf(float(a.get("attention",0)),clampf(awareness,0,1),clampf(dt*4,0,1))
			var flee_radius: float=float(profile.quiet_flee)-float(state.skills.stealth)*0.08 if quiet else float(profile.loud_flee)+(30.0 if player_speed>100 else 0.0)
			var direct_threat: bool=(distance<flee_radius and (visible or distance<60)) or loud_call
			var herd_threat := false
			if a.kind=="deer":
				for neighbor in world.animals:
					if neighbor.kind=="deer" and clock-float(neighbor.get("_direct_threat_at",-100))<2 and a.p.distance_to(neighbor.p)<260 and a.home.distance_to(neighbor.home)<450:herd_threat=true;break
			if direct_threat:a._direct_threat_at=clock
			var threatened: bool=direct_threat or herd_threat
			if threatened:
				a.alarm=float(profile.recover) if direct_threat else maxf(float(a.get("alarm",0)),2.0)
				a._return_cover=false
				if not a.has("_refuge") or clock>=float(a.get("_escape_replan",0)) or a._refuge.distance_to(state.pos)<flee_radius:
					a._refuge=navigation.refuge_from(a,state.pos)
					a._escape_replan=clock+2.0
			if a.get("alarm",0.0)>0:
				a.alarm=maxf(0,a.alarm-dt)
				if not a.has("_refuge"):a._refuge=navigation.refuge_from(a,state.pos)
				target=a._refuge;speed=float(profile.escape_speed);mood="fliehen";a.behavior="flee"
				if a.p.distance_to(target)<12:speed=0;mood="lauschen"
			else:
				if previous_behavior=="flee":a._return_cover=true
				if a.get("_return_cover",false) or clock<float(a.get("_recover_until",-1)):
					target=ecology.shelter;speed=26;mood="wandern";a.behavior="recover"
					if a.p.distance_to(target)<12:
						speed=0;mood="lauschen"
						if a.get("_return_cover",false):a._return_cover=false;a._recover_until=clock+3.0
				elif visible and distance<(float(profile.quiet_flee)*1.8 if quiet else float(profile.notice)*0.82):
					target=a.p;speed=0;mood="lauschen";a.behavior="alert"
			if mood=="lauschen" and distance<float(profile.notice):a.facing=a.p.direction_to(state.pos)
		else:
			var social := WolfPackInteractions.plan(a,pack_members,navigation,pack_context)
			target=social.target;speed=social.speed;mood=social.mood
			a.attention=social.attention;a.behavior=social.behavior
			a.target_pos=social.look_target
			if speed<=1 and a.p.distance_squared_to(social.look_target)>.01:a.facing=a.p.direction_to(social.look_target)
		if a.kind!="wolf":a.target_pos=state.pos if a.get("behavior","")=="alert" else target
		var purposeful: bool=a.kind=="wolf" or a.p.distance_to(target)>260 or a.get("behavior","") in ["flee","recover","shelter","drink"]
		var next: Vector2=navigation.advance_pack(a,target,speed,dt,clock,pack_members,state.pos,player_radius) if a.kind=="wolf" else navigation.advance(a,target,speed,dt,clock,purposeful)
		var moved: float=next.distance_to(a.p)
		if moved>0.01:a.facing=(next-a.p).normalized()
		a.speed=moved/maxf(dt,0.0001)
		a.gait=a.get("gait",0.0)+moved/18.0
		a.p=next
		a.mood=mood
		if a.kind=="wolf" and (a.get("companion",false) or (state.escort and a.get("role","")=="Mutter")):
			state.tick_pack_walk(dt,a,player_speed,navigation.segment_free(a.p,state.pos))

func toggle_view() -> void:
	state.clear_encounter_presence()
	first_person=not first_person
	_cancel_touch_inputs()
	world_view.visible=first_person
	map_view.visible=not first_person
	stick.reset()
	if first_person:
		if world_view.region_built!=state.region:world_view.rebuild()
		world_view.enter()
		world_view.set_follow_camera(state.camera_follow)
	camera_button.visible=first_person
	camera_button.text="Wolfsblick" if state.camera_follow else "Folgekamera"
	_apply_quality()
	_update_bottom_labels()
	notify("Wische über die Landschaft zum Umsehen. Untersuchen entdeckt sichtbare Tiere." if first_person else "Du siehst die Karte wieder von oben. Bewege dich in alle Richtungen.")

func switch_camera() -> void:
	state.clear_encounter_presence()
	look_pointer=-1;looking_mouse=false
	state.camera_follow=not state.camera_follow
	if first_person:world_view.set_follow_camera(state.camera_follow)
	camera_button.text="Wolfsblick" if state.camera_follow else "Folgekamera"
	_update_bottom_labels()
	_save_game()
	notify("Die Kamera folgt deinen Pfoten. Wische zum Umsehen." if state.camera_follow else "Du siehst die Wildnis wieder aus den Augen deines Wolfs.")

func _apply_quality() -> void:
	get_viewport().msaa_3d=Viewport.MSAA_2X if first_person and state.smooth_edges else Viewport.MSAA_DISABLED

# Desktop mouse look remains intact. Touch is routed before the GUI using finger IDs.
func _look_input(event: InputEvent) -> void:
	if not first_person or app_idle or is_instance_valid(overlay):return
	if event.device==InputEvent.DEVICE_ID_EMULATION:return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		looking_mouse=event.pressed
	elif event is InputEventMouseMotion and looking_mouse:
		world_view.look(event.relative)

# A finger owns exactly one surface for its lifetime: joystick, 3D look,
# or a HUD button. No finger may hijack another finger's gesture.
func _touch_button_at(pos: Vector2) -> Button:
	var controls: Array[Button]=[fold_button,menu_button,encounter_button,camera_button,observation_fold,observation_details]
	controls.append_array(hud_action_controls)
	controls.append_array(hud_bottom_controls)
	for control in controls:
		if is_instance_valid(control) and control.is_visible_in_tree() and not control.disabled and control.get_global_rect().has_point(pos):
			return control
	return null

func _cancel_touch_inputs() -> void:
	for target in touch_owners.values():
		if is_instance_valid(target) and target is Button:target.modulate=Color.WHITE
	touch_owners.clear()
	look_pointer=-1
	looking_mouse=false
	if is_instance_valid(stick):stick.reset()

func _input(event: InputEvent) -> void:
	if app_idle or is_instance_valid(overlay):return
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):return
	# This prevents the GUI from firing a second action for the same real tap.
	# Desktop mouse clicks and normal scrolling inside menus are unaffected.
	get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		var tap: InputEventScreenTouch=event
		if tap.pressed and not tap.canceled:
			if touch_owners.has(tap.index):return
			var target := _touch_button_at(tap.position)
			if target!=null:
				# Prevent two fingers from activating the same button twice.
				if touch_owners.values().has(target):return
				touch_owners[tap.index]=target
				target.modulate=Color(0.78,0.94,0.81)
			elif is_instance_valid(stick) and stick.get_global_rect().has_point(tap.position):
				if stick.begin_touch(tap.index,tap.position-stick.get_global_rect().position):
					touch_owners[tap.index]=stick
			elif first_person and look_pointer==-1 and look_area.get_global_rect().has_point(tap.position):
				look_pointer=tap.index
				touch_owners[tap.index]=look_area
			return
		if not touch_owners.has(tap.index):return
		var owner: Control=touch_owners[tap.index]
		touch_owners.erase(tap.index)
		if not is_instance_valid(owner):return
		if owner==stick:
			stick.release_touch(tap.index)
		elif owner==look_area:
			if look_pointer==tap.index:look_pointer=-1
		elif owner is Button:
			owner.modulate=Color.WHITE
			if not tap.canceled and owner.is_visible_in_tree() and owner.get_global_rect().grow(12).has_point(tap.position):
				if owner.toggle_mode:owner.set_pressed_no_signal(not owner.button_pressed)
				owner.pressed.emit()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag=event
		if not touch_owners.has(drag.index):return
		var owner: Control=touch_owners[drag.index]
		if not is_instance_valid(owner):return
		if owner==stick:
			stick.drag_touch(drag.index,drag.position-stick.get_global_rect().position)
		elif owner==look_area and first_person and look_pointer==drag.index:
			world_view.look(drag.relative)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode==KEY_ESCAPE:
		if is_instance_valid(overlay):close_overlay()
		else:show_menu()
		return
	if is_instance_valid(overlay):return
	match event.keycode:
		KEY_V:toggle_view()
		KEY_F:sniff()
		KEY_E:interact()
		KEY_H:howl()
		KEY_R:rest()
		KEY_P:show_pack()
		KEY_G:show_main_story()
		KEY_M:show_map()

func notify(message: String) -> void:
	toast.text=message
	toast_time=7

func sniff() -> void:
	scent_time=22+float(state.skills.nose)/10.0
	player_mood="schnüffeln"
	action_timer=2
	var nearest := 9999.0
	for t in world.tracks:
		if not state.found.has(t.id):nearest=minf(nearest,t.p.distance_to(state.pos))
	notify("Frische Fährten werden goldfarben sichtbar. Folge ihrem Verlauf und untersuche sie." if nearest<500 else "Du riechst Wald, Wasser und ferne Tiere. Suche entlang der Wege weiter.")

func interact() -> void:
	if state.nature_journey_status().accepted and guided_main_story.is_empty():
		if _interact_nature_journey():return
		if _interact_main_story():return
	else:
		if _interact_main_story():return
		if _interact_nature_journey():return
	# A nearby food source stays usable even when a family member stands there.
	if state.food_cooldown<=0:
		for obj in world.objects:
			if obj.kind=="food" and obj.p.distance_to(state.pos)<85:
				state.hunger=minf(100,state.hunger+40)
				state.food_cooldown=300
				state.note_action("feed")
				notify("Du frisst von den Beuteresten. Dein Hunger lässt nach.")
				check_quests()
				return
	if not state.active_encounter.is_empty() and state.active_encounter.task=="site_mark" and not state.active_encounter.get("site_checked",false):
		for obj in world.objects:
			if obj.kind=="discovery" and obj.site==state.active_encounter.site_id and obj.p.distance_to(state.pos)<140:
				inspect_nature_site(obj)
				return
	# A completed drink leads to protected rest even when family members are nearby.
	if not state.active_encounter.is_empty() and ((state.active_encounter.task=="water_rest" and state.active_encounter.get("drank_after_start",false)) or (state.active_encounter.task=="care_route" and state.active_encounter.get("care_feed",false))):
		for obj in world.objects:
			if obj.kind=="den" and obj.p.distance_to(state.pos)<190:
				rest()
				return
	if not state.active_encounter.is_empty() and state.active_encounter.task=="site_mark" and state.active_encounter.get("site_checked",false) and not state.active_encounter.get("site_marked",false):
		var encounter := state.encounter_status()
		if state.region==int(encounter.region) and state.pos.distance_to(encounter.target_pos)<140:
			mark_territory()
			return
	for a in world.animals:
		if a.kind=="wolf" and a.p.distance_to(state.pos)<135:
			if state.elapsed-last_pack_visit<20:
				notify("Das Rudel bleibt bei dir. Lass ihm einen Moment Ruhe.")
				return
			last_pack_visit=state.elapsed
			state.pack_contacts+=1
			state.note_action("greet")
			state.note_main_story_action("greet","",a)
			state.skills.pack=mini(100,int(state.skills.pack)+2)
			state.bond=minf(100,state.bond+8)
			state.record("Rudelmoment · Du begrüßt die Familie mit einem freundlichen Stupser und vertrauten Gerüchen.")
			notify("Ein vertrauter Stupser. Eure Bindung wächst; das Rudel begleitet dich in der Lichtung.")
			check_quests()
			return
	var best: Dictionary={}
	var distance := 9999.0
	for t in world.tracks:
		var d: float=t.p.distance_to(state.pos)
		if d<100 and d<distance and scent_time>0 and not state.found.has(t.id):
			best=t
			distance=d
	if not best.is_empty():
		state.found.append(best.id)
		state.skills.nose=mini(100,int(state.skills.nose)+1)
		player_mood="schnüffeln";action_timer=2
		state.record("Fährte · "+best.species+" im Gebiet "+WolfWorldData.REGIONS[state.region].name+". Die Trittsiegel sind noch frisch.")
		notify("Eine frische "+best.species+"fährte. Deine Nase lernt diesen Duft kennen.")
		check_quests()
		return
	for obj in world.objects:
		var d: float=obj.p.distance_to(state.pos)
		match obj.kind:
			"water":
				if (obj.variant==0 and d<190*obj.scale+90) or (obj.variant==1 and absf(state.pos.x-WolfWorldData.river_x(state.pos.y))<155):
					state.thirst=100
					player_mood="trinken";action_timer=3
					state.drank=true
					state.note_action("drink")
					notify("Du trinkst kühles Wasser. Dein Durst ist gestillt.")
					check_quests()
					return
			"den":
				if d<190:
					rest()
					return
			"discovery":
				if d<140:
					inspect_nature_site(obj)
					return
			"landmark":
				if d<100:
					if not state.landmarks.has(state.region):
						state.landmarks.append(state.region)
						state.record("Wegstein · "+WolfWorldData.REGIONS[state.region].name+". Moose und fremde Düfte verraten, wer hier vorbeikam.")
					notify("Ein alter Wegstein. Du prägst dir den Ort und seine Gerüche ein.")
					check_quests()
					return
	if first_person and observe():return
	notify("Nichts in unmittelbarer Nähe. Schnüffle nach Spuren oder nähere dich Wasser und Wegsteinen.")

func inspect_nature_site(obj: Dictionary) -> void:
	state.note_action("site",obj.site)
	if not state.sites.has(obj.site):
		state.sites.append(obj.site)
		state.xp+=5
	if not state.discoveries.has(state.region):
		state.discoveries.append(state.region)
		state.xp+=15
		state.record("Entdeckung · "+WolfWorldData.REGIONS[state.region].name+". Ein geschützter Naturort voller neuer Düfte.")
	notify(obj.title+" · "+obj.description)
	check_quests()

func observation_candidate(for_main_story: bool=false,for_nature_journey: bool=false) -> Dictionary:
	var forward := Vector2(-sin(world_view.yaw),-cos(world_view.yaw))
	var nearest: Dictionary={}
	var closest := INF
	var locked_key := str(state.main_story_status().get("watch_animal","")) if for_main_story else str(state.nature_journey_status().get("watch_animal","")) if for_nature_journey else str(state.active_encounter.get("watch_animal",""))
	for a in world.animals:
		if (for_main_story or for_nature_journey) and a.kind!="deer":continue
		if not locked_key.is_empty() and WolfPackLife.animal_key(a)!=locked_key:continue
		var diff: Vector2=a.p-state.pos
		if a.kind=="wolf" or diff.length()<145 or diff.length()>420:continue
		if forward.dot(diff.normalized())<0.94 or world_view.pitch < -0.7:continue
		# Trees and rocks block an observation, just as they block the view.
		var blocked := false
		for obj in world.objects:
			if obj.kind not in ["tree","rock","den"]:continue
			var t := clampf((obj.p-state.pos).dot(diff)/diff.length_squared(),0,1)
			if t>0.04 and t<0.96 and (state.pos+diff*t).distance_to(obj.p)<WolfWorldData.solid_radius(obj)+10:
				blocked=true
				break
		if blocked:continue
		if not locked_key.is_empty() and WolfPackLife.animal_key(a)==locked_key:return a
		if diff.length()<closest:nearest=a;closest=diff.length()
	return nearest

func _quiet_player_speed() -> float:
	# Pressing toward a blocked body is movement intent, not quiet listening.
	return maxf(player_speed,2.0) if player_mood=="laufen" else player_speed

func _tick_wildlife_observation(dt: float) -> void:
	if state.active_encounter.is_empty() or state.active_encounter.task not in ["quiet_watch","wildlife_cycle"]:return
	var animal := observation_candidate() if first_person else {}
	var species := WolfWorldData.species(animal.kind) if not animal.is_empty() else ""
	state.tick_wildlife_observation(minf(dt,0.1),species,animal,state.pos,_quiet_player_speed(),sneak_button.button_pressed or player_speed<1)

func observe() -> bool:
	var story := state.main_story_status()
	var for_story: bool=story.started and not story.done and story.action=="watch"
	var journey := state.nature_journey_status()
	var for_journey: bool=journey.accepted and not journey.ready and journey.action=="watch"
	var prefer_journey: bool=for_journey and (not for_story or guided_main_story.is_empty())
	var animal := observation_candidate(for_story and not prefer_journey,prefer_journey)
	if animal.is_empty():return false
	var species := WolfWorldData.species(animal.kind)
	state.note_action("observe",species)
	if first_person:state.note_nature_journey_observation(animal,player_speed,sneak_button.button_pressed or player_speed<1,true)
	if for_story and first_person:state.note_main_story_observation(animal,player_speed,sneak_button.button_pressed or player_speed<1,true)
	if first_person:state.note_wildlife_observation(species,animal,state.pos,player_speed,sneak_button.button_pressed or player_speed<1)
	if not state.observations.has(species):
		state.observations.append(species)
		state.skills.stealth=mini(100,int(state.skills.stealth)+5)
		state.record("Beobachtung · "+species+". Du bleibst auf Abstand und beobachtest leise aus dem Wolfsblick.")
	notify("Du beobachtest ein "+species+". Es lauscht und prüft seine Umgebung.")
	if not state.active_encounter.is_empty() and state.active_encounter.task in ["quiet_watch","wildlife_cycle"]:notify("Bleibe mit Abstand ruhig und halte dasselbe Tier im Blick. Die Leiste zeigt dir, was gerade zählt.")
	check_quests()
	return true

func howl() -> void:
	if howl_cooldown>0:
		notify("Lausche erst auf die Antwort des Rudels.")
		return
	howl_cooldown=8
	player_mood="heulen";action_timer=3
	if state.sound_enabled and not app_idle and not is_instance_valid(overlay):play_howl()
	if state.region==0 and state.pos.distance_to(Vector2(1600,2240))<460:
		state.bond=minf(100,state.bond+4)
		state.howled=true
		state.note_action("howl")
		notify("Dein Rudel antwortet mit vertrauten Stimmen. Du bist nicht allein.")
	else:notify("Dein Ruf trägt durch die Wildnis. Eine ferne Antwort kommt aus dem Tal.")
	check_quests()

func play_howl() -> void:
	var bytes := PackedByteArray()
	var rate := 22050
	bytes.resize(rate*2*2)
	for i in range(rate*2):
		var t := float(i)/rate
		var envelope := sin(t*PI/2.0)*0.16
		var sample := int(sin(TAU*(310*t+30*sin(t*1.8)))*envelope*32767)
		bytes.encode_s16(i*2,sample)
	var stream := AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=rate
	stream.data=bytes
	sound.stream=stream
	sound.play()

func rest() -> void:
	if rest_cooldown>0:
		notify("Lass deinem Körper einen Moment Ruhe, bevor du dich erneut niederlegst.")
		return
	for obj in world.objects:
		if obj.kind=="den" and state.pos.distance_to(obj.p)<190:
			rest_cooldown=12
			state.energy=minf(100,state.energy+30)
			state.rested=true
			state.note_action("rest")
			player_mood="ruhen";action_timer=8
			notify("Du ruhst im Schutz der Höhle. Die vertrauten Düfte geben dir Sicherheit.")
			check_quests()
			return
	notify("Hier ist es zu offen. Suche die geschützte Umgebung einer Höhle zum Ruhen.")

func check_quests() -> void:
	for q in state.quests():
		if q.done and not state.completed.has(q.id):
			if state.tracked_quest==q.id:state.tracked_quest=""
			state.completed.append(q.id)
			state.xp+=25
			state.record("Erlebnis abgeschlossen · "+q.name)
			notify("Erlebnis abgeschlossen: "+q.name+" · +25 Erfahrung")
			_save_game()

func _refresh_status() -> void:
	for key in need_bars:
		need_bars[key].value=state.get(key)
		need_labels[key].text={"hunger":"Nahrung","thirst":"Wasser","energy":"Kraft","bond":"Rudel"}[key]+" %d"%state.get(key)
	level_label.text="%d Wochen · Rang %d · Wildnis %d/%d"%[state.age_weeks(),state.level(),state.visited.size(),WolfWorldData.REGIONS.size()]
	title.text=WolfWorldData.REGIONS[state.region].name
	location_hint.text="Tag %d · %02d:%02d · %s"%[state.day(),int(state.hour()),int(fmod(state.hour(),1)*60),state.weather()]
	compact_needs.text="N%d  W%d  K%d  R%d"%[int(state.hunger),int(state.thirst),int(state.energy),int(state.bond)]
	compact_needs.add_theme_color_override("font_color",Color("#f3ca7f") if minf(state.hunger,minf(state.thirst,state.energy))<25 else Color("#d4d9c0"))
	var encounter: Dictionary=state.encounter_status()
	if encounter_button!=null:encounter_button.text="Begegnung ✓" if encounter.done else "Begegnung · "+encounter.progress if encounter.accepted else "Neue Begegnung"
	var story := state.main_story_status()
	story_button.text="Geschichte •" if story.ready else "Geschichte"
	stats.text="Nahrung %d   Wasser %d   Kraft %d   Rudel %d"%[state.hunger,state.thirst,state.energy,state.bond]
	quest_hint.text="Alle Erlebnisse entdeckt. Folge neuen Fährten und erkunde die Wildnis."
	for q in state.quests():
		if (state.tracked_quest.is_empty() and not q.done) or q.id==state.tracked_quest:
			quest_hint.text="◌ "+q.name+" · "+q.progress
			break

	if state.waypoint_region>=0:
		var points := navigation_route()
		var direction := WolfTrailNavigation.bearing(WolfTrailNavigation.next_direction(points))
		var steps := ceili(WolfTrailNavigation.length(points)/25.0)
		quest_hint.text="◎ %s · etwa %d Pfotenschritte"%[direction,steps] if not points.is_empty() else "◎ Suche den nächsten freien Weg zum Duftziel."
		if state.waypoint_region!=state.region:
			var route := route_to(state.waypoint_region)
			if not route.is_empty():quest_hint.text+="\nÜbergang nach "+WolfWorldData.REGIONS[route[0]].name
	var journey := state.nature_journey_status()
	var prefer_journey: bool=journey.accepted and guided_main_story.is_empty()
	if story.started and not story.done:quest_hint.text="Hauptgeschichte · "+story.progress
	if prefer_journey:quest_hint.text="Naturreise · "+journey.progress
	_refresh_observation_hud()
	if prefer_journey:
		_refresh_main_story_presence_hud()
		_refresh_nature_journey_hud()
	else:
		_refresh_nature_journey_hud()
		_refresh_main_story_presence_hud()

	_layout_mission_hud()
	_update_bottom_labels()

func wildlife_activity_name(activity: String) -> String:
	return {"forage":"Nahrung suchen","drink":"Trinken","shelter":"Geschützt ruhen","roaming":"Unterwegs","wandern":"Unterwegs","lauschen":"Lauschen","fliehen":"Aufgeschreckt","fressen":"Fressen","grasen":"Grasen","schnüffeln":"Duft prüfen","trinken":"Trinken","ruhen":"Ruhen","laufen":"Unterwegs"}.get(activity,"Lauschen")

func _refresh_observation_hud() -> void:
	if not is_instance_valid(observation_panel):return
	observation_panel.hide()
	if is_instance_valid(overlay):return
	var encounter := state.encounter_status()
	if encounter.accepted and not encounter.done and encounter.task=="pack_walk":
		observation_panel.show();observation_progress.show()
		observation_progress.max_value=3;observation_progress.value=float(encounter.get("joint_seconds",0))
		observation_title.text="Gemeinsamer Weg · Ruhepunkt "+("2" if encounter.get("pack_first",false) else "1")
		if not state.escort:observation_hint.text="Nimm im Rudelmenü die Begleitung wieder auf."
		elif not encounter.get("player_ready",false):observation_hint.text="Folge dem Duftziel zum gemeinsamen Ruhepunkt."
		elif not encounter.get("companion_ready",false):observation_hint.text="Warte, bis der Elternwolf neben dir angekommen ist."
		elif player_speed>1:observation_hint.text="Bleib einen Moment bei deinem Elternwolf stehen."
		else:observation_hint.text="Gemeinsam lauschen · %.1f / 3 ruhige Sekunden"%float(encounter.get("joint_seconds",0))
		return
	if not first_person:return
	var animal := observation_candidate()
	var watching: bool=encounter.accepted and not encounter.done and encounter.task in ["quiet_watch","wildlife_cycle"]
	if animal.is_empty() and not watching:return
	observation_panel.show()
	observation_progress.visible=watching
	if animal.is_empty():
		observation_title.text="Ein ruhiger Blick bleibt"
		observation_hint.text="Suche dasselbe Tier mit Abstand im Wolfsblick."
	else:
		var activity := str(animal.get("mood","lauschen"))
		observation_title.text=WolfWorldData.species(animal.kind)+" · "+wildlife_activity_name(activity)+" · %d Pfotenschritte"%maxi(1,roundi(animal.p.distance_to(state.pos)/25.0))
		observation_hint.text="Wähle Beobachten, um diesen Augenblick kennenzulernen."
	if not watching:return
	observation_progress.max_value=3 if encounter.task=="wildlife_cycle" else 12
	observation_progress.value=float(encounter.get("activity_seconds",0) if encounter.task=="wildlife_cycle" else encounter.get("watch_seconds",0))
	if not encounter.get("watch_started",false):
		observation_hint.text="Nähere dich leise. Wähle bei ruhigen Pfoten Beobachten."
	elif animal.is_empty():pass
	elif WolfPackLife.animal_key(animal)!=str(encounter.get("watch_animal","")):
		observation_hint.text="Halte das zu Beginn beobachtete Tier im Blick."
	elif player_speed>1:
		observation_hint.text="Bleib stehen und halte den Blick ruhig."
	elif str(animal.get("mood",""))=="fliehen" or float(animal.get("alarm",0))>0:
		observation_hint.text="Das Tier ist aufgeschreckt. Warte mit Abstand."
	elif encounter.task=="wildlife_cycle":
		var current := str(encounter.get("current_activity",""))
		var first := str(encounter.get("first_activity",""))
		if encounter.get("cycle_first",false) and (current.is_empty() or current==first):observation_hint.text="Schon gesehen: "+wildlife_activity_name(first)+". Warte auf eine andere Aktivität."
		elif not current.is_empty():observation_hint.text=wildlife_activity_name(current)+" · %.1f / 3 ruhige Sekunden"%float(encounter.get("activity_seconds",0))
		else:observation_hint.text="Warte, bis das Tier an Nahrung, Wasser oder Deckung angekommen ist."
	else:observation_hint.text="Ruhiger Blick · %.1f / 12 aktive Sekunden"%float(encounter.get("watch_seconds",0))

func context_action() -> String:
	var main_action := _main_story_context()
	var nature_action := _nature_journey_context()
	if state.nature_journey_status().accepted and guided_main_story.is_empty():
		if not nature_action.is_empty():return nature_action
		if not main_action.is_empty():return main_action
	else:
		if not main_action.is_empty():return main_action
		if not nature_action.is_empty():return nature_action
	if state.food_cooldown<=0:
		for obj in world.objects:
			if obj.kind=="food" and obj.p.distance_to(state.pos)<85:return "Fressen"
	if not state.active_encounter.is_empty() and state.active_encounter.task=="site_mark" and not state.active_encounter.get("site_checked",false):
		for obj in world.objects:
			if obj.kind=="discovery" and obj.site==state.active_encounter.site_id and obj.p.distance_to(state.pos)<140:return "Ort prüfen"
	if not state.active_encounter.is_empty() and state.active_encounter.task=="site_mark" and state.active_encounter.get("site_checked",false) and not state.active_encounter.get("site_marked",false):
		var encounter := state.encounter_status()
		if state.region==int(encounter.region) and state.pos.distance_to(encounter.target_pos)<140:return "Duft setzen"
	if not state.active_encounter.is_empty() and ((state.active_encounter.task=="water_rest" and state.active_encounter.get("drank_after_start",false)) or (state.active_encounter.task=="care_route" and state.active_encounter.get("care_feed",false))):
		for obj in world.objects:
			if obj.kind=="den" and obj.p.distance_to(state.pos)<190:return "Ruhen"
	for a in world.animals:
		if a.kind=="wolf" and a.p.distance_to(state.pos)<135:return "Begrüßen"
	for t in world.tracks:
		if scent_time>0 and not state.found.has(t.id) and t.p.distance_to(state.pos)<100:return "Spur lesen"
	for obj in world.objects:
		var d: float=obj.p.distance_to(state.pos)
		if obj.kind=="water" and ((obj.variant==0 and d<190*obj.scale+90) or (obj.variant==1 and absf(state.pos.x-WolfWorldData.river_x(state.pos.y))<155)):return "Trinken"
		if obj.kind=="food" and d<85 and state.food_cooldown<=0:return "Fressen"
		if obj.kind=="den" and d<190:return "Ruhen"
		if (obj.kind=="landmark" and d<100) or (obj.kind=="discovery" and d<140):return "Entdecken"
	return "Beobachten" if first_person else "Aktion"

func route_to(target: int) -> Array[int]:
	var path: Array[int]=[]
	if target<0 or target>=WolfWorldData.REGIONS.size() or target==state.region:return path
	var queue: Array[int]=[state.region]
	var previous := {state.region:-1}
	while not queue.is_empty():
		var current: int=queue.pop_front()
		if current==target:break
		for neighbor in WolfWorldData.REGIONS[current].links.values():
			if not previous.has(neighbor):previous[neighbor]=current;queue.append(neighbor)
	if not previous.has(target):return path
	var cursor := target
	while cursor!=state.region:path.push_front(cursor);cursor=previous[cursor]
	return path

func goal_position() -> Vector2:
	if state.waypoint_region==state.region:return state.waypoint_pos
	var route := route_to(state.waypoint_region)
	if route.is_empty():return state.pos
	for direction in WolfWorldData.REGIONS[state.region].links:
		if WolfWorldData.REGIONS[state.region].links[direction]==route[0]:
			return {"north":Vector2(1600,0),"south":Vector2(1600,3200),"west":Vector2(0,1600),"east":Vector2(3200,1600)}[direction]
	return state.pos

func navigation_route(force: bool=false) -> PackedVector2Array:
	if state.waypoint_region<0:
		navigation_points=PackedVector2Array()
		return navigation_points
	if not world.has("_animal_motion"):
		var motion := WolfAnimalMotion.new()
		motion.configure(state.region,world.objects)
		world._animal_motion=motion
	trail_navigation.configure(state.region,world._animal_motion)
	navigation_points=trail_navigation.route(state.pos,goal_position(),clock,force)
	return navigation_points

func navigation_summary() -> String:
	if state.waypoint_region<0:return "Wähle einen Duft im Atlas."
	var points := navigation_route()
	if points.is_empty():return "Hier führt noch kein sicherer Pfad zum Duftziel. Versuche einen nahen Weg."
	var bearing := WolfTrailNavigation.bearing(WolfTrailNavigation.next_direction(points))
	var steps := maxi(1,ceili(WolfTrailNavigation.length(points)/25.0))
	if state.waypoint_region==state.region:
		return "%s · etwa %d Pfotenschritte entlang sicherer Wege"%[bearing,steps]
	var route := route_to(state.waypoint_region)
	if route.is_empty():return "Duftziel in diesem Gebiet."
	return "%s · %d Pfotenschritte zum Übergang · dann %s"%[bearing,steps,WolfWorldData.REGIONS[route[0]].name]

func guide_resource(kind: String) -> bool:
	var navigation := WolfAnimalMotion.new()
	navigation.configure(state.region,world.objects)
	var target := Vector2(INF,INF)
	if kind=="water":target=WolfWorldData.water_bank(state.region)
	elif kind in ["den","food"]:
		var nearest := INF
		for obj in world.objects:
			if obj.kind!=kind:continue
			var approach := navigation.nearest_free(obj.p+Vector2(0,-115) if kind=="den" else obj.p,140)
			if approach.is_finite() and state.pos.distance_to(approach)<nearest:
				nearest=state.pos.distance_to(approach);target=approach
	if not target.is_finite():return false
	set_waypoint(state.region,target)
	close_overlay()
	notify({"water":"Deine Nase führt dich zum festen Trinkufer.","food":"Deine Nase führt dich zu einem vertrauten Futterplatz.","den":"Deine Nase führt dich in die Nähe eines geschützten Ruheplatzes."}.get(kind,"Folge dem Duftziel."))
	return true

func set_waypoint(region: int,point: Vector2) -> void:
	if region<0 or region>=WolfWorldData.REGIONS.size():return
	guided_encounter_id=""
	guided_main_story=""
	guided_nature_journey=""
	point=point.clamp(Vector2(20,20),WolfWorldData.SIZE-Vector2(20,20))
	state.waypoint_region=region
	state.waypoint_pos=point
	var data: Dictionary=world if region==state.region else WolfWorldData.generate(region)
	if WolfWorldData.water_blocked(point,region) or not WolfWorldData.walkable(point,data.objects):
		var resolved := false
		for radius in [55,120,260,440]:
			for i in range(16):
				var q: Vector2=point+Vector2(cos(i*TAU/16),sin(i*TAU/16))*radius
				if Rect2(Vector2(20,20),Vector2(3160,3160)).has_point(q) and WolfWorldData.walkable(q,data.objects) and not WolfWorldData.water_blocked(q,region):state.waypoint_pos=q;resolved=true;break
			if resolved:break
	_save_game()
	if is_instance_valid(map_panel):map_panel.queue_redraw()
	if is_instance_valid(map_selection):map_selection.text="Duftziel: "+WolfWorldData.REGIONS[region].name+"\n"+navigation_summary()

func close_overlay(resume_audio: bool=true) -> void:
	_cancel_touch_inputs()
	Input.emulate_mouse_from_touch=false
	if is_instance_valid(overlay):
		ui.remove_child(overlay)
		overlay.queue_free()
		overlay=null
	look_pointer=-1
	looking_mouse=false
	stick.reset()
	if resume_audio:
		toast.show()
		_refresh_status()
		_sync_audio()

func modal(heading: String,full_bleed: bool=false) -> VBoxContainer:
	close_overlay(false)
	Input.emulate_mouse_from_touch=true
	observation_panel.hide()
	toast.hide()
	stick.reset()
	overlay=ColorRect.new()
	overlay.color=Color(0.025,0.08,0.06,0.98)
	_sync_audio()
	ui.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	var margin := MarginContainer.new()
	overlay.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,12 if full_bleed else 26)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,18 if full_bleed else 38)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	panel.add_theme_stylebox_override("panel",panel_style(Color("#193d31"),24))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",16)
	panel.add_child(stack)
	var row := HBoxContainer.new()
	stack.add_child(row)
	var h := label(heading,27)
	h.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(h)
	row.add_child(button("×",close_overlay))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",18)
	scroll.add_child(content)
	return content

func card(parent: VBoxContainer,heading: String,body: String,accent: Color=Color("#587e59")) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",panel_style(Color("#274c3b"),18))
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",8)
	panel.add_child(stack)
	var title_label := label(heading,21)
	title_label.add_theme_color_override("font_color",accent.lightened(0.45))
	stack.add_child(title_label)
	if not body.is_empty():stack.add_child(label(body,17))
	return stack

func hero(parent: VBoxContainer,caption: String,height: float=180) -> void:
	var art := WolfMenuArt.new()
	art.game=self;art.caption=caption
	art.custom_minimum_size=Vector2(0,height)
	parent.add_child(art)

func nav_tile(parent: GridContainer,heading: String,subtitle: String,glyph: String,callback: Callable) -> void:
	var tile := button("",callback)
	tile.custom_minimum_size=Vector2(0,138)
	tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(tile)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for side in ["top","bottom","left","right"]:margin.add_theme_constant_override("margin_"+side,12)
	tile.add_child(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation",5)
	margin.add_child(stack)
	var art := WolfMenuArt.new();art.kind=glyph
	art.custom_minimum_size=Vector2(30,30)
	art.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	stack.add_child(art)
	var heading_label := label(heading,16)
	heading_label.custom_minimum_size.x=0
	stack.add_child(heading_label)
	var detail := label(subtitle,12)
	detail.add_theme_color_override("font_color",Color("#b3c9ad"))
	stack.add_child(detail)

func show_menu() -> void:
	var v := modal("Dein Rudelleben")
	v.add_child(button("Hauptgeschichte\n"+str(state.main_story_status().title),show_main_story))
	hero(v,"DEIN PFAD DURCH EINE LEBENDIGE WILDNIS",190)
	v.add_child(button("Zurück in die Wildnis",close_overlay))
	card(v,"%s · Tag %d"%[state.season_name(),state.day()],"%d Wochen · %s · Rang %d\n%d/%d Gebiete · %d Naturorte · Bindung %d"%[state.age_weeks(),state.time_name(),state.level(),state.visited.size(),WolfWorldData.REGIONS.size(),state.sites.size(),state.bond])
	var grid := GridContainer.new()
	grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10)
	v.add_child(grid)
	var chapters := state.story_scenes().size()
	nav_tile(grid,"Rudelerinnerungen","Kapitel %d/%d"%[mini(state.story_step+1,chapters),chapters],"book",show_story)
	nav_tile(grid,"Naturreisen","Sechs Wege für deine Nase","leaf",show_nature_journeys)
	nav_tile(grid,"Wildnisatlas","Wege, Naturorte & Ziele","map",show_map)
	nav_tile(grid,"Deine Familie","Nähe & Begleitung","paw",show_pack)
	nav_tile(grid,"Begegnungen","Neue Düfte und Aufgaben","compass",show_encounter)
	nav_tile(grid,"Erlebnisse","%d Erinnerungen erfüllt"%state.completed.size(),"leaf",show_quests)
	nav_tile(grid,"Naturtagebuch","Deine Wege bleiben","journal",show_journal)
	nav_tile(grid,"Sichere Wege","Wasser, Nahrung & Rast","compass",show_travel_help)
	nav_tile(grid,"Tierwissen","Tiere & Trittsiegel","leaf",show_field_guide)
	nav_tile(grid,"Atmosphäre","Darstellung & Naturklang","compass",show_settings)
	var skills_card := card(v,"Was deine Pfoten lernen","Nase %d · Leise Pfoten %d · Rudelerfahrung %d"%[state.skills.nose,state.skills.stealth,state.skills.pack])
	skills_card.add_child(button("Eigenen Duft markieren",func():close_overlay();mark_territory()))
	skills_card.add_child(button("Hier ruhen",func():close_overlay();rest()))
	v.add_child(button("Steuerung & Einstieg",show_intro))
	v.add_child(button("Spielstand sichern",func():
		var saved := _save_game();close_overlay()
		notify("Dein Spielstand wurde gespeichert." if saved else "Spielstand konnte nicht gespeichert werden.")
	))
	v.add_child(button("Neues Rudelleben starten",confirm_new_game))
	v.add_child(label("Wolf 0.10.0 · Vertraute Wege",13))

func show_travel_help() -> void:
	var v := modal("Nase & sichere Wege")
	hero(v,"WIND PRÜFEN · DECKUNG FINDEN · HEIMKEHREN",145)
	card(v,"Was du gerade brauchst","Nahrung %d · Wasser %d · Kraft %d\n%s · %s"%[state.hunger,state.thirst,state.energy,WolfWorldData.REGIONS[state.region].name,state.time_name()])
	for item in [["water","Zum festen Trinkufer"],["food","Einen Futterplatz finden"],["den","Einen geschützten Ruheplatz finden"]]:
		var kind: String=item[0]
		v.add_child(button(item[1],func():guide_resource(kind)))
	if state.region!=0:
		v.add_child(button("Zum vertrauten Rudel zurück",func():set_waypoint(0,Vector2(1580,2025));close_overlay();notify("Folge den Übergängen zurück zur Rudelhöhle.")))
	if state.waypoint_region>=0:card(v,"Dein nächster Weg",navigation_summary())
	card(v,"Orientierung aus der Nähe","Die Pfotenschritte folgen dem sicheren Weg, auch um Felsen und über Brücken. N, O, S und W zeigen die erste Richtung. Die Gebietskarte zeichnet den Verlauf; freie Deckung und Tiere können sich verändern.")
	v.add_child(button("Gebietskarte öffnen",func():show_map();map_panel.set_local(state.region)))
	v.add_child(button("Weiter erkunden",close_overlay))

func show_encounter() -> void:
	var v := modal("Wildnisbegegnung")
	var encounter: Dictionary=state.encounter_status()
	hero(v,encounter.title.to_upper(),150)
	if encounter.done:
		v.add_child(button("Die Erfahrung mitnehmen · +%d"%encounter.reward,func():
			if state.complete_encounter():_save_game();check_quests();show_encounter()
		))
	elif not encounter.accepted:
		v.add_child(button("Diesem Duft folgen",func():
			if state.begin_encounter():guide_encounter();close_overlay();_refresh_status()
		))
	card(v,encounter.title,encounter.text,Color("#bfa367"))
	var task_name: String={"tracks":"Eine frische Fährte","sites":"Geschützte Naturorte","journey":"Ein eigener Weg","visit":"Jenseits vertrauter Kronen","observe":"Mit ruhigen Pfoten beobachten","water_rest":"Wasser und Geborgenheit","family":"Eine vertraute Antwort","care_route":"Ein sicherer Versorgungsweg","edge_pair":"Zwei Arten in einer Landschaft","quiet_watch":"Ein ruhiger Blick bleibt","site_mark":"Einen Ort am Duft wiedererkennen","pack_walk":"Zwei gemeinsame Ruhepunkte","wildlife_cycle":"Der Tageslauf eines Tieres"}.get(encounter.task,"Dein nächster Schritt")
	var task_card := card(v,task_name,encounter.hint)
	if encounter.accepted:
		var progress := ProgressBar.new()
		progress.max_value=encounter.goal;progress.value=encounter.current
		progress.custom_minimum_size.y=14;progress.show_percentage=false
		task_card.add_child(progress)
		task_card.add_child(label(encounter.progress,15))
		if encounter.task=="water_rest":
			task_card.add_child(label(("✓" if encounter.get("drank_after_start",false) else "○")+"  Frisches Wasser trinken",17))
			task_card.add_child(label(("✓" if encounter.get("rested_after_drink",false) else "○")+"  Danach im Schutz ruhen",17))
		elif encounter.task=="family":
			task_card.add_child(label(("✓" if encounter.get("greeted_family",false) else "○")+"  Familie begrüßen",17))
			task_card.add_child(label(("✓" if encounter.get("family_howl",false) else "○")+"  Nahe der Heimat heulen",17))
		elif encounter.task=="care_route":
			for step in [["care_drink","Am sicheren Ufer trinken"],["care_feed","Danach den gewählten Futterplatz nutzen"],["care_rest","Zuletzt im Schutz ruhen"]]:
				task_card.add_child(label(("✓" if encounter.get(step[0],false) else "○")+"  "+step[1],17))
		elif encounter.task=="edge_pair":
			task_card.add_child(label(("✓" if encounter.get("pair_first",false) else "○")+"  Die erste Art leise beobachten",17))
			task_card.add_child(label(("✓" if encounter.get("pair_second",false) else "○")+"  Die zweite Art aus Abstand beobachten",17))
		elif encounter.task=="site_mark":
			task_card.add_child(label(("✓" if encounter.get("site_checked",false) else "○")+"  Den gewählten Naturort prüfen",17))
			task_card.add_child(label(("✓" if encounter.get("site_marked",false) else "○")+"  Hier den eigenen Duft setzen",17))
		elif encounter.task=="quiet_watch":
			task_card.add_child(label("%.1f / 12 aktive Sekunden\nHalte dasselbe ruhige Tier mit Abstand im Blick. Beobachten beginnt die Erfahrung; Wegsehen und Bewegung zählen nicht."%float(encounter.get("watch_seconds",0)),16))
		elif encounter.task=="pack_walk":
			for step in [["pack_first","Gemeinsam am ersten Ruhepunkt ankommen"],["pack_second","Danach zusammen zum zweiten Ruhepunkt gehen"]]:
				task_card.add_child(label(("✓" if encounter.get(step[0],false) else "○")+"  "+step[1],17))
			task_card.add_child(label("%.1f / 3 ruhige Sekunden · %s"%[float(encounter.get("joint_seconds",0)),"Der Elternwolf ist in deiner Nähe." if encounter.get("companion_ready",false) else "Warte, bis der Elternwolf neben dir ankommt."],16))
			if not state.escort:task_card.add_child(button("Begleitung wieder aufnehmen",show_pack))
		elif encounter.task=="wildlife_cycle":
			var first := str(encounter.get("first_activity",""))
			task_card.add_child(label(("✓  "+wildlife_activity_name(first)) if encounter.get("cycle_first",false) else "○  Eine ruhige Aktivität beobachten",17))
			task_card.add_child(label(("✓" if encounter.get("cycle_second",false) else "○")+"  Dasselbe Tier bei einer anderen Aktivität sehen",17))
			task_card.add_child(label("Jede Aktivität zählt nach drei ruhigen Sekunden am echten Ziel. Nahrung, Wasser und Deckung sind unterschiedliche Stationen.",16))
	else:task_card.add_child(label("Neue Begegnung · Du bestimmst den ersten Schritt.",15))
	if encounter.accepted and not encounter.done:
		v.add_child(button("Den Weg in der Karte zeigen",func():guide_encounter();close_overlay()))
		if encounter.task in ["observe","edge_pair","quiet_watch","wildlife_cycle"] and not first_person:
			v.add_child(button("In den Wolfsblick wechseln",func():
				if state.camera_follow:switch_camera()
				close_overlay();toggle_view()
			))
		v.add_child(button("Für später lassen",func():state.abandon_encounter();_save_game();show_menu()))
	card(v,"Dein eigenes Tempo","Begegnungen wachsen aus deinen tatsächlichen Wegen: einer frischen Spur, einem ruhigen Blick, Wasser oder der Nähe deines Rudels. Dein nächster Schritt beginnt draußen.")
	v.add_child(button("Weiter erkunden",close_overlay))

func guide_encounter() -> void:
	var encounter := state.encounter_status()
	var target: int=encounter.target_region
	var point: Vector2=encounter.target_pos
	if target==state.region and encounter.task in ["tracks","sites"]:
		for obj in world.tracks if encounter.task=="tracks" else WolfWorldData.nature_sites(state.region):
			var known: bool=state.found.has(obj.id) if encounter.task=="tracks" else state.sites.has(obj.site)
			if not known:point=obj.p;break
	if target==state.region and (encounter.task in ["observe","edge_pair","quiet_watch","wildlife_cycle"] or (encounter.task=="family" and not encounter.get("greeted_family",false))):
		var nearest := INF
		for animal in world.animals:
			var matches: bool=animal.kind=="wolf" if encounter.task=="family" else WolfWorldData.species(animal.kind)==encounter.get("detail","Reh")
			if not matches:continue
			if encounter.get("watch_started",false) and WolfPackLife.animal_key(animal)!=str(encounter.get("watch_animal","")):continue
			var distance: float=animal.p.distance_to(state.pos)
			if distance<nearest:
				nearest=distance
				point=animal.p+Vector2(0,230) if encounter.task in ["observe","edge_pair","quiet_watch","wildlife_cycle"] else animal.p+Vector2(30,0)
	set_waypoint(target,point)
	guided_encounter_id=str(encounter.id)
	guided_progress=int(encounter.current)
	if encounter.task in ["observe","edge_pair","quiet_watch","wildlife_cycle"]:notify("Nähere dich leise mit Abstand. Im Wolfsblick richtest du den Blick auf das Tier und wählst Beobachten.")
	elif encounter.task=="journey":notify("Gehe deinen eigenen Weg. Der Fortschritt zählt deine tatsächlich gegangenen Pfotenschritte.")
	else:notify(encounter.hint)

func _refresh_encounter_guide() -> void:
	if guided_encounter_id.is_empty():return
	var encounter: Dictionary=state.encounter_status()
	if not encounter.accepted or str(encounter.id)!=guided_encounter_id:
		guided_encounter_id="";return
	if encounter.done:
		guided_encounter_id=""
		notify("Deine Begegnung ist erfüllt. Öffne Begegnungen, um die Erfahrung mitzunehmen.")
		return
	if int(encounter.current)!=guided_progress and encounter.task in ["tracks","sites","water_rest","family","care_route","edge_pair","site_mark","pack_walk","wildlife_cycle"]:guide_encounter()

func show_intro() -> void:
	var v := modal("Wolf · Wildnis & Rudel")
	hero(v,"DEIN LEBEN ZWISCHEN WALD UND WEITEN",210)
	v.add_child(label("Deine Welt beginnt am Geruch.",26))
	v.add_child(button("Die erste Pfote setzen",close_overlay))
	v.add_child(button("Hauptgeschichte beginnen",_begin_main_story))
	card(v,"Deine ersten Schritte","Begrüße die Familie nahe der Höhle. Trinke am Ufer. Schnüffle auf den Wegen und lies drei frische Fährten. Die Rudelgeschichte erinnert sich an das, was du selbst erlebst.")
	v.add_child(button("Den Weg zum kühlen Ufer zeigen",func():set_waypoint(state.region,WolfWorldData.water_bank(state.region));close_overlay();notify("Der Kompass führt dich zum sicheren Trinkufer. Dort wählst du Trinken.")))
	card(v,"Ein Jungwolf im natürlichen Rudel","Du bist 16 Wochen alt. Mutter, Vater und Geschwister begleiten deinen Anfang. Du lernst langsam, liest Spuren, beobachtest Tiere und findest geschützte Orte. Dein Körper wächst mit den vergangenen Tagen.")
	card(v,"%d Gebiete · eine zusammenhängende Wildnis"%WolfWorldData.REGIONS.size(),"Kiefern, Wälder, Schnee, Moore, Quellen und Küste. Wege an den Kartenrändern führen ins nächste Gebiet. Die Karte lässt sich ziehen und vergrößern; setze dort ein Duftziel für den Kompass.")
	card(v,"Pfoten & Wolfsblick","Der Stick bewegt dich in alle Richtungen. Schnüffeln zeigt Fährten; die Aktion passt sich der Umgebung an. In 3D wischst du über die Landschaft zum Umsehen. Nutze Leise, um Tiere mit Abstand zu beobachten.")
	card(v,"Eine Geschichte in kleinen Schritten","Rudelgeschichte erzählt deine Erlebnisse und bietet natürliche Entscheidungen. Menüs pausieren die Zeit. Ein Spieltag dauert 60 Minuten aktiver Spielzeit; Ruhen überspringt keine Tage.")
	v.add_child(label("Computer: WASD / Pfeile · V Ansicht · F Schnüffeln · E Aktion · H Heulen · R Ruhen · M Karte. In 3D: Maus ziehen oder I/J/K/L.",15))
	v.add_child(button("Die erste Pfote setzen",close_overlay))

func show_story() -> void:
	var v := modal("Rudelerinnerungen")
	hero(v,"EINE ERINNERUNG MIT JEDEM SCHRITT",170)
	var scenes := state.story_scenes()
	if state.story_step>=scenes.size():
		card(v,"Vertraute Heimat","Du hast alle %d Kapitel erlebt. Deine Geschichte geht mit den Spuren, Tagen und Begegnungen deiner Wildnis weiter. Die Erinnerungen bleiben im Tagebuch."%scenes.size())
		v.add_child(button("Erinnerungen lesen",show_journal))
		return
	var scene: Dictionary=scenes[state.story_step]
	v.add_child(label(scene.title,25))
	var progress := ProgressBar.new()
	progress.max_value=scenes.size();progress.value=state.story_step
	progress.show_percentage=false;progress.custom_minimum_size.y=10
	v.add_child(progress)
	v.add_child(label("Dein Wolf: %d Wochen · Bindung %d\n%s"%[state.age_weeks(),state.bond,WolfWorldData.REGIONS[state.region].name],15))
	card(v,"Wind, Pfoten und Gerüche",scene.text,Color("#b7a16f"))
	if not scene.ready:
		card(v,"Dein nächster Schritt",scene.gate)
		v.add_child(button("Den Weg zeigen",func():
			if state.story_step in [9,14,17] and state.completed_encounters.size()<[1,3,8][[9,14,17].find(state.story_step)]:show_encounter()
			elif state.story_step==11 and not state.escort:show_pack()
			else:guide_story();close_overlay()
		))
	else:
		v.add_child(label("Wie reagiert dein Wolf?",20))
		for i in range(scene.choices.size()):
			var choice_index := i
			v.add_child(button(scene.choices[i][0],func():
				if state.choose_story(choice_index):
					_save_game();check_quests();show_story()
			))
	v.add_child(button("Zurück in die Wildnis",close_overlay))

func guide_story() -> void:
	match state.story_step:
		1:set_waypoint(state.region,WolfWorldData.water_bank(state.region))
		2:
			for track in world.tracks:
				if not state.found.has(track.id):set_waypoint(state.region,track.p);break
		3:set_waypoint(0,Vector2(1530,2230))
		4:set_waypoint(3,Vector2(1600,1600))
		5:
			set_waypoint(state.region,world.animals[0].p+Vector2(0,230))
			notify("Nähere dich leise mit Abstand. Schalte auf 3D und richte den Blick auf das Reh.")
		6:
			for obj in world.objects:
				if obj.kind=="discovery" and not state.sites.has(obj.site):set_waypoint(state.region,obj.p);break
		7:
			if state.visited.size()<8:guide_new_region()
			else:set_waypoint(0,Vector2(1580,2025))
		8:set_waypoint(0,Vector2(1580,2025))
		9:guide_encounter()
		10:
			if state.sites.size()<6:guide_nature_site()
			else:guide_rest_place()
		11:set_waypoint(0,Vector2(1510,2170))
		12:
			for animal in world.animals:
				if animal.kind!="wolf" and not state.observations.has(WolfWorldData.species(animal.kind)):set_waypoint(state.region,animal.p+Vector2(0,230));break
		13:guide_new_region()
		16:
			if state.visited.size()<32:guide_new_region()
			else:
				var fresh := false
				for track in world.tracks:
					if not state.found.has(track.id):set_waypoint(state.region,track.p);fresh=true;break
				if not fresh:guide_encounter()
		14:
			if not state.marked.has(state.region):set_waypoint(state.region,state.pos)
			else:guide_new_region(true)
		15:
			if state.biome_count("snow")==0:set_waypoint(5,Vector2(1600,1600))
			elif state.biome_count("river")<2:set_waypoint(2 if not state.visited.has(2) else 6,Vector2(1600,1600))
			else:guide_nature_site()
		17:set_waypoint(0,Vector2(1580,2025))

func guide_nature_site() -> void:
	for obj in world.objects:
		if obj.kind=="discovery" and not state.sites.has(obj.site):set_waypoint(state.region,obj.p);return
	guide_new_region()

func guide_rest_place() -> void:
	var nearest := INF
	var target := state.pos
	for obj in world.objects:
		if obj.kind!="den":continue
		var distance: float=obj.p.distance_to(state.pos)
		if distance<nearest:nearest=distance;target=obj.p+Vector2(112,0)
	set_waypoint(state.region,target)

func guide_new_region(unmarked: bool=false) -> void:
	var queue: Array[int]=[state.region]
	var seen: Array[int]=[state.region]
	while not queue.is_empty():
		var current: int=queue.pop_front()
		for target in WolfWorldData.REGIONS[current].links.values():
			if seen.has(target):continue
			seen.append(target);queue.append(target)
			if not (state.marked.has(target) if unmarked else state.visited.has(target)):
				set_waypoint(target,Vector2(1600,1600));return

func _invite_pack_play() -> void:
	var nearby := false
	for animal in world.animals:
		if animal.kind == "wolf" and animal.p.distance_to(state.pos) < 210:
			nearby = true
			break
	close_overlay()
	if not nearby:
		notify("Zum Spielen brauchst du einen Wolf in deiner Nähe.")
		return
	if clock-last_pack_play < 18.0:
		notify("Dein Rudel verschnauft kurz. Lausche auf die nächsten Pfoten.")
		return
	last_pack_play = clock
	state.note_action("play")
	state.bond = minf(100,state.bond+1)
	state.record("Rudelmoment · Du lädst die Familie zum Toben ein und wartest auf ihre echten Schritte.")
	_save_game()
	check_quests()
	player_mood = "spielen"
	action_timer = 2.5
	notify("Spielzeit! Bleib bei deiner Familie und beobachte das Pfotenspiel.")

func show_pack() -> void:
	var v := modal("Deine Familie")
	hero(v,"VERTRAUTE STIMMEN · GEMEINSAME WEGE",180)
	card(v,"Natürliche Bindung","Ein vertrauter Geruch, ein Stupser, gemeinsames Heulen. Nähe und Ruhe stärken die Bindung. Dein Elternwolf wartet, wenn du dich umsiehst.")
	for role in ["Mutter","Vater","Geschwister"]:
		var routine: Dictionary=state.pack_routine(role)
		card(v,role+" · "+routine.label,routine.hint)
	var family_near := false
	for animal in world.animals:
		if animal.kind == "wolf" and animal.p.distance_to(state.pos) < 210:
			family_near = true
			break
	var play_button := button("🐾 Gemeinsam mit dem Rudel spielen",_invite_pack_play)
	play_button.disabled = not family_near
	v.add_child(play_button)
	if not family_near:v.add_child(label("Zum Spielen musst du deiner Familie nahe sein.",16))
	v.add_child(label("Bindung: %d / 100"%state.bond,20))
	var follow := button("Begleitung beenden" if state.escort else "Mit der Mutter die Wildnis erkunden",func():
		state.escort=not state.escort
		_sync_companion()
		if first_person:world_view.rebuild()
		else:world_view.region_built=-1
		_save_game()
		close_overlay();notify("Die Mutter bleibt in deiner Nähe." if state.escort else "Du erkundest den nächsten Weg selbstständig.")
	)
	follow.disabled=state.bond<48 and not state.escort
	v.add_child(follow)
	if follow.disabled:v.add_child(label("Ab Bindung 48 begleitet dich ein Elternwolf. Begrüße die Familie an der Höhle.",17))
	v.add_child(button("Zurück",show_menu))

func show_settings() -> void:
	var v := modal("Darstellung & Klang")
	card(v,"Deine Wildnis","%s · Tag %d\nWähle die Atmosphäre, die zu dir passt. Menüs halten die Zeit an."%[state.season_name(),state.day()])
	v.add_child(button("3D-Kamera: "+("Folgekamera" if state.camera_follow else "Wolfsblick"),func():switch_camera();show_settings()))
	v.add_child(button(("✓  " if state.compact_hud else "○  ")+"Mehr Platz für die Wildnis",func():set_hud_compact(not state.compact_hud);show_settings()))
	for item in [["sound_enabled","Naturklang & Rufe"],["weather_enabled","Wettereffekte"],["reduced_motion","Ruhige Animationen"],["smooth_edges","Weiche Kanten in 3D"],["map_reveal","Alle Gebietsnamen in der Übersicht"]]:
		var setting: String=item[0]
		var toggle := button(("✓  " if state.get(setting) else "○  ")+item[1],func():
			state.set(setting,not state.get(setting));_save_game()
			if setting=="smooth_edges":_apply_quality()
			if setting=="sound_enabled":
				_sync_audio()
			show_settings()
		)
		v.add_child(toggle)
	v.add_child(label("Draufsicht: Nähe",18))
	var zoom := HSlider.new()
	zoom.min_value=0.45;zoom.max_value=1.05;zoom.step=0.05;zoom.value=map_view.zoom
	zoom.custom_minimum_size.y=40
	zoom.value_changed.connect(func(value: float):map_view.zoom=value)
	v.add_child(zoom)
	v.add_child(label("Die Kopfleiste lässt sich mit ⌃ einklappen. Die Karte unterstützt Ziehen und Vergrößern mit zwei Fingern.",16))
	v.add_child(button("Zurück",show_menu))

func show_field_guide() -> void:
	var v := modal("Tierwissen & Fährten")
	hero(v,"LAUSCHEN · BEOBACHTEN · VERSTEHEN",170)
	for item in [["Reh","deer","Zwei schmale Schalen bilden ein Paar. Rehe heben den Kopf häufig und reagieren auf Geräusch, Sicht und Geruch."],["Hase","rabbit","Längere Hinterpfoten liegen im Lauf vor den kleineren Vorderpfoten. Bleibe leise; nahe Tiere können sofort fliehen."],["Fuchs","fox","Vier Zehen und ein Ballen. Ein Fuchs läuft oft in einer schmalen Spur und prüft seine Umgebung aufmerksam."],["Wolf","wolf","Vier Zehen und ein kräftiger Ballen. Vertraute Gerüche helfen dem Rudel, Wege und Angehörige zu erkennen."]]:
		var info := card(v,item[0]+(" · beobachtet" if state.observations.has(item[0]) else ""),item[2])
		var animal := TextureRect.new()
		animal.texture=WolfAtlas.walking(Vector2.LEFT,0) if item[1]=="wolf" else WolfAtlas.wildlife({"deer":0,"rabbit":1,"fox":2}[item[1]],0)
		animal.custom_minimum_size=Vector2(0,112)
		animal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		animal.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		animal.mouse_filter=Control.MOUSE_FILTER_IGNORE
		info.add_child(animal)
	v.add_child(label("Die Bedürfnisse und Verhaltensregeln sind für das Spiel vereinfacht. Tiere bleiben Tiere; du wächst langsam mit den Tagen deiner Geschichte.",15))
	v.add_child(button("Zurück",show_menu))

func confirm_new_game() -> void:
	var v := modal("Neu beginnen?")
	v.add_child(label("Dein bisheriger Spielstand wird ersetzt. Du beginnst wieder als Jungwolf an der Rudelhöhle.",20))
	v.add_child(button("Bisheriges Spiel fortsetzen",close_overlay))
	v.add_child(button("Neues Spiel beginnen",func():
		state=WolfState.new()
		world_memory.clear_cache(WolfState.save_path+".wildlife.json")
		world_cache.clear()
		world={}
		first_person=false
		guided_encounter_id="";guided_progress=-1
		set_hud_compact(state.compact_hud,false)
		camera_button.hide()
		_apply_quality()
		world_view.visible=false
		map_view.visible=true
		mode_button.text="3D · Wolfsblick"
		scent_time=0
		howl_cooldown=0;rest_cooldown=0;action_timer=0;player_mood="lauschen";clock=0
		change_region(0,WolfWorldData.SPAWN)
		close_overlay()
		show_intro()
	))

func show_quests() -> void:
	var v := modal("Erlebnisse & Spuren")
	v.add_child(label("%d Erlebnisse abgeschlossen · %d Erfahrung"%[state.completed.size(),state.xp],17))
	for q in state.quests():
		var content := card(v,("✓ " if q.done else "◌ ")+q.name+" · "+q.progress,q.hint)
		if not q.done:
			var id: String=q.id
			content.add_child(button("Auf dem Weg verfolgen" if state.tracked_quest!=id else "Wird verfolgt",func():state.tracked_quest=id;_refresh_status();close_overlay()))
	v.add_child(button("Zurück",show_menu))

func show_journal(filter_value: String="") -> void:
	var v := modal("Naturtagebuch")
	var filters := HBoxContainer.new()
	v.add_child(filters)
	for item in [["Alle",""],["Rudel","Rudel"],["Fährten","Fährte"],["Wildnis","Begegnung"]]:
		var value: String=item[1]
		var b := button(item[0],func():show_journal(value));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;filters.add_child(b)
	if state.main_story_status().started:v.add_child(button("Reise der Hauptgeschichte",func():show_journal("Hauptgeschichte")))
	card(v,"Deine Erinnerung","%d Spuren · %d Naturorte · %d Rudelerinnerungen\n%d / 8 Hauptkapitel erinnert. Deine Einträge bleiben erhalten."%[state.found.size(),state.sites.size(),state.story_step,int(state.main_story_status().chapter)])
	for entry in state.journal:
		if not filter_value.is_empty() and not entry.contains(filter_value):continue
		var parts := entry.split(" · ",true,1)
		card(v,parts[0],parts[1] if parts.size()>1 else entry)
	v.add_child(button("Zurück",show_menu))

func mark_territory() -> void:
	state.note_action("mark")
	if not state.marked.has(state.region):
		state.marked.append(state.region)
		state.record("Duftmarke · "+WolfWorldData.REGIONS[state.region].name+". Du kennst diesen Weg nun am Geruch.")
		notify("Du setzt eine Duftmarke und prägst dir den Weg ein.")
		check_quests()
	else:notify("Du erneuerst deinen vertrauten Duft an diesem Ort.")

func atlas_view_state() -> Dictionary:
	if not is_instance_valid(map_panel):return {}
	return {"local":map_panel.local_region,"selected":map_selected,"zoom":map_panel.magnification,"pan":map_panel.pan,"span":minf(map_panel.size.x,map_panel.size.y),"layers":map_panel.layers.duplicate(),"caption":map_selection.text}

func _restore_atlas_view(view: WolfCartography,snapshot: Dictionary) -> void:
	# Containers must finish layout before pixel-space pan can be transferred.
	await get_tree().process_frame
	if not is_instance_valid(view) or view!=map_panel or not is_instance_valid(overlay):return
	if snapshot.is_empty():
		view.center_on_player()
		return
	view.magnification=clampf(float(snapshot.get("zoom",1)),1,4)
	var ratio := minf(view.size.x,view.size.y)/maxf(1,float(snapshot.get("span",380)))
	view.pan=Vector2(snapshot.get("pan",Vector2.ZERO))*ratio
	map_selection.text=str(snapshot.get("caption",""))
	view.queue_redraw()

func show_map(expanded: bool=false,snapshot: Dictionary={}) -> void:
	atlas_expanded=expanded
	var v := modal("Wildnisatlas",expanded)
	if expanded:
		var scroll: ScrollContainer=v.get_parent()
		var stack: VBoxContainer=scroll.get_parent()
		scroll.remove_child(v);stack.remove_child(scroll);scroll.queue_free()
		stack.add_child(v)
		v.size_flags_vertical=Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation",8)
	else:v.add_child(label("%d verbundene Gebiete · %d erforscht\n%d Naturorte · %s"%[WolfWorldData.REGIONS.size(),state.visited.size(),WolfWorldData.REGIONS.size()*WolfWorldData.nature_sites(0).size(),state.season_name()],16))
	var tabs := HBoxContainer.new()
	v.add_child(tabs)
	var overview := button("Wildnis",func():map_panel.set_local(-1))
	overview.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tabs.add_child(overview)
	var local := button("Gebiet",func():select_map_region(map_selected,true))
	local.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tabs.add_child(local)
	var expand := button("Liste" if expanded else "Große Karte",func():show_map(not atlas_expanded,atlas_view_state()))
	expand.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	expand.add_theme_font_size_override("font_size",15)
	tabs.add_child(expand)
	map_selected=int(snapshot.get("selected",state.region))
	map_panel=WolfCartography.new()
	map_panel.game=self;map_panel.selected=map_selected
	if snapshot.has("layers"):map_panel.layers=snapshot.layers.duplicate()
	v.add_child(map_panel)
	if snapshot.has("local"):map_panel.set_local(int(snapshot.local))
	if expanded:
		map_panel.custom_minimum_size.y=140
		map_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	map_places=null
	map_selection=label("",14 if expanded else 17)
	if expanded:map_selection.max_lines_visible=2
	v.add_child(map_selection)
	map_panel.region_selected.connect(func(index: int):
		select_map_region(index)
	)
	map_panel.place_selected.connect(func(region: int,point: Vector2):
		var data: Dictionary=map_panel.region_data
		var nearest: Dictionary={}
		var distance := 20.0/map_panel.local_scale()
		for obj in data.get("objects",[]):
			if obj.kind!="discovery":continue
			var delta: float=obj.p.distance_to(point)
			if delta<distance:distance=delta;nearest=obj
		set_waypoint(region,nearest.p if not nearest.is_empty() else point)
		if not nearest.is_empty():map_selection.text=nearest.title+"\n"+nearest.description+"\n"+navigation_summary()
	)
	map_selection.text=WolfWorldData.REGIONS[state.region].name+" · Dein Standort\nTippe ein Gebiet an; Gebiet zeigt die Detailkarte."
	_restore_atlas_view.call_deferred(map_panel,snapshot)
	var controls := HBoxContainer.new()
	v.add_child(controls)
	for item in [["−",func():map_panel.zoom_by(1.0/1.3)],["Mein Standort",func():map_panel.center_on_player();select_map_region(state.region)],["+",func():map_panel.zoom_by(1.3)]]:
		var b := button(item[0],item[1]);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_child(b)
	var layers := HBoxContainer.new()
	v.add_child(layers)
	for item in [["sites","Naturorte"],["tracks","Spuren"],["route","Weg"]]:
		var layer: String=item[0]
		var toggle := button(item[1],func():map_panel.toggle_layer(layer))
		toggle.toggle_mode=true;toggle.button_pressed=map_panel.layers[layer]
		toggle.add_theme_font_size_override("font_size",14)
		toggle.size_flags_horizontal=Control.SIZE_EXPAND_FILL;layers.add_child(toggle)
		if expanded:toggle.custom_minimum_size.y=38
	if expanded:
		var goals := HBoxContainer.new()
		v.add_child(goals)
		for item in [["Zum Gebiet",func():set_waypoint(map_selected,Vector2(1600,1600))],["Ziel entfernen",func():state.waypoint_region=-1;_save_game();map_panel.queue_redraw();map_selection.text="Duftziel entfernt."]]:
			var b := button(item[0],item[1]);b.custom_minimum_size.y=45
			b.add_theme_font_size_override("font_size",15)
			b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;goals.add_child(b)
		var resume := button("Weiter erkunden",close_overlay)
		resume.custom_minimum_size.y=45;v.add_child(resume)
		return
	map_places=VBoxContainer.new();map_places.add_theme_constant_override("separation",8)
	v.add_child(map_places)
	refresh_map_places(map_selected)
	v.add_child(button("Zum gewählten Gebiet führen",func():set_waypoint(map_selected,Vector2(1600,1600));map_panel.queue_redraw()))
	v.add_child(button("Duftziel entfernen",func():state.waypoint_region=-1;_save_game();map_panel.queue_redraw();map_selection.text="Duftziel entfernt."))
	var search := LineEdit.new()
	search.placeholder_text="Bekanntes Gebiet suchen …"
	search.custom_minimum_size.y=50
	search.add_theme_stylebox_override("normal",panel_style(Color("#294c3a"),12))
	search.add_theme_font_size_override("font_size",16)
	v.add_child(search)
	var results := VBoxContainer.new()
	v.add_child(results)
	search.text_changed.connect(func(query: String):
		for child in results.get_children():results.remove_child(child);child.queue_free()
		if query.length()<2:return
		var found := find_map_regions(query)
		if found.is_empty():results.add_child(label("Kein bekanntes Gebiet mit diesem Namen.",15))
		for index in found:
			var target: int=index
			results.add_child(button(WolfWorldData.REGIONS[target].name,func():
				select_map_region(target,true)
			))
	)
	card(v,"Legende","Helle Pfote: dein Wolf · dunkle Pfote: Höhle\nGoldener Kreis: Naturort · rote Linie: sicherer Weg\nPfeile zeigen Gebietsausgänge. Gelesene Spuren lassen sich einblenden. In der Detailkarte setzt du per Tippen ein genaues Ziel.")
	v.add_child(button("Weiter erkunden",close_overlay))

func select_map_region(index: int,details: bool=false) -> void:
	if index<0 or index>=WolfWorldData.REGIONS.size() or not is_instance_valid(map_panel):return
	map_selected=index;map_panel.selected=index
	if details:map_panel.set_local(index)
	var region: Dictionary=WolfWorldData.REGIONS[index]
	map_selection.text=region.name+"\n"+region.subtitle+("\nErkundet · "+region.district if state.visited.has(index) else "\nNoch unerforscht")
	refresh_map_places(index)
	map_panel.queue_redraw()

func refresh_map_places(index: int) -> void:
	if not is_instance_valid(map_places):return
	for child in map_places.get_children():map_places.remove_child(child);child.queue_free()
	if not state.visited.has(index):
		map_places.add_child(label("Naturorte lernst du draußen kennen. Folge den Übergängen zu diesem Gebiet.",15))
		return
	var sites := WolfWorldData.nature_sites(index)
	var known := 0
	for site in sites:if state.sites.has(site.site):known+=1
	map_places.add_child(label("Naturorte · %d/%d vertraut"%[known,sites.size()],18))
	for site in sites:
		var place: Dictionary=site
		var caption := ("✓  " if state.sites.has(place.site) else "○  ")+str(place.title)
		var b := button(caption,func():
			select_map_region(index,true)
			set_waypoint(index,place.p)
			map_selection.text=place.title+"\n"+place.description+"\n"+navigation_summary()
		)
		b.custom_minimum_size.y=45;b.add_theme_font_size_override("font_size",15)
		map_places.add_child(b)

func find_map_regions(query: String) -> Array[int]:
	var results: Array[int]=[]
	var text := query.strip_edges().to_lower()
	if text.is_empty():return results
	for index in range(WolfWorldData.REGIONS.size()):
		if not state.map_reveal and not state.visited.has(index):continue
		var region: Dictionary=WolfWorldData.REGIONS[index]
		if (str(region.name)+" "+str(region.subtitle)).to_lower().contains(text):results.append(index)
		if results.size()>=6:break
	return results

func _build_ambient() -> void:
	ambient=AudioStreamPlayer.new()
	add_child(ambient)
	var bytes := PackedByteArray()
	var rate := 16000
	var duration := 8
	bytes.resize(rate*duration*2)
	var rng := RandomNumberGenerator.new();rng.seed=204
	var smooth := 0.0
	for i in range(rate*duration):
		var t := float(i)/rate
		smooth=smooth*0.94+rng.randf_range(-1,1)*0.06
		var breeze := smooth*(0.16+sin(t*TAU/duration)*0.025)
		var bird := 0.0
		for call in [1.2,4.2,6.1]:
			var offset: float=t-call
			if offset>0 and offset<0.28:bird+=sin(TAU*(2100*offset+90*sin(offset*18)))*sin(offset/0.28*PI)*0.013
		bytes.encode_s16(i*2,int(clampf(breeze+bird,-1,1)*32767))
	var stream := AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.data=bytes
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=rate*duration
	ambient.stream=stream;ambient.volume_db=-19

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST:
		app_idle=true
		if state!=null:state.clear_encounter_presence()
		if state!=null:_save_game()
		_cancel_touch_inputs()
		_sync_audio()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN or what==NOTIFICATION_APPLICATION_RESUMED:
		app_idle=false
		_sync_audio()
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(ui):
		if is_instance_valid(overlay):close_overlay()
		else:show_menu()

# Campaign objectives use the same physical interactions as free exploration.
func _main_story_context() -> String:
	var story := state.main_story_status()
	if not story.started or story.done or story.ready or state.region!=int(story.target_region):return ""
	match str(story.action):
		"drink":
			for obj in world.objects:
				if obj.kind=="water" and ((obj.variant==0 and obj.p.distance_to(state.pos)<190*obj.scale+90) or (obj.variant==1 and absf(state.pos.x-WolfWorldData.river_x(state.pos.y))<155)):return "Trinken"
		"site":
			for obj in world.objects:
				if obj.kind=="discovery" and obj.site==story.site_id and obj.p.distance_to(state.pos)<140:return "Ort prüfen"
		"track":
			for track in world.tracks:
				if track.id==story.track_id and track.p.distance_to(state.pos)<100 and scent_time>0:return "Spur lesen"
		"mark":
			if state.pos.distance_to(story.target_pos)<140:return "Duft setzen"
		"rest", "rest_wait":
			for obj in world.objects:
				if obj.kind=="den" and obj.p.distance_to(state.pos)<190:return "Ruhen"
		"watch":
			if first_person and not observation_candidate(true).is_empty():return "Beobachten"
	return ""

func _interact_main_story() -> bool:
	var action := _main_story_context()
	if action.is_empty():return false
	var story := state.main_story_status()
	match action:
		"Trinken":
			state.thirst=100;state.drank=true
			player_mood="trinken";action_timer=3
			state.note_action("drink")
			notify("Du trinkst am kühlen Ufer. Deine Reise geht weiter.")
		"Ort prüfen":
			for obj in world.objects:
				if obj.kind=="discovery" and obj.site==story.site_id:inspect_nature_site(obj);break
		"Spur lesen":
			for track in world.tracks:
				if track.id!=story.track_id:continue
				if not state.found.has(track.id):
					state.found.append(track.id);state.skills.nose=mini(100,int(state.skills.nose)+1)
					state.record("Fährte · "+track.species+". Du prüfst die frischen Trittsiegel auf deiner Reise.")
				state.note_main_story_action("track",track.id)
				state.note_nature_journey_action("track",track.id)
				player_mood="schnüffeln";action_timer=2
				notify("Du erkennst die Fährte und folgst ihrem Duft.")
				break
		"Duft setzen":mark_territory()
		"Ruhen":rest()
		"Beobachten":return observe()
	check_quests()
	return true

func _tick_main_story(dt: float) -> void:
	if app_idle or is_instance_valid(overlay):return
	var story := state.main_story_status()
	if not story.started or story.done:return
	var parent: Dictionary={}
	for animal in world.animals:
		if animal.kind=="wolf" and animal.get("role","")=="Mutter" and not animal.get("young",false):parent=animal;break
	var clear := false
	if not parent.is_empty() and world.has("_animal_motion"):
		var navigation: WolfAnimalMotion=world._animal_motion
		clear=navigation.segment_free(parent.p,state.pos)
	var watched := observation_candidate(true) if first_person and story.action=="watch" else {}
	state.tick_main_story(minf(dt,.1),parent,clear,_quiet_player_speed(),watched,not watched.is_empty(),sneak_button.button_pressed or player_speed<1,player_mood)
	var updated := state.main_story_status()
	var key := "%d:%d"%[updated.chapter,updated.stage]
	if updated.ready and main_story_ready_notice!=key:
		main_story_ready_notice=key
		notify("Ein Kapitel ist erlebt. Öffne Geschichte, um deine Reise fortzusetzen.")
		_save_game()

func _begin_main_story() -> void:
	state.begin_main_story()
	_save_game();guide_main_story();close_overlay()
	notify("Die Düfte der Heimat · Deine Reise beginnt bei deiner Mutter.")

func guide_main_story() -> void:
	var story := state.main_story_status()
	if not story.started or story.done:return
	var point: Vector2=story.target_pos
	if story.action=="greet" and state.region==int(story.target_region):
		for animal in world.animals:
			if animal.kind=="wolf" and animal.get("role","")=="Mutter":point=animal.p;break
	set_waypoint(int(story.target_region),point)
	guided_main_story="%d:%d"%[story.chapter,story.stage]

func _refresh_main_story_guide() -> void:
	if guided_main_story.is_empty():return
	var story := state.main_story_status()
	if story.done:guided_main_story="";return
	if guided_main_story!="%d:%d"%[story.chapter,story.stage]:guide_main_story()

func show_main_story() -> void:
	var story := state.main_story_status()
	var v := modal("Die Düfte der Heimat")
	if not story.started:
		v.add_child(button("Die Reise beginnen",_begin_main_story))
	elif story.done:
		v.add_child(button("Die Heimkehr im Tagebuch",func():show_journal("Hauptgeschichte")))
	elif story.ready:
		v.add_child(button("Die Heimkehr erinnern" if int(story.chapter)==int(story.chapters_count)-1 else "Das nächste Kapitel",func():
			if state.advance_main_story():_save_game();guide_main_story();show_main_story()
		))
	else:
		v.add_child(button("Zurück auf meine Reise",func():guide_main_story();close_overlay()))
	hero(v,"ACHT KAPITEL · EIN VERTRAUTER DUFT",145)
	card(v,str(story.title),str(story.text))
	if story.started and not story.done:
		var progress := ProgressBar.new()
		progress.max_value=maxf(1,float(story.required));progress.value=float(story.current)
		v.add_child(progress)
		var objective_text: String=str(story.objective)+"\n"+str(story.progress)
		if float(story.seconds_required)>0:objective_text+="\n%.1f / %.0f aktive Sekunden"%[story.seconds,story.seconds_required]
		card(v,"Dein nächster Schritt",objective_text)
		if story.action in ["joint","rest_wait"]:card(v,"Gemeinsam ankommen","Bleib vor der Höhle ruhig stehen. Deine Mutter kommt selbst zu dir. Ihr lauscht gemeinsam, sobald sie wirklich neben dir angekommen ist." if story.get("home_meeting",false) else "Nimm die Mutter im Rudelmenü mit. Sie geht selbst durch die Wildnis. Warte am Ziel mit ruhigen Pfoten, bis sie wirklich neben dir angekommen ist.")
		if story.action=="watch":card(v,"Ein ruhiger Blick","Wechsle in 3D. Nähere dich leise auf Abstand und wähle Beobachten. Halte dasselbe ruhige Reh vier aktive Sekunden ohne Bäume oder Felsen im Blick.")
		v.add_child(button("Duftziel auf der Karte zeigen",func():guide_main_story();close_overlay()))
		v.add_child(button("Meine Familie & Begleitung",show_pack))
		var stages: String=""
		for i in range(story.stage_titles.size()):stages+=("✓ " if i<int(story.stage) else "◌ ")+str(story.stage_titles[i])+"\n"
		card(v,"Der Weg dieses Kapitels",stages.strip_edges())
	var chapters: String=""
	for chapter in story.chapter_titles:chapters+=str(chapter)+"\n"
	card(v,"Deine große Reise",chapters.strip_edges())
	card(v,"Ein Leben in deinem Tempo","Die Geschichte begleitet deine eigenen Schritte. Freies Erkunden bleibt möglich. Menüs pausieren die Welt; Rast überspringt weder Tage noch Alter.")
	v.add_child(button("Rudelerinnerungen",show_story))
	v.add_child(button("Zurück in die Wildnis",close_overlay))

func _refresh_main_story_presence_hud() -> void:
	var story := state.main_story_status()
	if not story.started or story.done or story.ready or is_instance_valid(overlay):return
	if story.action not in ["joint","watch","rest_wait"]:return
	observation_panel.show();observation_progress.show()
	observation_progress.max_value=maxf(1,float(story.seconds_required))
	observation_progress.value=float(story.seconds)
	observation_title.text="Ruhiger Blick" if story.action=="watch" else "Geschützte Ruhe" if story.action=="rest_wait" else "Gemeinsam ankommen"
	if story.action=="watch":
		if not first_person:observation_hint.text="Wechsle in 3D, um das Reh wirklich im Blick zu halten."
		elif not story.watch_started:observation_hint.text="Nähere dich leise und wähle Beobachten."
		elif not story.watch_ready:observation_hint.text="Halte dasselbe ruhige Reh mit freier Sicht und Abstand im Blick."
		else:observation_hint.text="Ruhiger Blick · %.1f / %.0f Sekunden"%[story.seconds,story.seconds_required]
	elif not story.player_ready:observation_hint.text="Folge dem Duftziel und halte am Ziel ruhig an."
	elif not story.companion_ready:observation_hint.text="Bleib ruhig vor der Höhle. Deine Mutter kommt zu dir." if story.get("home_meeting",false) else "Warte auf deine Mutter. Im Rudelmenü kannst du sie mitnehmen."
	elif story.action=="rest_wait" and player_mood!="ruhen":observation_hint.text="Wähle Ruhen im Schutz der Höhle."
	else:observation_hint.text="Gemeinsam lauschen · %.1f / %.0f Sekunden"%[story.seconds,story.seconds_required]

func _nature_journey_context() -> String:
	var goal := state.nature_journey_status()
	if not goal.accepted or goal.ready or state.region!=int(goal.target_region):return ""
	match str(goal.action):
		"drink":
			for obj in world.objects:
				if obj.kind=="water" and ((obj.variant==0 and obj.p.distance_to(state.pos)<190*obj.scale+90) or (obj.variant==1 and absf(state.pos.x-WolfWorldData.river_x(state.pos.y))<155)):return "Trinken"
		"site":
			for obj in world.objects:
				if obj.kind=="discovery" and obj.site==goal.site_id and obj.p.distance_to(state.pos)<140:return "Ort prüfen"
		"track":
			for track in world.tracks:
				if track.id==goal.track_id and track.p.distance_to(state.pos)<100 and scent_time>0:return "Spur lesen"
		"mark":
			if state.pos.distance_to(goal.target_pos)<140:return "Duft setzen"
		"rest", "rest_wait":
			if state.pos.distance_to(goal.target_pos)<185:
				for obj in world.objects:
					if obj.kind=="den" and obj.p.distance_to(state.pos)<190:return "Ruhen"
		"watch":
			if first_person and not observation_candidate(false,true).is_empty():return "Beobachten"
	return ""

func _interact_nature_journey() -> bool:
	var action := _nature_journey_context()
	if action.is_empty():return false
	var goal := state.nature_journey_status()
	match action:
		"Trinken":
			state.thirst=100;state.drank=true;player_mood="trinken";action_timer=3
			state.note_action("drink");notify("Du trinkst am kühlen Ufer.")
		"Ort prüfen":
			for obj in world.objects:
				if obj.kind=="discovery" and obj.site==goal.site_id:inspect_nature_site(obj);break
		"Spur lesen":
			for track in world.tracks:
				if track.id!=goal.track_id:continue
				if not state.found.has(track.id):
					state.found.append(track.id);state.skills.nose=mini(100,int(state.skills.nose)+1)
					state.record("Fährte · "+track.species+". Du prüfst den Duft auf deiner Naturreise.")
				state.note_nature_journey_action("track",track.id)
				state.note_main_story_action("track",track.id)
				player_mood="schnüffeln";action_timer=2;notify("Du liest das ausgewählte Trittsiegel.");break
		"Duft setzen":mark_territory()
		"Ruhen":rest()
		"Beobachten":return observe()
	check_quests();return true

func _tick_nature_journey(dt: float) -> void:
	if app_idle or is_instance_valid(overlay):return
	var goal := state.nature_journey_status()
	if not goal.accepted or goal.ready:return
	var animal := observation_candidate(false,true) if first_person and goal.action=="watch" else {}
	state.tick_nature_journey(minf(dt,.1),_quiet_player_speed(),animal,not animal.is_empty(),sneak_button.button_pressed or player_speed<1,player_mood)
	var updated := state.nature_journey_status()
	if updated.ready and nature_journey_ready_notice!=updated.id:
		nature_journey_ready_notice=updated.id;_save_game()
		notify("Deine Naturreise ist erlebt. Öffne Naturreisen und nimm die Erfahrung mit.")

func guide_nature_journey() -> void:
	var goal := state.nature_journey_status()
	if not goal.accepted or goal.ready:return
	set_waypoint(int(goal.target_region),goal.target_pos)
	guided_nature_journey="%s:%d"%[goal.id,goal.stage]

func _refresh_nature_journey_guide() -> void:
	if guided_nature_journey.is_empty():return
	var goal := state.nature_journey_status()
	if not goal.accepted or goal.ready:guided_nature_journey="";return
	if guided_nature_journey!="%s:%d"%[goal.id,goal.stage]:guide_nature_journey()

func show_nature_journeys() -> void:
	var goal := state.nature_journey_status()
	var v := modal("Naturreisen")
	if goal.accepted:
		if goal.ready:
			v.add_child(button("Die Erfahrung mitnehmen",func():
				if state.claim_nature_journey():_save_game();guided_nature_journey="";show_nature_journeys()
			))
		else:v.add_child(button("Meine Naturreise fortsetzen",func():guide_nature_journey();close_overlay()))
		card(v,str(goal.title),str(goal.text)+"\n\n"+str(goal.objective)+"\n"+str(goal.progress))
		var progress := ProgressBar.new();progress.max_value=maxf(1,float(goal.required));progress.value=goal.current;v.add_child(progress)
		if goal.action in ["watch","rest_wait"]:card(v,"Ein echter Augenblick","%.1f / %.0f ruhige Sekunden. Menüs pausieren die Reise. Beobachte dasselbe ruhige Reh im 3D-Blick mit freier Sicht; eine Rast zählt nur während wirklichen Liegens."%[goal.seconds,goal.seconds_required])
		v.add_child(button("Naturreise zurücklegen",func():
			state.abandon_nature_journey();guided_nature_journey="";_save_game();show_nature_journeys()
		))
	else:v.add_child(button("Zurück in die Wildnis",close_overlay))
	v.add_child(label("Sechs Wege in "+WolfWorldData.REGIONS[state.region].name,22))
	v.add_child(label("Wähle einen Duft. Sechs kleine Reisen führen zu wirklichen Handlungen und bringen jeweils 30 Erfahrung. Die Hauptgeschichte bleibt unabhängig.",16))
	# Compact rows keep all six titles available without sprawling hero cards.
	for offer in state.nature_journeys_options():
		var id: String=offer.id
		var row := button(("✓ " if offer.completed else "◌ ")+str(offer.title),func():
			if state.begin_nature_journey(id):_save_game();guide_nature_journey();close_overlay()
		)
		row.custom_minimum_size.y=54;row.add_theme_font_size_override("font_size",16);row.tooltip_text=str(offer.summary);row.disabled=not offer.available
		v.add_child(row)
	v.add_child(button("Hauptgeschichte",show_main_story))
	v.add_child(button("Zurück",show_menu))

func _refresh_nature_journey_hud() -> void:
	var goal := state.nature_journey_status()
	if not goal.accepted or goal.ready or is_instance_valid(overlay) or goal.action not in ["watch","rest_wait"]:return
	observation_panel.show();observation_progress.show()
	observation_progress.max_value=maxf(1,float(goal.seconds_required));observation_progress.value=goal.seconds
	observation_title.text="Naturreise · Reh beobachten" if goal.action=="watch" else "Naturreise · Geschützte Ruhe"
	if goal.action=="watch":
		if not first_person:observation_hint.text="Wechsle in 3D und beobachte ein ruhiges Reh."
		elif not goal.watch_started:observation_hint.text="Mit ruhigen Pfoten und Abstand: wähle Beobachten."
		elif not goal.watch_ready:observation_hint.text="Halte dasselbe ruhige Reh mit freier Sicht im Blick."
		else:observation_hint.text="Ruhiger Blick · %.1f / %.0f Sekunden"%[goal.seconds,goal.seconds_required]
	elif not goal.player_ready:observation_hint.text="Bleib im geschützten Rastplatz ruhig liegen."
	else:observation_hint.text="Geschützte Ruhe · %.1f / %.0f Sekunden"%[goal.seconds,goal.seconds_required]

# Keep the passive HUD small; only its two explicit buttons receive touches.
func _layout_mission_hud() -> void:
	if not is_instance_valid(observation_panel):return
	observation_hint.visible=mission_hud_expanded
	observation_fold.text="⌃" if mission_hud_expanded else "⌄"
	var hint := observation_hint.text
	var status := "Ruhige Pfoten"
	if hint.contains("3D"):status="3D-Blick öffnen"
	elif hint.contains("Beobachten"):status="Beobachten wählen"
	elif hint.contains("aufgeschreckt"):status="Tier braucht Ruhe"
	elif hint.contains("Mutter") or hint.contains("Elternwolf"):
		status="Auf die Mutter warten" if state.main_story_status().get("home_meeting",false) else "Auf Begleitung warten"
	elif hint.contains("Duftziel") or hint.contains("Ruhepunkt"):status="Zum Duftziel gehen"
	elif hint.contains("Bleib stehen"):status="Still stehen bleiben"
	elif hint.contains("dasselbe") or hint.contains("freie Sicht"):status="Dasselbe Tier im Blick"
	elif hint.contains("Ruhen") or hint.contains("liegen"):status="Geschützt liegen bleiben"
	observation_summary.text=("%.1f / %.0f s · "%[observation_progress.value,observation_progress.max_value] if observation_progress.visible else "")+status
	if ui.size.y<760 and not state.compact_hud:observation_panel.hide()
	_apply_header_display()
	observation_hint.max_lines_visible=2 if ui.size.y<720 else 3
	observation_hint.custom_minimum_size.y=0
	var height := clampf(observation_panel.get_combined_minimum_size().y,86,154) if mission_hud_expanded else 86.0
	observation_panel.offset_bottom=-328
	observation_panel.offset_top=-328-height
	# Toast has its own fixed, clipped three-line lane above the movement controls.
	toast_lane.offset_top=-316;toast_lane.offset_bottom=-246
	var narrow := ui.size.x<440
	if is_instance_valid(stick):stick.custom_minimum_size.x=clampf(ui.size.x*.28,96,140)
	if hud_layout_width_mode!=int(narrow):
		hud_layout_width_mode=int(narrow)
		for control in hud_action_controls+hud_bottom_controls:
			control.add_theme_font_size_override("font_size",12 if narrow else 15)
			for key in ["normal","hover","pressed"]:
				var style: StyleBoxFlat=control.get_theme_stylebox(key).duplicate()
				style.content_margin_left=4 if narrow else 9
				style.content_margin_right=4 if narrow else 9
				style.content_margin_top=6
				style.content_margin_bottom=6
				control.add_theme_stylebox_override(key,style)
	observation_panel.queue_sort()
	_fit_mission_panel.call_deferred()

func _fit_mission_panel() -> void:
	if not is_instance_valid(observation_panel):return
	var height := clampf(observation_panel.get_combined_minimum_size().y,86,154) if mission_hud_expanded else 86.0
	observation_panel.offset_bottom=-328
	observation_panel.offset_top=-328-height

func _show_hud_mission_details() -> void:
	var journey := state.nature_journey_status()
	var story := state.main_story_status()
	if journey.accepted and guided_main_story.is_empty():show_nature_journeys()
	elif story.started and not story.done:show_main_story()
	else:show_encounter()
