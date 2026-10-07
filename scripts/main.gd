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
var looking_mouse := false
var sneak_button: Button
var minimap: WolfMinimap
var need_bars: Dictionary = {}
var need_labels: Dictionary = {}
var level_label: Label
var last_pack_visit := -30.0
var sound: AudioStreamPlayer

func _ready() -> void:
	var resumed := state.load_from()
	world=WolfWorldData.generate(state.region)
	if not can_walk(state.pos):state.pos=WolfWorldData.SPAWN
	world_view=WolfWorldView.new()
	world_view.game=self
	add_child(world_view)
	world_view.rebuild()
	world_view.visible=false
	map_view=WolfMapView.new()
	map_view.game=self
	add_child(map_view)
	sound=AudioStreamPlayer.new()
	add_child(sound)
	_build_ui()
	_refresh_status()
	if not resumed:
		show_intro()
	else:
		notify("Willkommen zurück. Dein Rudel ist noch hier.")

func panel_style(color: Color, radius: int=18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color=Color("#9e906b")
	style.content_margin_left=16
	style.content_margin_right=16
	style.content_margin_top=12
	style.content_margin_bottom=12
	return style

func label(text_value: String,font_size: int=18) -> Label:
	var l := Label.new()
	l.text=text_value
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",Color("#eeebd5"))
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func button(text_value: String,callback: Callable) -> Button:
	var b := Button.new()
	b.text=text_value
	b.custom_minimum_size=Vector2(0,54)
	b.add_theme_font_size_override("font_size",17)
	b.add_theme_color_override("font_color",Color("#eee9cc"))
	b.add_theme_stylebox_override("normal",panel_style(Color("#1c343e"),14))
	b.add_theme_stylebox_override("hover",panel_style(Color("#324d53"),14))
	b.add_theme_stylebox_override("pressed",panel_style(Color("#756749"),14))
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
	var header := PanelContainer.new()
	ui.add_child(header)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left=16
	header.offset_right=-16
	header.offset_top=16
	header.add_theme_stylebox_override("panel",panel_style(Color(0.055,0.16,0.16,0.94)))
	var hv := VBoxContainer.new()
	header.add_child(hv)
	var row := HBoxContainer.new()
	hv.add_child(row)
	row.add_theme_constant_override("separation",9)
	var portrait_stack := VBoxContainer.new()
	row.add_child(portrait_stack)
	var portrait := TextureRect.new()
	portrait.texture=WolfAtlas.sprite(15)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size=Vector2(66,70)
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	portrait_stack.add_child(portrait)
	level_label=label("",12)
	level_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	portrait_stack.add_child(level_label)
	var meters := VBoxContainer.new()
	meters.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(meters)
	for item in [["hunger","Nahrung","#d3a54e"],["thirst","Wasser","#51b9d2"],["energy","Kraft","#63b477"],["bond","Rudel","#d57d88"]]:
		var meter_row := HBoxContainer.new()
		meters.add_child(meter_row)
		var text_label := label(item[1],11)
		text_label.custom_minimum_size.x=75
		meter_row.add_child(text_label)
		need_labels[item[0]]=text_label
		var bar := ProgressBar.new()
		bar.custom_minimum_size=Vector2(60,13)
		bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		bar.show_percentage=false
		bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background",panel_style(Color("#10232c"),6))
		var fill := panel_style(Color(item[2]),6)
		fill.set_border_width_all(0)
		bar.add_theme_stylebox_override("fill",fill)
		meter_row.add_child(bar)
		need_bars[item[0]]=bar
	minimap=WolfMinimap.new()
	minimap.game=self
	row.add_child(minimap)
	row.add_child(button("☰",show_menu))
	title=label("",20)
	hv.add_child(title)
	location_hint=label("",12)
	hv.add_child(location_hint)
	stats=label("",12)
	stats.visible=false
	hv.add_child(stats)
	quest_hint=label("",14)
	hv.add_child(quest_hint)
	look_area=Control.new()
	ui.add_child(look_area)
	look_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	look_area.offset_top=246
	look_area.offset_bottom=-262
	look_area.mouse_filter=Control.MOUSE_FILTER_STOP
	look_area.gui_input.connect(_look_input)
	toast=label("",17)
	ui.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast.offset_left=24
	toast.offset_right=-24
	toast.offset_top=-308
	toast.offset_bottom=-244
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_shadow_color",Color("#15362f"))
	toast.add_theme_constant_override("shadow_outline_size",5)
	var lower := HBoxContainer.new()
	ui.add_child(lower)
	lower.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	lower.offset_left=16
	lower.offset_right=-16
	lower.offset_top=-242
	lower.offset_bottom=-90
	lower.add_theme_constant_override("separation",14)
	stick=WolfTouchStick.new()
	lower.add_child(stick)
	var actions := GridContainer.new()
	actions.columns=2
	actions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation",8)
	actions.add_theme_constant_override("v_separation",8)
	lower.add_child(actions)
	for item in [["Schnüffeln",sniff],["Aktion",interact],["Heulen",howl],["Duft setzen",mark_territory]]:
		var b := button(item[0],item[1])
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		actions.add_child(b)
	var bottom := HBoxContainer.new()
	ui.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left=16
	bottom.offset_right=-16
	bottom.offset_top=-76
	bottom.offset_bottom=-18
	bottom.add_theme_constant_override("separation",10)
	mode_button=button("3D · Wolfsblick",toggle_view)
	mode_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bottom.add_child(mode_button)
	sprint_button=button("Trab",func():pass)
	sprint_button.toggle_mode=true
	bottom.add_child(sprint_button)
	sneak_button=button("Leise",func():pass)
	sneak_button.toggle_mode=true
	bottom.add_child(sneak_button)
	bottom.add_child(button("Karte",show_map))

func _process(dt: float) -> void:
	clock+=dt
	if is_instance_valid(overlay):return
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
	if v.length()>0.01:
		state.facing=v.normalized()
		move_wolf(v*speed*minf(dt,0.05))
	state.tick(dt,v.length()>0.01,sprint)
	_update_animals(dt)
	world_view.sync_camera()
	map_view.queue_redraw()
	minimap.queue_redraw()
	if toast_time>0:
		toast_time-=dt
		if toast_time<=0:toast.text=""
	status_timer+=dt
	if status_timer>0.25:
		status_timer=0
		check_quests()
		_refresh_status()
	save_timer+=dt
	if save_timer>20:
		save_timer=0
		state.save_to()

func can_walk(p: Vector2) -> bool:
	if WolfWorldData.water_blocked(p,state.region):return false
	return WolfWorldData.walkable(p,world.objects)

func move_wolf(delta: Vector2) -> void:
	# Axis separation permits sliding around trees without cutting through them.
	var before := state.pos
	var p := state.pos+Vector2(delta.x,0)
	if can_walk(p):state.pos=p
	p=state.pos+Vector2(0,delta.y)
	if can_walk(p):state.pos=p
	state.distance_walked+=state.pos.distance_to(before)
	var direction := WolfWorldData.exit_at(state.pos,state.region)
	if direction!="":
		change_region(WolfWorldData.REGIONS[state.region].links[direction],WolfWorldData.entry_point(direction))
	else:
		state.pos=state.pos.clamp(Vector2(14,14),WolfWorldData.SIZE-Vector2(14,14))

func change_region(index: int,entry: Vector2) -> void:
	state.region=index
	state.pos=entry
	world=WolfWorldData.generate(index)
	if not state.visited.has(index):
		state.visited.append(index)
		state.record("Neues Gebiet · "+WolfWorldData.REGIONS[index].name+". "+WolfWorldData.REGIONS[index].subtitle)
	world_view.rebuild()
	last_pack_visit=-30
	notify(WolfWorldData.REGIONS[index].name+" · Ein neuer Duft liegt in der Luft.")
	state.save_to()

func _update_animals(dt: float) -> void:
	for a in world.animals:
		var target: Vector2=a.home+Vector2(sin(clock*0.18+a.phase)*45,cos(clock*0.13+a.phase)*38)
		var speed := 11.0
		var distance: float=a.p.distance_to(state.pos)
		if a.kind!="wolf" and distance<(75 if sneak_button.button_pressed else 145):
			target=a.p+(a.p-state.pos).normalized()*150
			speed=65
		if a.kind=="wolf" and state.region==0 and state.bond>=50 and distance<380 and distance>150:
			target=state.pos
			speed=55
		var next: Vector2=a.p.move_toward(target,speed*dt)
		if next.distance_to(a.p)>0.01:a.facing=(next-a.p).normalized()
		if can_walk(next):a.p=next.clamp(Vector2(100,100),Vector2(3100,3100))

func toggle_view() -> void:
	first_person=not first_person
	world_view.visible=first_person
	map_view.visible=not first_person
	stick.reset()
	if first_person:world_view.enter()
	mode_button.text="2D · Draufsicht" if first_person else "3D · Wolfsblick"
	notify("Wische über die Landschaft zum Umsehen. Untersuchen entdeckt sichtbare Tiere." if first_person else "Du siehst die Karte wieder von oben. Bewege dich in alle Richtungen.")

func _look_input(event: InputEvent) -> void:
	if not first_person:return
	if event is InputEventScreenTouch:
		if event.pressed and look_pointer==-1:look_pointer=event.index
		elif not event.pressed and event.index==look_pointer:look_pointer=-1
	elif event is InputEventScreenDrag and event.index==look_pointer:
		world_view.look(event.relative)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		looking_mouse=event.pressed
	elif event is InputEventMouseMotion and looking_mouse:
		world_view.look(event.relative)

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
		KEY_M:show_map()

func notify(message: String) -> void:
	toast.text=message
	toast_time=7

func sniff() -> void:
	scent_time=18
	var nearest := 9999.0
	for t in world.tracks:
		if not state.found.has(t.id):nearest=minf(nearest,t.p.distance_to(state.pos))
	notify("Frische Fährten werden goldfarben sichtbar. Folge ihrem Verlauf und untersuche sie." if nearest<500 else "Du riechst Wald, Wasser und ferne Tiere. Suche entlang der Wege weiter.")

func interact() -> void:
	if first_person and observe():return
	for a in world.animals:
		if a.kind=="wolf" and a.p.distance_to(state.pos)<135:
			if state.elapsed-last_pack_visit<20:
				notify("Das Rudel bleibt bei dir. Lass ihm einen Moment Ruhe.")
				return
			last_pack_visit=state.elapsed
			state.pack_contacts+=1
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
					state.drank=true
					notify("Du trinkst kühles Wasser. Dein Durst ist gestillt.")
					check_quests()
					return
			"food":
				if d<85 and state.food_cooldown<=0:
					state.hunger=minf(100,state.hunger+40)
					state.food_cooldown=300
					notify("Du frisst vom Nahrungsvorrat. Das Rudel hat einen Teil seiner Beute hier abgelegt.")
					return
			"den":
				if d<210:
					rest()
					return
			"discovery":
				if d<140:
					if not state.discoveries.has(state.region):
						state.discoveries.append(state.region)
						state.xp+=15
						state.record("Entdeckung · "+WolfWorldData.REGIONS[state.region].name+". Ein geschützter Naturort voller neuer Düfte.")
					notify("Du hast einen besonderen Naturort entdeckt. +15 Erfahrung.")
					check_quests()
					return
			"landmark":
				if d<100:
					if not state.landmarks.has(state.region):
						state.landmarks.append(state.region)
						state.record("Wegstein · "+WolfWorldData.REGIONS[state.region].name+". Moose und fremde Düfte verraten, wer hier vorbeikam.")
					notify("Ein alter Wegstein. Du prägst dir den Ort und seine Gerüche ein.")
					check_quests()
					return
	notify("Nichts in unmittelbarer Nähe. Schnüffle nach Spuren oder nähere dich Wasser und Wegsteinen.")

func observe() -> bool:
	var forward := Vector2(-sin(world_view.yaw),-cos(world_view.yaw))
	for a in world.animals:
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
		var species := "Reh" if a.kind=="deer" else "Hase" if a.kind=="rabbit" else "Fuchs"
		if not state.observations.has(species):
			state.observations.append(species)
			state.record("Beobachtung · "+species+". Du bleibst auf Abstand und beobachtest leise aus dem Wolfsblick.")
		notify("Du beobachtest ein "+species+". Es lauscht und prüft seine Umgebung.")
		check_quests()
		return true
	return false

func howl() -> void:
	if howl_cooldown>0:
		notify("Lausche erst auf die Antwort des Rudels.")
		return
	howl_cooldown=8
	play_howl()
	if state.region==0 and state.pos.distance_to(Vector2(1600,2240))<460:
		state.bond=minf(100,state.bond+4)
		state.howled=true
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
	for obj in world.objects:
		if obj.kind=="den" and state.pos.distance_to(obj.p)<190:
			state.energy=minf(100,state.energy+30)
			state.rested=true
			notify("Du ruhst im Schutz der Höhle. Die vertrauten Düfte geben dir Sicherheit.")
			check_quests()
			return
	notify("Hier ist es zu offen. Suche die geschützte Umgebung einer Höhle zum Ruhen.")

func check_quests() -> void:
	for q in state.quests():
		if q.done and not state.completed.has(q.id):
			state.completed.append(q.id)
			state.xp+=25
			state.record("Erlebnis abgeschlossen · "+q.name)
			notify("Erlebnis abgeschlossen: "+q.name+" · +25 Erfahrung")
			state.save_to()

func _refresh_status() -> void:
	for key in need_bars:
		need_bars[key].value=state.get(key)
		need_labels[key].text={"hunger":"Nahrung","thirst":"Wasser","energy":"Kraft","bond":"Rudel"}[key]+" %d"%state.get(key)
	level_label.text="Rang %d"%state.level()
	title.text=WolfWorldData.REGIONS[state.region].name
	location_hint.text="Tag %d · %s"%[1+int(state.elapsed/1200),"Wolfsblick · Umsehen durch Wischen" if first_person else "Wildnis %d/16 · Erfahrung %d"%[state.visited.size(),state.xp]]
	stats.text="Nahrung %d   Wasser %d   Kraft %d   Rudel %d"%[state.hunger,state.thirst,state.energy,state.bond]
	quest_hint.text="Alle Erlebnisse entdeckt. Folge neuen Fährten und erkunde die Wildnis."
	for q in state.quests():
		if not q.done:
			quest_hint.text="◌ "+q.name+" · "+q.progress+"\n"+q.hint
			break

func close_overlay() -> void:
	if is_instance_valid(overlay):
		ui.remove_child(overlay)
		overlay.queue_free()
		overlay=null
	look_pointer=-1
	looking_mouse=false
	stick.reset()

func modal(heading: String) -> VBoxContainer:
	close_overlay()
	stick.reset()
	overlay=ColorRect.new()
	overlay.color=Color(0.03,0.1,0.1,0.88)
	ui.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	var margin := MarginContainer.new()
	overlay.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,26)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,38)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	panel.add_theme_stylebox_override("panel",panel_style(Color("#203c42"),24))
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

func show_intro() -> void:
	var v := modal("Wolf · Wildnis & Rudel")
	v.add_child(label("Ein kleiner Wolf. Eine große Welt.",24))
	v.add_child(label("Du bist ein Jungwolf in einem natürlichen Rudel. Lerne die Gerüche deiner Heimat kennen, finde Wasser und erkunde neue Gebiete. Deine Geschichte wächst in kleinen Schritten.",20))
	v.add_child(label("Draufsicht\nMit dem Pfotenstick bewegst du dich nach oben, unten, links und rechts. Breite Wege verbinden sechzehn große Kartenbereiche.",19))
	v.add_child(label("Wolfsblick\nSchalte überall auf 3D um. Wische zum Umsehen. Alle Bäume, Tiere und Spuren bleiben am selben Ort. Schnüffeln macht Fährten sichtbar; Untersuchen liest sie oder beobachtet Tiere.",19))
	v.add_child(label("Am Computer: WASD / Pfeile · V Ansicht · F Schnüffeln · E Untersuchen · H Heulen · R Ruhen · M Karte. In 3D: Maus ziehen oder I/J/K/L zum Umsehen.",17))
	v.add_child(button("Die erste Pfote setzen",close_overlay))

func show_menu() -> void:
	var v := modal("Dein Rudelleben")
	v.add_child(label("Version 0.2.0 · Große Wildnis\nJungwolf · Dein Rudel: zwei erwachsene Wölfe und zwei Jungwölfe\nAutomatischer Spielstand alle 20 Sekunden und bei Gebietswechseln.",18))
	v.add_child(button("Erlebnisse & Aufgaben",show_quests))
	v.add_child(button("Hier ruhen",func():close_overlay();rest()))
	v.add_child(button("Ansicht weiter / näher",func():map_view.zoom=0.48 if map_view.zoom>0.6 else 0.72;close_overlay()))
	v.add_child(button("Naturtagebuch",show_journal))
	v.add_child(button("Gebietskarte",show_map))
	v.add_child(button("Steuerung & Einstieg",show_intro))
	v.add_child(button("Spielstand speichern",func():
		var success := state.save_to()
		close_overlay()
		notify("Dein Spielstand wurde gespeichert." if success else "Spielstand konnte nicht gespeichert werden.")
	))
	v.add_child(button("Neues Rudelleben starten",confirm_new_game))
	v.add_child(button("Zurück in die Wildnis",close_overlay))

func confirm_new_game() -> void:
	var v := modal("Neu beginnen?")
	v.add_child(label("Dein bisheriger Spielstand wird ersetzt. Du beginnst wieder als Jungwolf an der Rudelhöhle.",20))
	v.add_child(button("Bisheriges Spiel fortsetzen",close_overlay))
	v.add_child(button("Neues Spiel beginnen",func():
		state=WolfState.new()
		first_person=false
		world_view.visible=false
		map_view.visible=true
		mode_button.text="3D · Wolfsblick"
		scent_time=0
		change_region(0,WolfWorldData.SPAWN)
		close_overlay()
		show_intro()
	))

func show_quests() -> void:
	var v := modal("Erlebnisse")
	for q in state.quests():
		v.add_child(label(("✓ " if q.done else "◌ ")+q.name+" · "+q.progress,22))
		v.add_child(label(q.hint,18))

func show_journal() -> void:
	var v := modal("Naturtagebuch")
	v.add_child(label("Deine Entdeckungen, Fährten und Rudelmomente.",19))
	for entry in state.journal:v.add_child(label(entry,18))

func mark_territory() -> void:
	if not state.marked.has(state.region):
		state.marked.append(state.region)
		state.record("Duftmarke · "+WolfWorldData.REGIONS[state.region].name+". Du kennst diesen Weg nun am Geruch.")
		notify("Du setzt eine Duftmarke und prägst dir den Weg ein.")
		check_quests()
	else:notify("Dein vertrauter Duft ist hier schon vorhanden.")

func show_map() -> void:
	var v := modal("Die große Wildnis")
	v.add_child(label("16 verbundene Gebiete · Erkundet %d/16\nDie Karte zeigt Norden oben. Folge den gebogenen Wegen zu den offenen Kartenrändern."%state.visited.size(),17))
	var grid := GridContainer.new()
	grid.columns=4
	grid.add_theme_constant_override("h_separation",6)
	grid.add_theme_constant_override("v_separation",6)
	v.add_child(grid)
	for y in range(4):
		for x in range(4):
			var index := WolfWorldData.index_at(Vector2i(x,y))
			var p := PanelContainer.new()
			p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			p.custom_minimum_size=Vector2(0,108)
			var card := panel_style(Color(WolfWorldData.REGIONS[index].ground).darkened(0.55))
			card.content_margin_left=6
			card.content_margin_right=6
			p.add_theme_stylebox_override("panel",card)
			grid.add_child(p)
			var text: String = ("● Hier\n" if state.region==index else "✓ \n" if state.visited.has(index) else "◌ \n")+WolfWorldData.REGIONS[index].name
			p.add_child(label(text,12))
	v.add_child(label("Rudelhöhle: Dein sicherer Ausgangspunkt. Norden führt zur Bergwiese, Osten zum Kiefernwald, Westen zu den Moosruinen und Süden zum Schilfmoor.",17))
	v.add_child(label("Goldene Naturorte liegen abseits der Wege. Schnee im Norden, Küste im Südwesten und Dorfrand im Süden bieten neue Düfte und Begegnungen.",17))
	v.add_child(button("Weiter erkunden",close_overlay))

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST:
		if state!=null:state.save_to()
		if stick!=null:stick.reset()
		looking_mouse=false
		look_pointer=-1
