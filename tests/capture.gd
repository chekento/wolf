extends SceneTree

var captured := 0
var game: Node

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	game._refresh_status()
	if game.first_person:game.world_view.sync_camera()
	else:game.map_view.queue_redraw()
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(path)
	if result!=OK:
		push_error("Capture failed: "+path)
		quit(1)
		return
	captured+=1

func run() -> void:
	WolfState.save_path="user://wolf_capture_state.json"
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.show_main_story()
	await capture("res://docs/main-story-start.png")
	game._begin_main_story()
	game.show_main_story()
	await capture("res://docs/main-story.png")
	game.state=WolfState.new()
	game.show_nature_journeys()
	await capture("res://docs/nature-journeys.png")
	var nature_offer: Dictionary=game.state.nature_journeys_options()[0]
	game.state.begin_nature_journey(nature_offer.id)
	game.show_nature_journeys()
	await capture("res://docs/nature-journey-active.png")
	game.state.abandon_nature_journey()
	game.show_intro()
	await capture("res://docs/intro.png")
	game.close_overlay()
	game.state=WolfState.new()
	game.change_region(0,WolfWorldData.SPAWN)
	game.scent_time=18
	game.toast.text=""
	game.toast_time=0
	await capture("res://docs/top-down.png")
	game.state.pos=Vector2(1700,1660)
	game.state.facing=Vector2(0,-1)
	game.toggle_view()
	game.world_view.yaw=-0.35
	game.toast.text=""
	game.toast_time=0
	await capture("res://docs/wolfs-eye.png")
	game.show_map(true)
	game.state.map_reveal=true
	await capture("res://docs/world-map.png")
	game.map_panel.set_local(0)
	game.map_panel.zoom_by(1.4)
	await capture("res://docs/region-map.png")
	game.show_map(false,game.atlas_view_state())
	await capture("res://docs/atlas-list.png")
	game.show_story()
	await capture("res://docs/story.png")
	game.show_menu()
	await capture("res://docs/menu.png")
	game.show_encounter()
	await capture("res://docs/encounter.png")
	game.show_pack()
	await capture("res://docs/pack.png")
	game.close_overlay()
	game.toggle_view()
	game.change_region(5,Vector2(1650,1720))
	game.toast.text=""
	await capture("res://docs/snow.png")
	game.change_region(2,Vector2(1200,1650))
	game.toast.text=""
	await capture("res://docs/river.png")
	game.change_region(0,Vector2(1350,2100))
	game.state.facing=Vector2.DOWN
	game.toggle_view()
	game.world_view.yaw=-2.68
	game.world_view.pitch=-0.12
	game.toast.text=""
	await capture("res://docs/pack-3d.png")
	game.state.pos=Vector2(1690,1800)
	game.state.facing=Vector2.UP
	game.world_view.yaw=0.2
	game.world_view.pitch=-0.15
	game.switch_camera()
	game.player_mood="laufen"
	game.player_gait=0.7
	game.toast.text=""
	await capture("res://docs/follow-camera.png")
	game.state.active_encounter={}
	for serial in range(80):
		game.state.encounter_serial=serial
		if game.state.encounter_status().task=="quiet_watch":game.state.begin_encounter();break
	game.state.sound_enabled=false
	game.state.pos=Vector2(1600,1800)
	var kind: String={"Reh":"deer","Hase":"rabbit","Fuchs":"fox"}[game.state.active_encounter.detail]
	var watched := {"kind":kind,"p":Vector2(1600,1540),"home":Vector2(1600,1540),"phase":0.0,"mood":"lauschen","alarm":0.0,"facing":Vector2.LEFT,"speed":0.0,"gait":0.0}
	game.world.animals=[watched];game.world.objects=[];game.world.tracks=[]
	game.scent_time=0
	game.set_process(false)
	game.world_view.rebuild()
	if game.state.camera_follow:game.switch_camera()
	game.world_view.yaw=0;game.world_view.pitch=-.14
	game.player_speed=0;game.interact()
	for i in range(37):game._tick_wildlife_observation(.1)
	game._refresh_status();game.world_view.sync_camera()
	game.toast.text="";game.toast_time=0
	await capture("res://docs/observation.png")
	game.show_encounter()
	await capture("res://docs/observation-menu.png")
	game.close_overlay()
	var completed: Array=[]
	for i in range(4):completed.append(WolfMainStory.chapters()[i].id)
	game.state.main_story_progress=WolfMainStory.restored({"version":1,"started":true,"chapter":4,"stage":0,"completed_chapters":completed})
	game.change_region(3,Vector2(1600,1800))
	var story_deer := {"kind":"deer","p":Vector2(1600,1540),"home":Vector2(1600,1540),"phase":0.0,"mood":"lauschen","attention":0.0,"alarm":0.0,"facing":Vector2.LEFT,"speed":0.0,"gait":0.0}
	game.world.animals=[story_deer];game.world.objects=[];game.world.tracks=[]
	game.world_view.rebuild();game.world_view.yaw=0;game.world_view.pitch=-.14
	game.player_speed=0;game.interact()
	for i in range(20):game._tick_main_story(.1)
	game._refresh_status();game.world_view.sync_camera();game.toast.text=""
	await capture("res://docs/main-story-watch.png")
	game.show_main_story()
	await capture("res://docs/main-story-mission.png")
	game.set_process(false)
	game.sound.stream_paused=false;game.ambient.stream_paused=false
	await create_timer(0.2).timeout
	game._release_audio()
	await create_timer(0.2).timeout
	root.remove_child(game);game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf UI capture: %d views completed"%captured)
	quit(0 if captured==22 else 1)
