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
	game.state.pos=Vector2(850,830)
	game.state.facing=Vector2(0,-1)
	game.toggle_view()
	game.world_view.yaw=-0.35
	game.toast.text=""
	game.toast_time=0
	await capture("res://docs/wolfs-eye.png")
	game.show_map()
	await capture("res://docs/world-map.png")
	game.close_overlay()
	quit()
