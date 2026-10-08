class_name WolfCartography
extends Control

signal region_selected(index: int)
signal place_selected(region: int,point: Vector2)
var game: Node
var local_region := -1
var selected := -1
var magnification := 1.0
var pan := Vector2.ZERO
var pointer := -1
var press_pos := Vector2.ZERO
var previous := Vector2.ZERO
var dragged := false
var mouse_down := false
var touches: Dictionary = {}
var pinch_length := 0.0
var region_data: Dictionary = {}
var loaded_region := -1
var path_mesh: ArrayMesh
var layers := {"sites":true,"tracks":false,"route":true}

func _ready() -> void:
	custom_minimum_size=Vector2(0,380)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	center_on_player()

func center_on_player() -> void:
	if game==null:return
	if local_region>=0:
		if local_region!=game.state.region:set_local(game.state.region)
		pan=(Vector2(1600,1600)-game.state.pos)*local_scale()
	else:
		var coord: Vector2i=WolfWorldData.REGIONS[game.state.region].coord
		pan=(Vector2.ONE*WolfWorldData.GRID_SIZE*0.5-Vector2(coord)-Vector2(0.5,0.5))*cell_size()
	queue_redraw()

func cell_size() -> float:
	return minf(size.x,size.y)/float(WolfWorldData.GRID_SIZE)*magnification

func local_scale() -> float:
	return minf(size.x,size.y)/3200.0*magnification

func zoom_by(factor: float) -> void:
	zoom_at(factor,size*0.5)

func zoom_at(factor: float,anchor: Vector2) -> void:
	var old := magnification
	magnification=clampf(magnification*factor,1,4)
	var ratio := magnification/old
	pan=(anchor-size*0.5)-(anchor-size*0.5-pan)*ratio
	queue_redraw()

func toggle_layer(layer: String) -> void:
	if layers.has(layer):layers[layer]=not layers[layer];queue_redraw()

func set_local(region: int) -> void:
	local_region=region
	loaded_region=-1
	region_data={}
	magnification=1
	pan=Vector2.ZERO
	pointer=-1;mouse_down=false;touches.clear();pinch_length=0
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.device==InputEvent.DEVICE_ID_EMULATION:return
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom_at(1.2,event.position)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom_at(1.0/1.2,event.position)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			mouse_down=event.pressed
			if event.pressed:press_pos=event.position;previous=event.position;dragged=false
			elif not dragged:_select(event.position)
		accept_event()
	elif event is InputEventMouseMotion and mouse_down:
		if event.device==InputEvent.DEVICE_ID_EMULATION:return
		if event.position.distance_to(press_pos)>7:dragged=true
		if dragged:pan+=event.position-previous;queue_redraw()
		previous=event.position
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index]=event.position
			if pointer==-1:pointer=event.index;press_pos=event.position;previous=event.position;dragged=false
			if touches.size()==2:pinch_length=touches.values()[0].distance_to(touches.values()[1]);dragged=true
		else:
			if pointer==event.index:
				if not dragged:_select(event.position)
				pointer=-1
			touches.erase(event.index)
			pinch_length=0
			if pointer==-1 and not touches.is_empty():
				pointer=int(touches.keys()[0]);previous=touches[pointer];press_pos=previous;dragged=true
		accept_event()
	elif event is InputEventScreenDrag:
		touches[event.index]=event.position
		if touches.size()==2:
			var length: float=touches.values()[0].distance_to(touches.values()[1])
			if pinch_length>10:zoom_at(length/pinch_length,(touches.values()[0]+touches.values()[1])*0.5)
			pinch_length=length
		elif pointer==event.index:
			if event.position.distance_to(press_pos)>7:dragged=true
			if dragged:pan+=event.position-previous;queue_redraw()
			previous=event.position
		accept_event()
	elif event is InputEventMagnifyGesture:zoom_by(event.factor);accept_event()

func _select(p: Vector2) -> void:
	if local_region>=0:
		if not game.state.visited.has(local_region):return
		var point := (p-size*0.5-pan)/local_scale()+Vector2(1600,1600)
		if Rect2(Vector2.ZERO,WolfWorldData.SIZE).has_point(point):place_selected.emit(local_region,point)
	else:
		var c := (p-size*0.5-pan)/cell_size()+Vector2.ONE*WolfWorldData.GRID_SIZE*0.5
		var index := WolfWorldData.index_at(Vector2i(floori(c.x),floori(c.y)))
		if index>=0:selected=index;region_selected.emit(index);queue_redraw()

func _draw() -> void:
	if game==null:return
	draw_style_box(game.panel_style(Color("#d5c9a6"),14),Rect2(Vector2.ZERO,size))
	if local_region>=0:_local()
	else:_world()
	_compass(Vector2(size.x-30,36))
	draw_rect(Rect2(8,size.y-30,195,21),Color(0.89,0.85,0.69,0.88))
	draw_string(ThemeDB.fallback_font,Vector2(12,size.y-12),"Ziehen · Aufziehen · Tippen",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#253e36"))
	draw_rect(Rect2(3,3,size.x-6,size.y-6),Color("#657857"),false,1.5)
	_scale_bar()

func _compass(p: Vector2) -> void:
	var ink := Color("#2d4c3d")
	draw_circle(p,22,Color(0.88,0.86,0.68,0.9))
	draw_arc(p,20,0,TAU,32,ink,1,true)
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-15),p+Vector2(-5,5),p+Vector2(0,1)]),ink)
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,15),p+Vector2(5,-5),p+Vector2(0,-1)]),ink.lightened(0.4))
	draw_string(ThemeDB.fallback_font,p+Vector2(-5,-23),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)

func _scale_bar() -> void:
	var ink := Color("#365140")
	var length := 800*local_scale() if local_region>=0 else cell_size()*2
	if length>size.x*0.38:length*=0.5
	var p := Vector2(size.x-15-length,size.y-18)
	draw_rect(Rect2(p-Vector2(6,16),Vector2(length+12,24)),Color(0.89,0.85,0.69,0.86))
	draw_line(p,p+Vector2(length,0),ink,2)
	for x in [0.0,length]:draw_line(p+Vector2(x,-4),p+Vector2(x,3),ink,1)
	var text := "%d Schritte"%int(length/local_scale()/25) if local_region>=0 else "%d Gebiete"%roundi(length/cell_size())
	draw_string(ThemeDB.fallback_font,p+Vector2(0,-6),text,HORIZONTAL_ALIGNMENT_CENTER,length,10,ink)

func _world() -> void:
	var cell := cell_size()
	var origin := size*0.5+pan-Vector2.ONE*WolfWorldData.GRID_SIZE*0.5*cell
	for index in range(WolfWorldData.REGIONS.size()):
		var region: Dictionary=WolfWorldData.REGIONS[index]
		var p: Vector2=origin+Vector2(region.coord)*cell
		var rect := Rect2(p,Vector2.ONE*cell)
		if not rect.intersects(Rect2(Vector2.ZERO,size)):continue
		var known: bool=game.state.visited.has(index) or game.state.map_reveal
		var c := Color(region.ground)
		var paper := c.lerp(Color("#ded5ae"),0.30)
		draw_rect(rect,paper.lerp(Color("#aaa98d"),0.60) if not known else paper)
		var random := RandomNumberGenerator.new()
		random.seed=region.seed
		for i in range(9):
			var q := p+Vector2(random.randf_range(0.1,0.9),random.randf_range(0.1,0.9))*cell
			if region.biome in ["snow","alpine"]:
				draw_colored_polygon(PackedVector2Array([q+Vector2(-cell*0.14,cell*0.06),q+Vector2(0,-cell*0.15),q+Vector2(cell*0.14,cell*0.06)]),c.darkened(0.22))
			else:
				var tree := PackedVector2Array([q-Vector2(0,cell*0.08),q+Vector2(-cell*0.055,cell*0.05),q+Vector2(cell*0.055,cell*0.05)])
				draw_colored_polygon(tree,c.darkened(0.19).lerp(Color("#63816a"),0.20))
				draw_line(q+Vector2(0,cell*0.04),q+Vector2(0,cell*0.09),c.darkened(0.27),1)
		if region.biome=="river":draw_line(p+Vector2(cell*0.30,0),p+Vector2(cell*0.32,cell),Color("#64adb4"),cell*0.11)
		if region.biome=="coast":draw_rect(Rect2(p,Vector2(cell*0.22,cell)),Color("#72a6b1"))
		if region.biome=="lake":draw_circle(p+Vector2(cell*0.67,cell*0.63),cell*0.15,Color("#64adb4"))
		var middle := p+Vector2.ONE*cell*0.5
		for direction in region.links:
			var d: Vector2={"north":Vector2.UP,"south":Vector2.DOWN,"west":Vector2.LEFT,"east":Vector2.RIGHT}[direction]
			draw_line(middle,middle+d*cell*0.5,Color("#dcce9d"),maxf(1,cell*0.025))
		draw_rect(rect,Color(0.18,0.28,0.23,0.30),false,1)
		if selected==index:draw_rect(rect.grow(-2),Color("#ffe8a0"),false,3)
		if index==0:_paw(middle,cell*0.075,Color("#4c4937"))
		if game.state.marked.has(index):draw_arc(middle,cell*0.14,0,TAU,20,Color("#f0d990"),1.5)
		if not known:
			for cloud in range(3):draw_circle(middle+Vector2((cloud-1)*cell*0.2,sin(index+cloud)*cell*0.12),cell*0.24,Color(0.72,0.73,0.64,0.32))
		if cell>72:
			var name: String=region.name if known else "Unerkundet"
			var font := ThemeDB.fallback_font
			draw_string(font,p+Vector2(5,cell-10),name,HORIZONTAL_ALIGNMENT_CENTER,cell-10,11,Color("#253e34"))
	var player: Vector2=origin+(Vector2(WolfWorldData.REGIONS[game.state.region].coord)+game.state.pos/3200)*cell
	_paw(player,6,Color("#fff1b8"))
	if game.state.waypoint_region>=0:
		var goal: Vector2=origin+(Vector2(WolfWorldData.REGIONS[game.state.waypoint_region].coord)+game.state.waypoint_pos/3200)*cell
		draw_arc(goal,7,0,TAU,24,Color("#a34436"),2)
		var route: Array[int]=game.route_to(game.state.waypoint_region)
		var points := PackedVector2Array([player])
		for id in route:points.append(origin+(Vector2(WolfWorldData.REGIONS[id].coord)+Vector2(0.5,0.5))*cell)
		points.append(goal)
		if layers.route and points.size()>1:draw_polyline(points,Color(0.64,0.24,0.18,0.72),2,true)

func _local() -> void:
	var scale_value := local_scale()
	var origin := size*0.5+pan-Vector2(1600,1600)*scale_value
	var region: Dictionary=WolfWorldData.REGIONS[local_region]
	var color := Color(region.ground)
	var rect := Rect2(origin,WolfWorldData.SIZE*scale_value)
	draw_rect(rect,color.lerp(Color("#d9d0a7"),0.25))
	if not game.state.visited.has(local_region):
		draw_rect(rect,Color(0.60,0.63,0.53,0.80))
		draw_string(ThemeDB.fallback_font,Vector2(40,size.y*0.5),"Dieser Ort ist noch unerforscht.",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#334b3d"))
		return
	if loaded_region!=local_region:
		region_data=game.world if local_region==game.state.region else WolfWorldData.generate(local_region)
		var paths := WolfWorldData.render_paths(local_region,region_data.objects)
		path_mesh=WolfWildernessPaths.mesh_2d(paths,paths.color)
		loaded_region=local_region
	var data: Dictionary=region_data
	for x in range(0,3201,400):
		draw_line(origin+Vector2(x,0)*scale_value,origin+Vector2(x,3200)*scale_value,Color(0.22,0.35,0.22,0.08),1)
	for y in range(0,3201,400):
		draw_line(origin+Vector2(0,y)*scale_value,origin+Vector2(3200,y)*scale_value,Color(0.22,0.35,0.22,0.08),1)
	if region.biome in ["alpine","snow","meadow","forest"]:
		for contour in range(6):
			var ring := PackedVector2Array()
			for angle in range(49):
				var t := TAU*angle/48.0
				var radius := (140+contour*65)*(1.0+0.14*sin(t*3+local_region))
				ring.append(origin+(Vector2(760,900)+Vector2(cos(t)*1.2,sin(t))*radius)*scale_value)
			draw_polyline(ring,Color(0.2,0.32,0.19,0.18),1,true)
	if region.biome=="river":
		var river := PackedVector2Array()
		for y in range(0,3201,50):river.append(origin+Vector2(WolfWorldData.river_x(y),y)*scale_value)
		draw_polyline(river,Color("#53adbb"),155*scale_value,true)
	if region.biome=="coast":
		draw_rect(Rect2(origin,Vector2(425,3200)*scale_value),Color("#5dabb7"))
		draw_rect(Rect2(origin+Vector2(0,1535)*scale_value,Vector2(460,130)*scale_value),Color("#d2c38d"))
	if path_mesh!=null:draw_mesh(path_mesh,null,Transform2D(0,Vector2.ONE*scale_value,0,origin))
	for obj in data.objects:
		var q: Vector2=origin+obj.p*scale_value
		if not Rect2(Vector2.ZERO,size).grow(15).has_point(q):continue
		match obj.kind:
			"tree":
				var r := maxf(1.5,38*scale_value)
				if obj.variant==0:draw_colored_polygon(PackedVector2Array([q-Vector2(0,r),q+Vector2(-r*0.7,r*0.5),q+Vector2(r*0.7,r*0.5)]),color.darkened(0.27))
				else:draw_circle(q,r,color.darkened(0.23));draw_circle(q+Vector2(r*0.4,-r*0.35),r*0.7,color.darkened(0.18))
			"rock":
				var r := maxf(1.5,23*scale_value)
				draw_colored_polygon(PackedVector2Array([q+Vector2(-r,r*0.5),q+Vector2(-r*0.3,-r),q+Vector2(r*0.8,-r*0.3),q+Vector2(r,r*0.6)]),Color("#9eaa98"))
			"water":
				if obj.variant==0:draw_circle(q,190*obj.scale*scale_value,Color("#52abb8"))
			"den":_paw(q,5,Color("#584a32"))
			"discovery":
				if not layers.sites:continue
				draw_circle(q,6,Color("#405f40"))
				draw_arc(q,5,0,TAU,16,Color("#f7e098"),2)
				if game.state.sites.has(obj.site):draw_circle(q,2,Color("#eae0b6"))
				if magnification>1.3:
					var text_width := ThemeDB.fallback_font.get_string_size(obj.title,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
					draw_rect(Rect2(q+Vector2(6,-10),Vector2(text_width+8,17)),Color(0.88,0.85,0.7,0.9))
					draw_string(ThemeDB.fallback_font,q+Vector2(10,3),obj.title,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#233e31"))
			"landmark":draw_circle(q,4,Color("#d6c185"))
			"bridge":draw_line(q-Vector2(12,0),q+Vector2(12,0),Color("#805b35"),5)
			"house":draw_rect(Rect2(q-Vector2(5,5),Vector2(10,10)),Color("#835738"))
	if layers.tracks:
		for track in data.tracks:
			if not game.state.found.has(track.id):continue
			var q: Vector2=origin+track.p*scale_value
			_paw(q,2.5,Color("#8b6d42"))
	if layers.route and local_region==game.state.region and game.state.waypoint_region>=0:
		var route: PackedVector2Array=game.navigation_route()
		var projected := PackedVector2Array()
		for point in route:projected.append(origin+point*scale_value)
		if projected.size()>1:
			draw_polyline(projected,Color("#efdfb0"),5,true)
			draw_polyline(projected,Color("#a4503f"),2,true)
			for i in range(0,projected.size(),8):draw_circle(projected[i],2.2,Color("#a4503f"))
	_draw_exits(origin,scale_value)
	if local_region==game.state.region:
		for a in data.animals:
			if a.kind=="wolf":_paw(origin+a.p*scale_value,3,Color("#e7dfc4"))
		_paw(origin+game.state.pos*scale_value,6,Color("#fff0b3"))
	if game.state.waypoint_region==local_region:draw_arc(origin+game.state.waypoint_pos*scale_value,8,0,TAU,24,Color("#a54638"),3)

func _draw_exits(origin: Vector2,scale_value: float) -> void:
	var links: Dictionary=WolfWorldData.REGIONS[local_region].links
	for direction in links:
		var target: int=links[direction]
		var point: Vector2={"north":Vector2(1600,70),"south":Vector2(1600,3130),"west":Vector2(70,1600),"east":Vector2(3130,1600)}[direction]
		var q := origin+point*scale_value
		if not Rect2(Vector2.ZERO,size).grow(12).has_point(q):continue
		var outward: Vector2={"north":Vector2.UP,"south":Vector2.DOWN,"west":Vector2.LEFT,"east":Vector2.RIGHT}[direction]
		var side := Vector2(-outward.y,outward.x)
		draw_circle(q,11,Color("#eee0b2"))
		draw_colored_polygon(PackedVector2Array([q+outward*7,q-outward*4+side*5,q-outward*4-side*5]),Color("#576b4a"))
		if magnification<1.3:continue
		var known: bool=game.state.visited.has(target) or game.state.map_reveal
		var caption: String=WolfWorldData.REGIONS[target].name if known else "Neue Wildnis"
		var font := ThemeDB.fallback_font
		var text_width := minf(font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x,size.x-24)
		var baseline := (q-outward*23+Vector2(-text_width*0.5,4)).clamp(Vector2(8,18),size-Vector2(text_width+8,40))
		draw_rect(Rect2(baseline-Vector2(3,13),Vector2(text_width+6,18)),Color(0.91,0.88,0.73,0.94))
		draw_string(font,baseline,caption,HORIZONTAL_ALIGNMENT_LEFT,text_width,11,Color("#36503e"))

func _paw(p: Vector2,r: float,color: Color) -> void:
	draw_circle(p+Vector2(0,r*0.3),r*0.65,color)
	for i in range(3):draw_circle(p+Vector2((i-1)*r*0.65,-r*0.55),r*0.30,color)
