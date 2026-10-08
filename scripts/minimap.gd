class_name WolfMinimap
extends Control

var game: Node
var path_region := -1
var path_mesh: ArrayMesh

func _ready() -> void:
	custom_minimum_size=Vector2(83,83)
	mouse_filter=Control.MOUSE_FILTER_STOP

func _draw() -> void:
	if game==null:return
	var center := size*0.5
	var radius := minf(size.x,size.y)*0.5-5
	draw_circle(center,radius+3,Color("#c7ab68"))
	draw_circle(center,radius,Color("#223934"))
	draw_circle(center,radius-4,Color(WolfWorldData.REGIONS[game.state.region].ground).darkened(0.18))
	var scale_f := (radius-9)*2/3200.0
	var origin := center-Vector2(1600,1600)*scale_f
	if path_region!=game.state.region:
		path_region=game.state.region
		var paths := WolfWorldData.render_paths(path_region,game.world.objects)
		path_mesh=WolfWildernessPaths.mesh_2d(paths,paths.color)
	if path_mesh!=null:draw_mesh(path_mesh,null,Transform2D(0,Vector2.ONE*scale_f,0,origin))
	for obj in game.world.objects:
		var p: Vector2=origin+obj.p*scale_f
		if p.distance_to(center)>radius-6:continue
		match obj.kind:
			"water":draw_circle(p,7,Color("#58b9c4"))
			"den":draw_circle(p,4,Color("#f4e5b0"))
			"landmark","discovery":draw_circle(p,3,Color("#edc457"))
			"tree":draw_circle(p,1.5,Color("#355b37"))
	if game.state.waypoint_region>=0:
		var route: PackedVector2Array=game.navigation_points
		var points := PackedVector2Array()
		for point in route:points.append(origin+point*scale_f)
		if points.size()>1:draw_polyline(points,Color("#d7ad69"),1.5,true)
		var target: Vector2=game.goal_position()
		var q: Vector2=origin+target*scale_f
		draw_circle(q,3,Color("#eaba77"))
	var p: Vector2 = origin+game.state.pos*scale_f
	var d: Vector2=Vector2(-sin(game.world_view.yaw),-cos(game.world_view.yaw)) if game.first_person else game.state.facing
	var side := Vector2(-d.y,d.x)
	draw_colored_polygon(PackedVector2Array([p+d*7,p-d*4+side*4,p-d*4-side*4]),Color("#ffe6a0"))
	draw_string(ThemeDB.fallback_font,center+Vector2(-5,-radius+13),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f2e8c5"))

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed):
		game.show_map()
		accept_event()
