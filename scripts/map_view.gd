class_name WolfMapView
extends Node2D

var game: Node
var zoom := 0.64

func _draw() -> void:
	if game==null:return
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size),Color("#172f31"))
	var center := Vector2(size.x*0.5,size.y*0.48)
	draw_set_transform(center-game.state.pos*zoom,0,Vector2.ONE*zoom)
	var ground := Color(WolfWorldData.REGIONS[game.state.region].ground)
	draw_rect(Rect2(Vector2.ZERO,WolfWorldData.SIZE),ground)
	# Stable decorative geometry; no regenerated noise per frame.
	var rng := RandomNumberGenerator.new()
	rng.seed = 290+game.state.region
	for i in range(250):
		var p := Vector2(rng.randf_range(25,1575),rng.randf_range(25,1575))
		draw_circle(p,rng.randf_range(3,22),ground.lightened(0.08) if i%2==0 else ground.darkened(0.05))
		if i%4==0:
			draw_line(p,p+Vector2(-4,-8),Color("#527453"),2)
			draw_line(p+Vector2(4,0),p+Vector2(5,-10),Color("#527453"),2)
		if i%13==0:
			draw_circle(p,3,Color("#efd6a2"))
			draw_circle(p+Vector2(7,3),2,Color("#d5b8c9"))
	# Crossroads are continuous with reciprocal exits.
	draw_line(Vector2(800,0),Vector2(800,1600),ground.darkened(0.09),128)
	draw_line(Vector2(0,800),Vector2(1600,800),ground.darkened(0.09),128)
	draw_line(Vector2(800,0),Vector2(800,1600),Color("#b6b292"),100)
	draw_line(Vector2(0,800),Vector2(1600,800),Color("#b6b292"),100)
	for i in range(30):
		draw_circle(Vector2(795+sin(float(i)*3.0)*25,i*54),2,Color("#929775"))
	if game.state.region==2:
		draw_line(Vector2(480,0),Vector2(480,1600),Color("#6badae"),150)
		draw_line(Vector2(460,0),Vector2(460,1600),Color("#8cc6bc"),80)
		# A ford in the main path is the safe crossing.
		draw_rect(Rect2(390,753,180,94),Color("#b8b89b"))
	for obj in game.world.objects:
		_draw_object(obj)
	for track in game.world.tracks:
		if game.scent_time>0 or game.state.found.has(track.id):
			var c := Color("#f5d389") if not game.state.found.has(track.id) else Color("#bcc4b2")
			_draw_track(track.p,c)
			if game.scent_time>0 and not game.state.found.has(track.id):
				draw_arc(track.p,26+sin(game.clock*3.0)*3,0,TAU,24,Color(c,0.45),2)
	for a in game.world.animals:
		_draw_animal(a.p,a.kind,Vector2(0,-1),false)
	_draw_animal(game.state.pos,"wolf",game.state.facing,true)
	if game.scent_time>0:
		draw_arc(game.state.pos,145,0,TAU,64,Color(0.94,0.84,0.55,0.25),3)
	# Soft dusk veil leaves paths readable.
	var night := (1.0-cos(game.state.elapsed/300.0))*0.065
	draw_rect(Rect2(Vector2.ZERO,WolfWorldData.SIZE),Color(0.06,0.13,0.27,night))
	for direction in WolfWorldData.REGIONS[game.state.region].links:
		var p: Vector2
		match direction:
			"east":p=Vector2(1500,800)
			"west":p=Vector2(100,800)
			"north":p=Vector2(800,100)
			_:p=Vector2(800,1500)
		draw_circle(p,23,Color("#e2d5ac"))
		var d := (WolfWorldData.entry_point(direction)-Vector2(800,800)).normalized()*-1
		draw_line(p-d*12,p+d*12,Color("#3c6860"),4)
		draw_line(p+d*12,p+d*4+Vector2(-d.y,d.x)*8,Color("#3c6860"),4)
		draw_line(p+d*12,p+d*4-Vector2(-d.y,d.x)*8,Color("#3c6860"),4)
	draw_set_transform(Vector2.ZERO)

func _draw_object(obj: Dictionary) -> void:
	var p: Vector2=obj.p
	var s: float=obj.scale
	match obj.kind:
		"tree":
			draw_circle(p+Vector2(12,13),48*s,Color(0.08,0.18,0.14,0.16))
			draw_circle(p,46*s,Color("#284c42"))
			if obj.variant==0:
				for layer in range(3):
					var r := (42-layer*11)*s
					var c := Color("#3f7257").lightened(layer*0.065)
					draw_colored_polygon(PackedVector2Array([p+Vector2(0,-r),p+Vector2(r*0.84,r*0.42),p+Vector2(r*0.42,r*0.38),p+Vector2(r*0.64,r),p+Vector2(0,r*0.63),p+Vector2(-r*0.64,r),p+Vector2(-r*0.42,r*0.38),p+Vector2(-r*0.84,r*0.42)]),c)
			else:
				for i in range(5):
					var v := Vector2(cos(i*1.26),sin(i*1.26))*20*s
					draw_circle(p+v,27*s,Color("#547c53").lightened(i*0.025))
				draw_circle(p+Vector2(-8,-11)*s,23*s,Color("#7f9a60"))
		"rock":
			draw_circle(p+Vector2(8,8),28*s,Color(0.12,0.2,0.2,0.15))
			draw_colored_polygon(PackedVector2Array([p+Vector2(-28,-12)*s,p+Vector2(-10,-27)*s,p+Vector2(23,-18)*s,p+Vector2(29,14)*s,p+Vector2(5,29)*s,p+Vector2(-26,16)*s]),Color("#85918b"))
			draw_colored_polygon(PackedVector2Array([p+Vector2(-28,-12)*s,p+Vector2(-10,-27)*s,p+Vector2(23,-18)*s,p+Vector2(2,1)*s]),Color("#b3bab0"))
		"water":
			if game.state.region==2:return
			draw_circle(p,132*s,Color("#789687"))
			draw_circle(p,120*s,Color("#519397"))
			draw_circle(p+Vector2(-13,-14),91*s,Color("#79b7b1"))
			for i in range(4):
				draw_arc(p+Vector2(0,15*i),65-i*11,3.6,5.6,24,Color(0.8,0.94,0.86,0.4),2)
		"den":
			draw_circle(p,76,Color("#617864"))
			draw_circle(p+Vector2(0,-6),66,Color("#9a9a83"))
			draw_circle(p+Vector2(0,16),39,Color("#364744"))
			draw_circle(p+Vector2(0,25),28,Color("#233431"))
			draw_arc(p+Vector2(0,-6),60,3.4,5.8,20,Color("#c2bda0"),7)
		"food":
			if game.state.food_cooldown>0:return
			draw_circle(p,22,Color("#c1ac7e"))
			draw_circle(p+Vector2(-4,2),12,Color("#9d7260"))
			draw_circle(p+Vector2(7,-3),8,Color("#c09479"))
		"landmark":
			draw_circle(p+Vector2(7,9),36,Color(0.1,0.2,0.17,0.15))
			draw_rect(Rect2(p-Vector2(22,28),Vector2(44,56)),Color("#b9b79d"))
			draw_rect(Rect2(p-Vector2(15,21),Vector2(30,42)),Color("#d5cfb1"))
			draw_line(p+Vector2(-8,-10),p+Vector2(6,8),Color("#85987b"),3)

func _draw_track(p: Vector2,c: Color) -> void:
	for side in [-1,1]:
		var q := p+Vector2(side*9,side*5)
		draw_circle(q,4,c)
		draw_circle(q+Vector2(-3,-7),2,c)
		draw_circle(q+Vector2(3,-7),2,c)

func _draw_animal(p: Vector2,kind: String,facing: Vector2,player: bool) -> void:
	var angle := facing.angle()+PI*0.5
	var c := Color("#acbdc3") if kind=="wolf" else Color("#baa180") if kind=="deer" else Color("#cfbca2")
	var body := 20.0 if kind=="wolf" else 22.0 if kind=="deer" else 12.0
	draw_circle(p+Vector2(4,7),body,Color(0.1,0.18,0.18,0.22))
	if player:
		draw_arc(p,31,0,TAU,40,Color(0.94,0.88,0.65,0.65),2)
	var forward := Vector2(0,-1).rotated(angle)
	var right := Vector2(1,0).rotated(angle)
	draw_line(p-forward*15,p-forward*32+right*sin(game.clock*5)*3,c.darkened(0.15),10 if kind=="wolf" else 5)
	for i in [-1,1]:
		draw_circle(p+right*i*10+forward*6,5,c.darkened(0.12))
		draw_circle(p+right*i*10-forward*11,5,c.darkened(0.12))
	draw_circle(p,body,c)
	draw_circle(p+forward*10,body*0.85,c.lightened(0.09))
	var head := p+forward*22
	draw_circle(head,13 if kind!="rabbit" else 9,c.lightened(0.14))
	for i in [-1,1]:
		var ear: Vector2 = head+right*i*8+forward*6
		draw_colored_polygon(PackedVector2Array([ear-right*5,ear+forward*(16 if kind=="rabbit" else 9),ear+right*5]),c.darkened(0.22))
		draw_circle(head+forward*5+right*i*6,2.3,Color("#283c40"))
	draw_circle(head+forward*12,4 if kind=="wolf" else 2.5,Color("#283c40"))
