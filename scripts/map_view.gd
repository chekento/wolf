class_name WolfMapView
extends Node2D

var game: Node
var zoom := 0.72
var bounds: Rect2

func _draw() -> void:
	if game==null:return
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size),Color("#213c36"))
	var center := Vector2(size.x*0.5,size.y*0.48)
	bounds=Rect2(game.state.pos-size/(2*zoom),size/zoom).grow(220)
	draw_set_transform(center-game.state.pos*zoom,0,Vector2.ONE*zoom)
	var biome: String=WolfWorldData.REGIONS[game.state.region].biome
	var ground := Color(WolfWorldData.REGIONS[game.state.region].ground)
	draw_rect(Rect2(Vector2.ZERO,WolfWorldData.SIZE),ground)
	for d in game.world.decor:
		if not bounds.has_point(d.p):continue
		var p: Vector2=d.p
		var r: float=d.size
		var grass := Color("#567d24") if biome!="snow" else Color("#b2cbd5")
		match d.variant:
			0,1:draw_circle(p,r*2,Color(ground.darkened(0.1),0.30))
			2,3:
				draw_line(p,p+Vector2(-3,-r),grass,1.5)
				draw_line(p+Vector2(3,0),p+Vector2(5,-r*1.3),grass.lightened(0.16),1.5)
				_draw_flower(p+Vector2(-3,-r),2.2,Color("#f4d358"))
			4:_draw_flower(p,2.4,Color("#faf3d5"))
			5:_draw_flower(p,2,Color("#b9a1d8"))
			6:draw_circle(p,2,Color("#6f7951"))
	for vertical in [true,false]:
		var points := WolfWorldData.path_points(game.state.region,vertical)
		draw_polyline(points,ground.darkened(0.14),140,true)
		draw_polyline(points,Color("#ddc58a") if biome!="snow" else Color("#ebf3f0"),112,true)
		draw_polyline(points,Color("#e7cf95") if biome!="snow" else Color("#f8fcfa"),75,true)
	if biome=="river":
		var river := PackedVector2Array()
		for i in range(65):river.append(Vector2(WolfWorldData.river_x(i*50),i*50))
		draw_polyline(river,Color("#537c57"),226,true)
		draw_polyline(river,Color("#4c9db7"),195,true)
		draw_polyline(river,Color("#56c2d0"),151,true)
		for y in range(40,3200,60):
			var p := Vector2(WolfWorldData.river_x(y),y)
			if bounds.has_point(p):draw_arc(p+Vector2(sin(game.clock+y)*20,0),30,0.1,2.4,10,Color(0.8,0.98,0.98,0.65),2)
	if biome=="coast":
		draw_rect(Rect2(0,0,445,3200),Color("#3b9fb4"))
		draw_line(Vector2(445,0),Vector2(445,3200),Color("#83d9d5"),35)
		for y in range(0,3200,55):
			var q := Vector2(437+sin(game.clock*2+y)*9,y)
			if bounds.has_point(q):draw_arc(q,25,-1.5,1.5,16,Color(0.9,0.99,0.93,0.6),3)
	# Ground objects first. Taller objects and animals are sorted by depth.
	var items: Array[Dictionary]=[]
	for obj in game.world.objects:
		if not bounds.has_point(obj.p):continue
		if obj.kind in ["water","flowers","bridge","food","discovery"]:_draw_object(obj,biome)
		else:items.append({"p":obj.p,"object":obj})
	for t in game.world.tracks:
		if bounds.has_point(t.p) and (game.scent_time>0 or game.state.found.has(t.id)):
			_draw_track(t.p,Color("#ffda77") if not game.state.found.has(t.id) else Color("#8a9b76"))
	for a in game.world.animals:
		if bounds.has_point(a.p):items.append({"p":a.p,"animal":a})
	items.append({"p":game.state.pos,"player":true})
	items.sort_custom(func(a:Dictionary,b:Dictionary):return a.p.y<b.p.y)
	for item in items:
		if item.has("object"):_draw_object(item.object,biome)
		elif item.has("animal"):
			var a: Dictionary=item.animal
			_draw_animal(a.p,a.kind,a.get("facing",Vector2.LEFT),false,a.get("young",false))
		else:_draw_animal(game.state.pos,"wolf",game.state.facing,true,true)
	if game.scent_time>0:draw_arc(game.state.pos,160,0,TAU,64,Color(0.98,0.83,0.43,0.22),2)
	for direction in WolfWorldData.REGIONS[game.state.region].links:
		var p := WolfWorldData.entry_point({"east":"west","west":"east","north":"south","south":"north"}[direction])
		if not bounds.has_point(p):continue
		draw_circle(p,25,Color("#dcc594"))
		draw_circle(p,21,Color("#294c38"))
		var d: Vector2={"north":Vector2.UP,"south":Vector2.DOWN,"east":Vector2.RIGHT,"west":Vector2.LEFT}[direction]
		var side := Vector2(-d.y,d.x)
		draw_colored_polygon(PackedVector2Array([p+d*12,p-d*8+side*8,p-d*8-side*8]),Color("#ffdc81"))
	var dusk := (1-cos(game.state.elapsed/250))*0.06
	draw_rect(Rect2(Vector2.ZERO,WolfWorldData.SIZE),Color(0.06,0.10,0.25,dusk))
	draw_set_transform(Vector2.ZERO)
	_draw_weather(size,biome)

func _draw_flower(p: Vector2,r: float,c: Color) -> void:
	for i in range(5):draw_circle(p+Vector2(cos(i*TAU/5),sin(i*TAU/5))*r,r*0.8,c)
	draw_circle(p,r*0.45,Color("#e7b844"))

func _sprite(index: int,p: Vector2,dimensions: Vector2,tint: Color=Color.WHITE,flip: bool=false) -> void:
	var texture := WolfAtlas.sprite(index)
	if texture==null:return
	var rect := Rect2(p-dimensions*0.5,dimensions)
	if flip:
		rect.position.x+=dimensions.x
		rect.size.x=-dimensions.x
	draw_texture_rect(texture,rect,false,tint)

func _shadow(p: Vector2,width: float) -> void:
	draw_set_transform(p,0,Vector2(1,0.42))
	draw_circle(Vector2.ZERO,width,Color(0.09,0.19,0.1,0.19))
	var size := get_viewport_rect().size
	draw_set_transform(Vector2(size.x*0.5,size.y*0.48)-game.state.pos*zoom,0,Vector2.ONE*zoom)

func _draw_object(obj: Dictionary,biome: String) -> void:
	var p: Vector2=obj.p
	var s: float=obj.scale
	var snow := biome=="snow"
	match obj.kind:
		"tree":
			_shadow(p+Vector2(9,8),52*s)
			_sprite(obj.variant,p+Vector2(0,-65*s),Vector2(165,225)*s,Color("#d3e5e5") if snow else Color.WHITE)
			if snow:
				for i in range(3):
					draw_line(p+Vector2(-30+i*8,-120+i*33)*s,p+Vector2(27-i*6,-111+i*30)*s,Color("#f0f8f5"),7*s)
		"rock":
			_shadow(p,37*s)
			_sprite(4,p+Vector2(0,-13),Vector2(102,95)*s,Color("#d4e5ec") if snow else Color.WHITE)
		"bush":_sprite(3,p+Vector2(0,-15),Vector2(88,74)*s)
		"flowers":_sprite(6,p,Vector2(70,63)*s,Color("#e3ebef") if snow else Color.WHITE)
		"den":
			_shadow(p,75)
			_sprite(7,p+Vector2(0,-35),Vector2(224,204))
		"water":
			if obj.variant==1:return
			var r := 190*s
			draw_circle(p,r+15,Color("#647f4b"))
			draw_circle(p,r,Color("#287d9e"))
			draw_circle(p-Vector2(12,18),r-16,Color("#42adc2"))
			for i in range(12):
				var q := p+Vector2(cos(i*2.4),sin(i*2.4))*(r-45)
				draw_arc(q,20,0.2,2.5,12,Color(0.78,0.99,1,0.5),2)
				draw_circle(q+Vector2(-7,8),7,Color("#73a941"))
				if i%3==0:_draw_flower(q+Vector2(-6,6),4,Color("#f2eddb"))
			for i in range(9):
				var q := p+Vector2(cos(i*0.7),sin(i*0.7))*(r+9)
				_sprite(4,q,Vector2(60,55))
		"food":
			if game.state.food_cooldown<=0:
				draw_circle(p,19,Color("#d6c398"))
				draw_circle(p+Vector2(-5,-1),12,Color("#b37b58"))
				draw_circle(p+Vector2(8,2),8,Color("#cd936d"))
		"bridge":
			for i in range(14):
				var x := -105+i*16
				draw_rect(Rect2(p+Vector2(x,-48),Vector2(14,96)),Color("#b88b4c") if i%2==0 else Color("#c79857"))
			for y in [-46,46]:
				draw_line(p+Vector2(-115,y),p+Vector2(115,y),Color("#694729"),7)
				for x in [-112,-40,40,112]:draw_circle(p+Vector2(x,y),7,Color("#d2a666"))
		"landmark":
			_sprite(4,p,Vector2(95,80))
			draw_arc(p+Vector2(0,-8),12,0,TAU,20,Color("#ddce8c"),2)
		"discovery":
			_sprite(6,p,Vector2(115,100))
			draw_arc(p,55+sin(game.clock*2)*4,0,TAU,40,Color(0.98,0.83,0.42,0.5),2)
			for i in range(4):draw_circle(p+Vector2(cos(game.clock+i*1.6),sin(game.clock+i*1.6))*45,3,Color("#fff2b2"))
		"ruin":
			for i in range(3):
				_sprite(4,p+Vector2(0,-i*30),Vector2(88,72),Color("#b4bc9a"))
		"waterfall":
			for side in [-1,1]:_sprite(4,p+Vector2(side*125,-30),Vector2(140,120))
			draw_rect(Rect2(p-Vector2(90,75),Vector2(180,150)),Color("#6ed0d5"))
			for i in range(7):
				var x := -70+i*23
				draw_line(p+Vector2(x,-65),p+Vector2(x+sin(game.clock*3+i)*5,60),Color(0.9,1,1,0.7),5)
				draw_circle(p+Vector2(x,70),12,Color(0.9,1,1,0.65))
		"house":
			draw_rect(Rect2(p-Vector2(80,90),Vector2(160,155)),Color("#dbcba2"))
			draw_colored_polygon(PackedVector2Array([p+Vector2(-100,-72),p+Vector2(0,-145),p+Vector2(100,-72),p+Vector2(90,-28),p+Vector2(-90,-28)]),Color("#a35632"))
			for x in [-45,35]:
				draw_rect(Rect2(p+Vector2(x,-12),Vector2(30,38)),Color("#42656c"))
				draw_line(p+Vector2(x+15,-12),p+Vector2(x+15,26),Color("#d1b47f"),3)
			draw_rect(Rect2(p+Vector2(-14,23),Vector2(30,44)),Color("#6d4e31"))

func _draw_track(p: Vector2,c: Color) -> void:
	for side in [-1,1]:
		var q := p+Vector2(side*10,side*5)
		draw_circle(q,4.5,c)
		for toe in [-1,0,1]:draw_circle(q+Vector2(toe*4,-8),2,c)
	if game.scent_time>0:
		draw_arc(p,21,0,TAU,24,Color(c,0.24),2)

func _draw_animal(p: Vector2,kind: String,facing: Vector2,player: bool,young: bool=false) -> void:
	_shadow(p+Vector2(0,18),29 if kind!="rabbit" else 17)
	var index := 12 if kind=="deer" else 13 if kind=="rabbit" else 14 if kind=="fox" else 8
	if kind=="wolf":
		index=10 if absf(facing.x)>absf(facing.y) and facing.x<0 else 11 if absf(facing.x)>absf(facing.y) else 8 if facing.y<0 else 9
	var bob := sin(game.clock*9)*1.5 if player and game.stick.vector.length()>0.1 else sin(game.clock*2)*0.7
	var dimensions := Vector2(104,112) if kind=="wolf" else Vector2(112,107) if kind=="deer" else Vector2(67,68) if kind=="rabbit" else Vector2(96,84)
	if index==8:dimensions.x=65
	if kind=="wolf" and not young:dimensions*=1.15
	_sprite(index,p+Vector2(0,-12+bob),dimensions,Color.WHITE,kind!="wolf" and facing.x>0)
	if player:
		draw_arc(p+Vector2(0,20),32,0,TAU,32,Color(0.99,0.84,0.41,0.58),2)

func _draw_weather(size: Vector2,biome: String) -> void:
	if biome=="snow":
		for i in range(45):
			var p := Vector2(fposmod(i*137.2+sin(game.clock+i)*14,size.x),fposmod(i*61.1+game.clock*24,size.y))
			draw_circle(p,1.5+float(i%2),Color(1,1,1,0.7))
	elif biome=="marsh":
		for i in range(6):
			var y := fposmod(i*220+game.clock*6,size.y)
			draw_line(Vector2(0,y),Vector2(size.x,y+30),Color(0.8,0.89,0.79,0.035),100)
