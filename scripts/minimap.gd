class_name WolfMinimap
extends Control

var game: Node

func _ready() -> void:
	custom_minimum_size=Vector2(108,108)
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if game==null:return
	var center := size*0.5
	var radius := minf(size.x,size.y)*0.5-5
	draw_circle(center,radius+3,Color("#c7ab68"))
	draw_circle(center,radius,Color("#223934"))
	draw_circle(center,radius-4,Color(WolfWorldData.REGIONS[game.state.region].ground).darkened(0.18))
	var scale_f := (radius-9)*2/3200.0
	var origin := center-Vector2(1600,1600)*scale_f
	for vertical in [true,false]:
		var points := WolfWorldData.path_points(game.state.region,vertical)
		for i in range(points.size()-1):draw_line(origin+points[i]*scale_f,origin+points[i+1]*scale_f,Color("#d2c187"),2)
	for obj in game.world.objects:
		var p: Vector2=origin+obj.p*scale_f
		if p.distance_to(center)>radius-6:continue
		match obj.kind:
			"water":draw_circle(p,7,Color("#58b9c4"))
			"den":draw_circle(p,4,Color("#f4e5b0"))
			"landmark","discovery":draw_circle(p,3,Color("#edc457"))
			"tree":draw_circle(p,1.5,Color("#355b37"))
	var p: Vector2 = origin+game.state.pos*scale_f
	var d: Vector2=Vector2(-sin(game.world_view.yaw),-cos(game.world_view.yaw)) if game.first_person else game.state.facing
	var side := Vector2(-d.y,d.x)
	draw_colored_polygon(PackedVector2Array([p+d*7,p-d*4+side*4,p-d*4-side*4]),Color("#ffe6a0"))
	draw_string(ThemeDB.fallback_font,center+Vector2(-5,-radius+13),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f2e8c5"))
