extends SceneTree
func _initialize() -> void:call_deferred("run")
func shot(game: Node,path: String) -> void:
	game._update_animals(.016);game._tick_main_story(.016)
	game._refresh_status();game.world_view.sync_camera()
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	WolfState.save_path="user://wolf_hud_capture.json"
	var game = load("res://main.tscn").instantiate()
	game.state.sound_enabled=false;root.add_child(game);await process_frame
	game.close_overlay();game.set_process(false)
	game.state.begin_main_story();game.state.main_story_progress.stage=1
	game.state.pos=Vector2(1580,2380);game.state.facing=Vector2.DOWN
	game.state.camera_follow=false
	if not game.first_person:game.toggle_view()
	game.world_view.yaw=PI;game.world_view.pitch=-.10
	game.world_view.rebuild();game.notify("Frische Fährten und Pfotenspuren erscheinen im Wind. Nähere dich leise und prüfe die Trittsiegel.")
	await shot(game,"res://docs/hud-mission-folded.png")
	game.observation_fold.pressed.emit()
	await shot(game,"res://docs/hud-mission-expanded.png")
	game.observation_details.pressed.emit()
	await shot(game,"res://docs/hud-mission-details.png")
	game.close_overlay();game.observation_fold.pressed.emit()
	await shot(game,"res://docs/hud-mission-return.png")
	root.size=Vector2i(360,640);root.content_scale_size=Vector2i(360,640)
	game.observation_fold.pressed.emit()
	await shot(game,"res://docs/hud-mission-small.png")
	game._release_audio();root.remove_child(game);game.queue_free()
	for i in range(5):await process_frame
	await create_timer(.2).timeout
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf HUD capture: 5 views completed")
	quit()
