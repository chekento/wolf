extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	WolfState.save_path="user://wolf_capture_state.json"
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
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
	game.show_map()
	game.state.map_reveal=true
	await capture("res://docs/world-map.png")
	game.map_panel.set_local(0)
	game.map_panel.zoom_by(1.4)
	await capture("res://docs/region-map.png")
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
	game.set_process(false)
	game.sound.stream_paused=false;game.ambient.stream_paused=false
	await create_timer(0.2).timeout
	game._release_audio()
	root.remove_child(game);game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	quit()
