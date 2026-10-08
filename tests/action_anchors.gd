extends SceneTree

const MapView = preload("res://scripts/map_view.gd")
const Animal = preload("res://scripts/animal_model.gd")
const MOODS := ["schnüffeln","trinken","heulen","ruhen","spielen","begrüßen"]
var checks := 0
var failures := 0

class FixtureState extends RefCounted:
	var pos := Vector2.ZERO
	var region := 0
	var reduced_motion := true
	func growth() -> float:return .72

class FixtureGame extends Node:
	var state := FixtureState.new()
	var clock := 1.0

class AnchorView extends WolfMapView:
	var mood := "lauschen"
	var direction := Vector2.LEFT
	func _draw() -> void:
		draw_set_transform(get_viewport_rect().size*Vector2(.5,.48))
		_draw_animal(Vector2.ZERO,"wolf",direction,true,true,0,0,mood)

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);failures+=1

func transformed_bounds(transform: Transform2D,rect: Rect2) -> Rect2:
	var corners := [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]
	var result := Rect2(transform*corners[0],Vector2.ZERO)
	for corner in corners:result=result.expand(transform*corner)
	return result

func solid_center(image: Image) -> Vector2:
	var center := Vector2.ZERO
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			# Ignore the translucent shadow and player ring; measure animal art.
			if image.get_pixel(x,y).a>.86:center+=Vector2(x,y);count+=1
	return center/count if count>0 else Vector2.INF

func render_anchor_checks() -> void:
	var viewport := SubViewport.new()
	viewport.size=Vector2i(384,384)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game := FixtureGame.new()
	var view := AnchorView.new()
	view.game=game;view.zoom=1
	viewport.add_child(game);viewport.add_child(view)
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		view.direction=direction
		view.mood="lauschen";game.clock+=.2;view.queue_redraw()
		for frame in range(3):await process_frame
		await RenderingServer.frame_post_draw
		var initial := solid_center(viewport.get_texture().get_image())
		var maximum_offset := 0.0
		var maximum_return := 0.0
		for mood in MOODS:
			view.mood=mood;game.clock+=.2;view.queue_redraw()
			for frame in range(3):await process_frame
			await RenderingServer.frame_post_draw
			var acting := solid_center(viewport.get_texture().get_image())
			maximum_offset=maxf(maximum_offset,absf(acting.x-initial.x))
			view.mood="lauschen";game.clock+=.2;view.queue_redraw()
			for frame in range(3):await process_frame
			await RenderingServer.frame_post_draw
			var returned := solid_center(viewport.get_texture().get_image())
			maximum_return=maxf(maximum_return,absf(returned.x-initial.x))
		print(JSON.stringify({"direction":str(direction),"action_content_offset_px":maximum_offset,"return_content_offset_px":maximum_return}))
		# Artwork changes its outline, but cannot jump a full 124 px cell.
		check(initial.is_finite() and maximum_offset<24,"actual Canvas action art stays near its ground anchor "+str(direction))
		check(maximum_return<2,"actual Canvas returns to the same standing anchor "+str(direction))
	root.remove_child(viewport);viewport.queue_free()
	await process_frame

func run() -> void:
	var anchor := Vector2(931.5,648.0)
	for dimensions in [Vector2(124,124),Vector2(155,155),Vector2(68,68),Vector2(108,133)]:
		var rect := MapView.action_sprite_rect(dimensions)
		var normal: Transform2D=MapView.action_sprite_transform(anchor,false)
		var mirrored: Transform2D=MapView.action_sprite_transform(anchor,true)
		check(rect.size.x>0 and rect.size.y>0,"atlas destination sizes stay positive "+str(dimensions))
		check((normal*rect.get_center()).distance_to(anchor)<.0001 and (mirrored*rect.get_center()).distance_to(anchor)<.0001,"mirroring keeps the same sprite center "+str(dimensions))
		check(transformed_bounds(normal,rect).is_equal_approx(transformed_bounds(mirrored,rect)),"left and right artwork occupy identical destination bounds "+str(dimensions))
		var scaling_ok := true
		for zoom in [.38,.72,1.85]:
			var camera := Transform2D(.17,Vector2(-126,88)).scaled_local(Vector2.ONE*zoom)
			scaling_ok=scaling_ok and (camera*normal*rect.get_center()).distance_to(camera*anchor)<.0001 and (camera*mirrored*rect.get_center()).distance_to(camera*anchor)<.0001
		check(scaling_ok,"zoom and camera transforms preserve the common atlas anchor "+str(dimensions))

	for species in ["wolf","fox","deer","rabbit"]:
		var model := Animal.new()
		root.add_child(model);model.build(species)
		model.position=Vector3(12.5,2.4,-6.25)
		model.rotation.y=.65
		model.set_foot_heights([-.018,.014,-.008,.022])
		model.animate(.3,0,"lauschen",1.0)
		var original: Transform3D=model.transform
		var torso_anchor := Vector2(model.torso.position.x,model.torso.position.z)
		var stationary := true
		var finite := true
		var contact_error := 0.0
		var maximum_side_step := 0.0
		var previous_nose: Vector3=model.nose_position()
		var time := 1.0
		for mood in MOODS+["lauschen"]:
			for frame in range(120):
				time+=1.0/60.0
				model.animate(.3,0,mood,time,false,.65,.4)
				stationary=stationary and model.transform.is_equal_approx(original) and Vector2(model.torso.position.x,model.torso.position.z).distance_to(torso_anchor)<.00001
				var nose: Vector3=model.nose_position()
				maximum_side_step=maxf(maximum_side_step,absf(nose.x-previous_nose.x))
				finite=finite and nose.is_finite()
				previous_nose=nose
				for i in range(4):contact_error=maxf(contact_error,absf(model.foot_position(i).y-model.foot_ground[i]-model.paw_sizes[i].y))
		check(stationary,"3D actions never translate the model or torso ground anchor "+species)
		check(finite and maximum_side_step<.10,"3D action head turns remain continuous "+species)
		check(contact_error<.003,"3D actions retain all four terrain contacts "+species)
		model.free()

	# CI uses Dummy headless rendering. Real GL executions additionally
	# verify the actual draw command, including action entry and exit.
	if DisplayServer.get_name()!="headless":await render_anchor_checks()
	print("Action anchor checks: ",checks,"; failures: ",failures)
	quit(failures)
