extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:call_deferred("run")

func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func settled() -> void:
	for i in range(6):await process_frame

func tap(game: Node,index: int,point: Vector2,down: bool=true,canceled: bool=false) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index=index;ev.position=point;ev.pressed=down;ev.canceled=canceled
	game._input(ev)

func move(game: Node,index: int,point: Vector2,delta: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index=index;ev.position=point;ev.relative=delta
	game._input(ev)

func middle(button: Control) -> Vector2:
	return button.get_global_rect().get_center()

func run() -> void:
	WolfState.save_path="user://wolf_multitouch.json"
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	var previous_mouse := Input.emulate_mouse_from_touch
	var game=load("res://main.tscn").instantiate()
	game.state.sound_enabled=false
	root.add_child(game);await settled()
	game.close_overlay();game.set_process(false)
	check(not Input.emulate_mouse_from_touch,"gameplay suppresses duplicate emulated mouse taps")
	check(game.touch_owners.is_empty(),"fresh touch router has no stale fingers")
	game.toggle_view();await settled()
	var stick_center: Vector2=middle(game.stick)
	var look_center: Vector2=game.look_area.get_global_rect().get_center()
	check(not game.stick.get_global_rect().has_point(look_center),"camera and joystick hit boxes are distinct")
	tap(game,2,stick_center)
	move(game,2,stick_center+Vector2(38,-8),Vector2(38,-8))
	check(game.stick.pointer==2 and game.stick.vector.x>.40,"finger 2 drives joystick independently")
	tap(game,4,stick_center)
	move(game,4,stick_center-Vector2(34,0),Vector2(-34,0))
	check(game.stick.pointer==2 and game.stick.vector.x>.40,"second finger on joystick cannot steal the movement owner")
	tap(game,4,stick_center,false)
	check(game.stick.pointer==2,"stray release cannot reset other owner's joystick")
	tap(game,5,look_center)
	check(game.look_pointer==5 and game.stick.pointer==2,"finger 5 captures 3D look while movement remains held")
	var old_yaw: float=game.world_view.yaw
	move(game,5,look_center+Vector2(44,5),Vector2(44,5))
	check(absf(game.world_view.yaw-old_yaw)>.001 and game.stick.vector.x>.40,"camera rotates without interrupting walking")
	var action_center: Vector2=middle(game.hud_action_controls[0])
	tap(game,8,action_center)
	check(game.touch_owners.has(8) and game.touch_owners.size()==3,"third simultaneous finger captures a gameplay action")
	tap(game,8,action_center,false)
	check(game.scent_time>20 and game.stick.pointer==2 and game.look_pointer==5,"scent action fires once while both movement and camera remain held")
	var scent: float=game.scent_time
	tap(game,9,action_center)
	tap(game,9,action_center)
	tap(game,9,action_center,false,true)
	check(game.scent_time==scent,"cancelled tap and duplicate down do not fire an action")
	var sprint_pos: Vector2=middle(game.sprint_button)
	var sneak_pos: Vector2=middle(game.sneak_button)
	tap(game,10,sprint_pos)
	tap(game,11,sneak_pos)
	check(game.touch_owners.has(10) and game.touch_owners.has(11),"two independently pressed movement modifiers are tracked")
	tap(game,11,sneak_pos,false)
	tap(game,10,sprint_pos,false)
	check(game.sprint_button.button_pressed and game.sneak_button.button_pressed,"multitouch toggles both sprint and sneak buttons")
	tap(game,12,middle(game.fold_button))
	tap(game,12,middle(game.fold_button),false)
	await settled()
	check(not game.state.compact_hud and game.stick.pointer==2,"folding HUD during held movement does not release joystick")
	tap(game,2,stick_center,false)
	check(game.stick.pointer==-1 and game.stick.vector==Vector2.ZERO and game.look_pointer==5,"movement finger releases without releasing camera")
	old_yaw=game.world_view.yaw
	move(game,5,look_center+Vector2(60,16),Vector2(16,11))
	check(absf(game.world_view.yaw-old_yaw)>.001,"camera finger continues after movement finger lifts")
	tap(game,5,look_center,false)
	check(game.look_pointer==-1 and game.touch_owners.is_empty(),"all fingers release cleanly with no ghost controls")
	game.set_hud_compact(true,false)
	var howl_pos: Vector2=middle(game.hud_action_controls[2])
	tap(game,14,howl_pos)
	tap(game,14,howl_pos+Vector2(300,0),false)
	check(game.howl_cooldown==0,"dragging outside an action button cancels that tap")
	tap(game,15,howl_pos)
	tap(game,15,howl_pos,false)
	check(game.howl_cooldown>0,"proper multitouch action tap executes exactly once")
	tap(game,16,stick_center)
	tap(game,17,game.look_area.get_global_rect().get_center())
	game.show_menu()
	check(game.touch_owners.is_empty() and game.stick.vector==Vector2.ZERO and game.look_pointer==-1,"opening menu cancels all held gameplay touches")
	check(Input.emulate_mouse_from_touch,"normal touch-to-mouse emulation is restored for scrolling menus")
	game.close_overlay();await settled()
	check(not Input.emulate_mouse_from_touch,"returning to play restores independent raw multi-touch")
	tap(game,18,stick_center)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.touch_owners.is_empty() and game.stick.pointer==-1,"app backgrounding clears all captured fingers")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	game._release_audio()
	root.remove_child(game);game.queue_free();await settled()
	check(Input.emulate_mouse_from_touch==previous_mouse,"global touch emulation setting restored when game exits")
	for path in [WolfState.save_path,WolfState.save_path+".wildlife.json"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	print("Wolf multitouch: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
