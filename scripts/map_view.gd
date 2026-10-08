class_name WolfMapView
extends Node2D

var game: Node
var zoom := 0.72
var bounds: Rect2
var ground_region := -1
var ground_patches: Array[Dictionary]=[]
var ground_season := ""
var ground_chunks: Array[Dictionary]=[]
var cached_paths: Array[PackedVector2Array]=[]
var path_mesh: ArrayMesh
var cached_tree_shadows := 0
const GROUND_CHUNK := 400.0

func seasonal_color(color: Color,foliage: bool=false) -> Color:
	var season: String=game.state.season_name()
	if season=="Herbst" and foliage:return color.lerp(Color("#d2b68a"),0.34)
	if season=="Winter":return color.lerp(Color("#d4e1dc"),0.38 if not foliage else 0.27)
	if season=="Sommer":return color.darkened(0.035)
	return color

func _ground_triangle(buffer: Dictionary,a: Vector2,b: Vector2,c: Vector2,colour: Color) -> void:
	for p in [a,b,c]:
		buffer.vertices.append(p)
		buffer.colors.append(colour)

func _ground_disc(buffer: Dictionary,p: Vector2,r: float,colour: Color,segments: int=12) -> void:
	for i in range(segments):
		var a := float(i)/segments*TAU
		var b := float(i+1)/segments*TAU
		_ground_triangle(buffer,p,p+Vector2(cos(a),sin(a))*r,p+Vector2(cos(b),sin(b))*r,colour)

func _ground_oval(buffer: Dictionary,p: Vector2,radii: Vector2,colour: Color,segments: int=20) -> void:
	for i in range(segments):
		var a := float(i)/segments*TAU
		var b := float(i+1)/segments*TAU
		_ground_triangle(buffer,p,p+Vector2(cos(a),sin(a))*radii,p+Vector2(cos(b),sin(b))*radii,colour)

func _ground_fern(buffer: Dictionary,p: Vector2,r: float,colour: Color) -> void:
	for frond in range(6):
		var angle := frond*TAU/6.0
		var direction := Vector2(cos(angle),sin(angle)*.65)
		var side := Vector2(-sin(angle),cos(angle)*.65)
		for leaf in range(3):
			var t := .20+float(leaf)*.22
			var root := p+direction*r*t
			var tip := p+direction*r*(t+.27)
			for sign_value in [-1,1]:
				_ground_triangle(buffer,root,root+side*r*(1-t)*.30*sign_value+direction*r*.07,tip,colour.lightened(float(frond%2)*.055))

func _ground_flower(buffer: Dictionary,p: Vector2,r: float,colour: Color) -> void:
	for i in range(5):_ground_disc(buffer,p+Vector2(cos(i*TAU/5),sin(i*TAU/5))*r,r*.8,colour,8)
	_ground_disc(buffer,p,r*.45,Color("#e7b844"),8)

func _ground_buffer(buffers: Dictionary,p: Vector2) -> Dictionary:
	var key := Vector2i(floori(p.x/GROUND_CHUNK),floori(p.y/GROUND_CHUNK))
	if not buffers.has(key):buffers[key]={"vertices":PackedVector2Array(),"colors":PackedColorArray()}
	return buffers[key]

func _bake_ground(ground: Color,biome: String) -> void:
	# Quiet flowers, pebbles and painted soil do not change every frame. Bake
	# their small triangles together; individual draw_circle calls are costly
	# on mobile even when their radius is only two pixels.
	ground_season=game.state.season_name()
	ground_chunks.clear()
	cached_tree_shadows=0
	cached_paths.clear()
	var paths := WolfWorldData.render_paths(game.state.region,game.world.objects)
	for branch in paths.branches:cached_paths.append(branch.points)
	path_mesh=WolfWildernessPaths.mesh_2d(paths,seasonal_color(paths.color))
	var buffers := {}
	for patch in ground_patches:
		var buffer := _ground_buffer(buffers,patch.p)
		var colour := ground.lightened(.08) if patch.light else ground.darkened(.08)
		for ring in range(3):_ground_disc(buffer,patch.p,patch.r*(1.0-float(ring)*.20),Color(colour,.075),32)
	# Tree shadows do not depend on the camera or the tiny crown sway. Bake
	# the original three shapes with the soil instead of issuing them for
	# every visible trunk on every mobile frame.
	for obj in game.world.objects:
		if obj.kind!="tree":continue
		var buffer := _ground_buffer(buffers,obj.p)
		_ground_disc(buffer,obj.p+Vector2(24,35),53*obj.scale,Color(.16,.26,.12,.045),20)
		_ground_disc(buffer,obj.p+Vector2(-12,55),33*obj.scale,Color(.16,.26,.12,.035),16)
		_ground_oval(buffer,obj.p+Vector2(9,8),Vector2(52,52*.42)*obj.scale,Color(.09,.19,.10,.19))
		cached_tree_shadows+=1
	var grass := seasonal_color(Color("#5b7b3f"),true) if biome!="snow" else Color("#b2cbd5")
	for d in game.world.decor:
		var buffer := _ground_buffer(buffers,d.p)
		var p: Vector2=d.p
		var r: float=d.size
		match d.variant:
			0,1:_ground_disc(buffer,p,r*2,Color(ground.darkened(.1),.30))
			2,3:
				if WolfWildernessPaths.contains(p,paths,7):continue
				if d.variant==3 and biome in ["forest","oak","ruins"]:
					_ground_fern(buffer,p,maxf(7,r*1.1),grass)
					continue
				_ground_triangle(buffer,p-Vector2(.7,0),p+Vector2(.7,0),p+Vector2(-3,-r),grass)
				_ground_triangle(buffer,p+Vector2(2.3,0),p+Vector2(3.7,0),p+Vector2(5,-r*1.3),grass.lightened(.16))
				_ground_flower(buffer,p+Vector2(-3,-r),2.2,Color("#f4d358"))
			4:_ground_flower(buffer,p,2.4,Color("#faf3d5"))
			5:_ground_flower(buffer,p,2,Color("#b9a1d8"))
			6:_ground_disc(buffer,p,2,Color("#6f7951"),8)
	for key in buffers:
		var buffer: Dictionary=buffers[key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=buffer.vertices
		arrays[Mesh.ARRAY_COLOR]=buffer.colors
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		ground_chunks.append({"bounds":Rect2(Vector2(key)*GROUND_CHUNK,Vector2.ONE*GROUND_CHUNK).grow(260),"mesh":mesh})

func _prepare_ground(ground: Color,biome: String) -> void:
	var changed: bool=ground_region!=game.state.region
	if changed:
		ground_region=game.state.region
		ground_patches.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed=WolfWorldData.REGIONS[game.state.region].seed+923
		for i in range(80):ground_patches.append({"p":Vector2(rng.randf_range(0,3200),rng.randf_range(0,3200)),"r":rng.randf_range(90,250),"light":i%2==0})
	if changed or ground_season!=game.state.season_name():_bake_ground(ground,biome)

func _ground_texture(ground: Color,biome: String) -> void:
	_prepare_ground(ground,biome)
	for chunk in ground_chunks:
		if bounds.intersects(chunk.bounds):draw_mesh(chunk.mesh,null)

func _draw() -> void:
	if game==null:return
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size),Color("#213c36"))
	var center := Vector2(size.x*0.5,size.y*0.48)
	bounds=Rect2(game.state.pos-size/(2*zoom),size/zoom).grow(220)
	draw_set_transform(center-game.state.pos*zoom,0,Vector2.ONE*zoom)
	var biome: String=WolfWorldData.REGIONS[game.state.region].biome
	var ground := seasonal_color(Color(WolfWorldData.REGIONS[game.state.region].ground).lerp(Color("#8d9872"),0.08))
	draw_rect(Rect2(Vector2.ZERO,WolfWorldData.SIZE),ground)
	_ground_texture(ground,biome)
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
	if biome=="coast":
		draw_rect(Rect2(0,1535,460,130),Color("#d2c38d"))
		draw_line(Vector2(0,1540),Vector2(450,1540),Color("#e4d6a1"),6)
	if path_mesh!=null:draw_mesh(path_mesh,null)
	# Ground objects first. Taller objects and animals are sorted by depth.
	var items: Array[Dictionary]=[]
	for obj in game.world.objects:
		if not bounds.has_point(obj.p):continue
		if obj.kind in ["water","flowers","bridge","food","discovery"]:_draw_object(obj,biome)
		else:items.append({"p":obj.p,"object":obj})
	for t in game.world.tracks:
		if bounds.has_point(t.p) and (game.scent_time>0 or game.state.found.has(t.id)):
			_draw_track(t.p,Color("#ffda77") if not game.state.found.has(t.id) else Color("#8a9b76"),t.species)
	for a in game.world.animals:
		if bounds.has_point(a.p):items.append({"p":a.p,"animal":a})
	items.append({"p":game.state.pos,"player":true})
	items.sort_custom(func(a:Dictionary,b:Dictionary):return a.p.y<b.p.y)
	for item in items:
		if item.has("object"):_draw_object(item.object,biome)
		elif item.has("animal"):
			var a: Dictionary=item.animal
			_draw_animal(a.p,a.kind,a.get("facing",Vector2.LEFT),false,a.get("young",false),a.get("gait",0.0),a.get("speed",0.0),a.get("mood","lauschen"),a.get("attention",0.0),str(a.get("phase",0.0)))
		else:_draw_animal(game.state.pos,"wolf",game.state.facing,true,true,game.player_gait,game.player_speed,game.player_mood)
	for foot in game.state.pawsteps:
		if bounds.has_point(foot.p):
			var alpha: float=clampf(1.0-(game.state.elapsed-foot.time)/20.0,0,1)*0.22
			_draw_track(foot.p,Color(0.22,0.29,0.18,alpha),"Wolf")
	if game.state.waypoint_region>=0:
		var target: Vector2=game.goal_position()
		var arrow: Vector2=game.state.pos.direction_to(target)
		var side := Vector2(-arrow.y,arrow.x)
		var marker: Vector2=game.state.pos+arrow*100
		draw_colored_polygon(PackedVector2Array([marker+arrow*18,marker-arrow*10+side*10,marker-arrow*10-side*10]),Color("#f3d79a"))
	if game.scent_time>0:
		draw_arc(game.state.pos,155+sin(game.clock*3)*15,0,TAU,64,Color(0.98,0.83,0.43,0.22),2)
		var wind := Vector2(0.65,-0.75)
		for i in range(8):
			var p: Vector2=game.state.pos+wind*fposmod(game.clock*28+i*30,240)-wind*120+Vector2(0,sin(i*3)*55)
			draw_line(p,p+wind*16,Color(0.94,0.85,0.55,0.25),2)
	for direction in WolfWorldData.REGIONS[game.state.region].links:
		var p := WolfWorldData.entry_point({"east":"west","west":"east","north":"south","south":"north"}[direction])
		if not bounds.has_point(p):continue
		draw_circle(p,25,Color("#dcc594"))
		draw_circle(p,21,Color("#294c38"))
		var d: Vector2={"north":Vector2.UP,"south":Vector2.DOWN,"east":Vector2.RIGHT,"west":Vector2.LEFT}[direction]
		var side := Vector2(-d.y,d.x)
		draw_colored_polygon(PackedVector2Array([p+d*12,p-d*8+side*8,p-d*8-side*8]),Color("#ffdc81"))
	var dusk: float=(1-game.state.sunlight())*0.45
	draw_rect(Rect2(Vector2.ZERO,WolfWorldData.SIZE),Color(0.06,0.10,0.25,dusk))
	draw_set_transform(Vector2.ZERO)
	# Weather is rendered in the shared atmosphere layer for both views.

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
	var viewport_size := get_viewport_rect().size
	var base: Vector2=Vector2(viewport_size.x*0.5,viewport_size.y*0.48)-game.state.pos*zoom
	draw_set_transform(base+p*zoom,0,Vector2(zoom,zoom*0.42))
	draw_circle(Vector2.ZERO,width,Color(0.09,0.19,0.1,0.19))
	var size := get_viewport_rect().size
	draw_set_transform(Vector2(size.x*0.5,size.y*0.48)-game.state.pos*zoom,0,Vector2.ONE*zoom)

func _draw_nature_site(p: Vector2,biome: String,variant: int) -> void:
	var style := WolfForestMesh.site_style(biome,variant)
	match style:
		"shells":
			for i in range(5):
				var q := p+Vector2(sin(i*2.4)*29,cos(i*2.4)*24)
				var fan := PackedVector2Array([q+Vector2(0,5)])
				for rib in range(9):fan.append(q+Vector2(cos(rib*PI/8)*10,-sin(rib*PI/8)*9))
				draw_colored_polygon(fan,Color("#e9dac0"))
				for rib in range(1,8):draw_line(q+Vector2(0,5),q+Vector2(cos(rib*PI/8)*9,-sin(rib*PI/8)*8),Color("#baa181"),.8)
		"driftwood","fallen_log","wet_log":
			draw_line(p+Vector2(-40,-3),p+Vector2(35,13),Color("#b8ac87") if style=="driftwood" else Color("#9f8254"),20,true)
			draw_circle(p+Vector2(35,13),10,Color("#d5c499") if style=="driftwood" else Color("#c1a171"))
			draw_arc(p+Vector2(35,13),6,0,TAU,16,Color("#a58b65"),1)
			if style!="driftwood":_sprite(3,p+Vector2(-15,8),Vector2(60,48))
		"reeds","dune_grass","frost_grass":
			var colour := Color("#aca06a") if style=="dune_grass" else Color("#b5ced0") if style=="frost_grass" else Color("#7c9354")
			for i in range(7):
				var q := p+Vector2(sin(i*2.4)*30,cos(i*2.4)*24)
				var tip := q+Vector2(sin(i*1.7)*9,-18-float(i%3)*5)
				draw_line(q,tip,colour,2,true)
				draw_line(q,tip+Vector2(8,5),colour.lightened(.12),1.4,true)
				if style=="reeds":draw_line(tip-Vector2(0,5),tip+Vector2(0,5),Color("#88714e"),4,true)
		"cairn","pebbles","snow_rocks":
			for i in range(4):
				var q := Vector2(0,-i*13) if style=="cairn" else Vector2(sin(i*2.4)*29,cos(i*2.4)*24)
				var s := 1.0-i*.14 if style=="cairn" else .50+float(i%3)*.10
				_sprite(4,p+q,Vector2(70,52)*s,Color("#e0ece8") if style=="snow_rocks" else Color("#c0cab8"))
		"pinecones":
			for i in range(7):
				var q := p+Vector2(sin(i*2.4)*29,cos(i*2.4)*24)
				draw_line(q-Vector2(0,4),q+Vector2(0,4),Color("#92704a"),7,true)
				for row in range(3):draw_line(q+Vector2(-2,-3+row*3),q+Vector2(2,-3+row*3),Color("#bea277"),1)
		"mushrooms":
			for i in range(5):
				var q := p+Vector2(sin(i*2.4)*23,cos(i*2.4)*20)
				draw_line(q,q+Vector2(0,-7),Color("#d5c79d"),3)
				var cap := PackedVector2Array([q+Vector2(-7,-5),q+Vector2(-5,-10),q+Vector2(0,-12),q+Vector2(5,-10),q+Vector2(7,-5)])
				draw_colored_polygon(cap,Color("#bc875a"))
				draw_line(q+Vector2(-6,-5),q+Vector2(6,-5),Color("#e1c596"),1)
			_sprite(3,p+Vector2(-25,10),Vector2(43,33))
		_:
			for i in range(4):_sprite(6,p+Vector2(sin(i*2.4)*25,cos(i*2.4)*22),Vector2(48,46)*(.7 if style=="alpine_flowers" else 1.0))

func _draw_object(obj: Dictionary,biome: String) -> void:
	var p: Vector2=obj.p
	var s: float=obj.scale
	var snow := biome=="snow"
	match obj.kind:
		"tree":
			var sway := 0.0 if game.state.reduced_motion else sin(game.clock*0.7+p.y*0.02)*1.8
			_sprite(obj.variant,p+Vector2(sway,-65*s),Vector2(165,225)*s,Color("#d3e5e5") if snow else seasonal_color(Color.WHITE,true))
			if snow:
				for i in range(3):
					draw_line(p+Vector2(-30+i*8,-120+i*33)*s,p+Vector2(27-i*6,-111+i*30)*s,Color("#f0f8f5"),7*s)
		"rock":
			_shadow(p,37*s)
			_sprite(4,p+Vector2(0,-13),Vector2(102,95)*s,Color("#d4e5ec") if snow else Color.WHITE)
		"bush":_sprite(3,p+Vector2(0,-15),Vector2(88,74)*s,seasonal_color(Color.WHITE,true))
		"flowers":_sprite(6,p,Vector2(70,63)*s,Color("#e3ebef") if snow else Color.WHITE)
		"den":
			if obj.get("variant",0)==1:
				_shadow(p+Vector2(0,7),34*s)
				draw_line(p+Vector2(-33,-5)*s,p+Vector2(32,9)*s,Color("#8b744e"),16*s,true)
				draw_circle(p+Vector2(32,9)*s,8*s,Color("#bc9968"))
				draw_arc(p+Vector2(32,9)*s,4*s,0,TAU,12,Color("#8b744e"),1)
				_sprite(3,p+Vector2(-16,4)*s,Vector2(53,38)*s)
				return
			_shadow(p,75)
			_sprite(7,p+Vector2(0,-35)*s,Vector2(224,204)*s)
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
			_draw_nature_site(p,biome,obj.variant)
			var found: bool=game.state.sites.has(obj.site)
			var pulse := 0.0 if game.state.reduced_motion else sin(game.clock*1.5)*2
			draw_arc(p,50+pulse,0,TAU,40,Color(0.65,0.76,0.49,0.32) if found else Color(0.94,0.83,0.55,0.45),1.5)
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

func _draw_track(p: Vector2,c: Color,species: String="Wolf") -> void:
	if species=="Reh":
		for side in [-1,1]:
			var q := p+Vector2(side*9,side*6)
			draw_line(q+Vector2(-2,-5),q+Vector2(-2,4),c,3)
			draw_line(q+Vector2(2,-5),q+Vector2(2,4),c,3)
		return
	if species=="Hase":
		for side in [-1,1]:
			draw_line(p+Vector2(side*7,-8),p+Vector2(side*7,2),c,4)
			draw_circle(p+Vector2(side*4,10+side*3),3,c)
		return
	for side in [-1,1]:
		var q := p+Vector2(side*10,side*5)
		draw_circle(q,4.5,c)
		for toe in [-1,0,1]:draw_circle(q+Vector2(toe*4,-8),2,c)
	if game.scent_time>0:
		draw_arc(p,21,0,TAU,24,Color(c,0.24),2)

static func animal_pose(kind: String,facing: Vector2,gait: float,speed: float,mood: String,reduced: bool=false,attention: float=0.0,time: float=0.0) -> Dictionary:
	var cycle := gait*(22.0*.032*TAU)/(.90 if kind=="deer" else .53 if kind=="fox" else .42 if kind=="rabbit" else .65)
	var resting := speed<1 and mood=="ruhen"
	var feeding := speed<1 and mood in ["grasen","schnüffeln","trinken"]
	var lift := sin(clampf((fposmod(cycle/TAU,1.0)-.28)/.30,0,1)*PI)*5 if kind=="rabbit" and speed>1 else sin(cycle*2)*1.1 if speed>1 else 0.0
	if reduced:lift=0.0
	var motion := .25 if reduced else 1.0
	var breath := sin(time*1.65)*.006*motion if speed<1 else 0.0
	var head_angle := -.38 if feeding else .12 if attention>.35 else -.06 if mood=="begrüßen" else 0.0
	if speed<1:head_angle+=(sin(time*2.15)*.022+sin(time*1.07)*.008 if feeding else sin(time*.73)*.025)*motion
	return {"scale":Vector2(1.04,.74) if resting else Vector2(1.03,.94) if mood=="fliehen" else Vector2.ONE,"breath_scale":Vector2(1+breath,1-breath),"lift":lift,"head_angle":head_angle,"head_drop":4.0 if feeding else 0.0,"tilt":clampf(facing.y,-1,1)*(-.10 if facing.x>0 else .10),"frame":posmod(int(cycle*2/PI),4) if speed>1 else 1 if kind=="wolf" else 0}

static func blend_animal_pose(previous: Dictionary,current: Dictionary,dt: float) -> Dictionary:
	# Distance-derived atlas frames keep their timing; only posture eases.
	var pose := current.duplicate()
	var weight := 1.0-exp(-clampf(dt,0,.1)*10.0)
	for key in ["scale","breath_scale"]:pose[key]=previous[key].lerp(current[key],weight)
	for key in ["head_drop","lift"]:pose[key]=lerpf(previous[key],current[key],weight)
	for key in ["head_angle","tilt"]:pose[key]=lerp_angle(previous[key],current[key],weight)
	return pose

func _draw_animal(p: Vector2,kind: String,facing: Vector2,player: bool,young: bool=false,gait: float=0,speed: float=0,mood: String="lauschen",attention: float=0.0,animation_key: String="player") -> void:
	gait=WolfAnimalModel.renderer_gait(gait,player)
	_shadow(p+Vector2(0,18),29 if kind!="rabbit" else 17)
	var index := 12 if kind=="deer" else 13 if kind=="rabbit" else 14 if kind=="fox" else 8
	if kind=="wolf":
		index=10 if absf(facing.x)>absf(facing.y) and facing.x<0 else 11 if absf(facing.x)>absf(facing.y) else 8 if facing.y<0 else 9
	var pose_time: float=game.clock+float(posmod(hash(animation_key),1000))*.006
	var pose := animal_pose(kind,facing,gait,speed,mood,game.state.reduced_motion,attention,pose_time)
	# Individual keys survive depth sorting. Keep only a bounded regional
	# cache so a passing animal cannot inherit another animal's resting pose.
	var memory: Dictionary=get_meta("animated_poses",{})
	if memory.get("region",-1)!=game.state.region:memory={"region":game.state.region,"animals":{}}
	var key := "player" if player else kind+":"+animation_key
	if memory.animals.has(key):
		var previous: Dictionary=memory.animals[key]
		if game.clock>=previous.time:pose=blend_animal_pose(previous.pose,pose,game.clock-previous.time)
	if memory.animals.size()>=24 and not memory.animals.has(key):memory.animals.clear()
	memory.animals[key]={"time":game.clock,"pose":pose}
	set_meta("animated_poses",memory)
	var bob: float=-pose.lift
	var dimensions := Vector2(104,112) if kind=="wolf" else Vector2(112,107) if kind=="deer" else Vector2(67,68) if kind=="rabbit" else Vector2(96,84)
	if index==8:dimensions.x=65
	if kind=="wolf" and not young:dimensions*=1.30
	if player:dimensions*=game.state.growth()/0.72
	if kind=="wolf":
		var texture := WolfAtlas.walking(facing,pose.frame)
		var special := -1
		if speed<1:
			special=0 if mood in ["schnüffeln","trinken"] else 1 if mood=="heulen" else 2 if mood=="ruhen" else 3 if mood in ["spielen","begrüßen"] else -1
		if special>=0:texture=WolfAtlas.wildlife(3,special)
		var walk_size := Vector2(124,124)*(1.25 if not young else 1.0)
		if special<0 and absf(facing.y)>absf(facing.x):walk_size=Vector2(108,133)*(1.25 if not young else 1.0)
		if player:walk_size*=game.state.growth()/0.72
		walk_size*=pose.breath_scale
		var rect := Rect2(p+Vector2(0,-14+bob)-walk_size*0.5,walk_size)
		if special>=0 and facing.x>0:rect.position.x+=rect.size.x;rect.size.x=-rect.size.x
		draw_texture_rect(texture,rect,false)
	else:
		var row := 0 if kind=="deer" else 1 if kind=="rabbit" else 2
		var texture := WolfAtlas.wildlife(row,pose.frame)
		dimensions*=pose.scale*pose.breath_scale
		if absf(facing.y)>absf(facing.x):dimensions.x*=.87
		var camera_base: Vector2=get_viewport_rect().size*Vector2(.5,.48)-game.state.pos*zoom
		var anchor := p+Vector2(0,-12+bob+(10.0 if mood=="ruhen" else 0.0))
		var transform := Transform2D(pose.tilt,camera_base+anchor*zoom).scaled_local(Vector2(-zoom if facing.x>0 else zoom,zoom))
		draw_set_transform_matrix(transform)
		var full := Rect2(-dimensions*.5,dimensions)
		var source := Rect2(Vector2.ZERO,texture.get_size())
		# Repose the existing illustrated head separately from the body; retain
		# the original fur and clear outline instead of rotating an entire deer.
		var cut_x := .46
		var cut_y := .64
		draw_texture_rect_region(texture,Rect2(full.position+Vector2(dimensions.x*cut_x,0),Vector2(dimensions.x*(1-cut_x),dimensions.y*cut_y)),Rect2(Vector2(source.size.x*cut_x,0),Vector2(source.size.x*(1-cut_x),source.size.y*cut_y)))
		draw_texture_rect_region(texture,Rect2(full.position+Vector2(0,dimensions.y*cut_y),Vector2(dimensions.x,dimensions.y*(1-cut_y))),Rect2(Vector2(0,source.size.y*cut_y),Vector2(source.size.x,source.size.y*(1-cut_y))))
		var pivot := Vector2(-dimensions.x*.10,-dimensions.y*.10)
		draw_set_transform_matrix(transform*Transform2D(pose.head_angle,pivot+Vector2(0,pose.head_drop)))
		draw_texture_rect_region(texture,Rect2(full.position-pivot,Vector2(dimensions.x*cut_x,dimensions.y*cut_y)),Rect2(Vector2.ZERO,Vector2(source.size.x*cut_x,source.size.y*cut_y)))
		draw_set_transform(camera_base,0,Vector2.ONE*zoom)

	if player:
		draw_arc(p+Vector2(0,20),32,0,TAU,32,Color(0.99,0.84,0.41,0.58),2)

func _draw_weather(size: Vector2,biome: String) -> void:
	if not game.state.weather_enabled:return
	if biome=="snow":
		for i in range(45):
			var p := Vector2(fposmod(i*137.2+sin(game.clock+i)*14,size.x),fposmod(i*61.1+game.clock*24,size.y))
			draw_circle(p,1.5+float(i%2),Color(1,1,1,0.7))
	elif biome=="marsh":
		for i in range(6):
			var y := fposmod(i*220+game.clock*6,size.y)
			draw_line(Vector2(0,y),Vector2(size.x,y+30),Color(0.8,0.89,0.79,0.035),100)
