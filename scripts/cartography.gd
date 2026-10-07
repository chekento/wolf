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
		pan=(Vector2(1600,1600)-game.state.pos)*local_scale()
	else:
		var coord: Vector2i=WolfWorldData.REGIONS[game.state.region].coord
		pan=(Vector2(4,4)-Vector2(coord)-Vector2(0.5,0.5))*cell_size()
	queue_redraw()

func cell_size() -> float:
	return minf(size.x,size.y)/8.0*magnification

func local_scale() -> float:
	return minf(size.x,size.y)/3200.0*magnification

func zoom_by(factor: float) -> void:
	var old := magnification
	magnification=clampf(magnification*factor,1,4)
	pan*=magnification/old
	queue_redraw()

func set_local(region: int) -> void:
	local_region=region
	magnification=1
	pan=Vector2.ZERO
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom_by(1.2)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom_by(1.0/1.2)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			mouse_down=event.pressed
			if event.pressed:press_pos=event.position;previous=event.position;dragged=false
			elif not dragged:_select(event.position)
		accept_event()
	elif event is InputEventMouseMotion and mouse_down:
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
		accept_event()
	elif event is InputEventScreenDrag:
		touches[event.index]=event.position
		if touches.size()==2:
			var length: float=touches.values()[0].distance_to(touches.values()[1])
			if pinch_length>10:zoom_by(length/pinch_length)
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
		var c := (p-size*0.5-pan)/cell_size()+Vector2(4,4)
		var index := WolfWorldData.index_at(Vector2i(floori(c.x),floori(c.y)))
		if index>=0:selected=index;region_selected.emit(index);queue_redraw()

func _draw() -> void:
	if game==null:return
	draw_style_box(game.panel_style(Color("#d5c9a6"),14),Rect2(Vector2.ZERO,size))
	if local_region>=0:_local()
	else:_world()
	draw_string(ThemeDB.fallback_font,Vector2(size.x-32,26),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#243e34"))
	draw_line(Vector2(size.x-27,34),Vector2(size.x-27,48),Color("#243e34"),2)
	draw_string(ThemeDB.fallback_font,Vector2(12,size.y-12),"Ziehen · Aufziehen · Tippen",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#253e36"))

func _world() -> void:
	var cell := cell_size()
	var origin := size*0.5+pan-Vector2(4,4)*cell
	for index in range(WolfWorldData.REGIONS.size()):
		var region: Dictionary=WolfWorldData.REGIONS[index]
		var p: Vector2=origin+Vector2(region.coord)*cell
		var rect := Rect2(p,Vector2.ONE*cell)
		if not rect.intersects(Rect2(Vector2.ZERO,size)):continue
		var known: bool=game.state.visited.has(index) or game.state.map_reveal
		var c := Color(region.ground)
		draw_rect(rect,c.lerp(Color("#9d9e82"),0.7) if not known else c)
		var random := RandomNumberGenerator.new()
		random.seed=region.seed
		for i in range(9):
			var q := p+Vector2(random.randf_range(0.1,0.9),random.randf_range(0.1,0.9))*cell
			if region.biome in ["snow","alpine"]:
				draw_colored_polygon(PackedVector2Array([q+Vector2(-cell*0.14,cell*0.06),q+Vector2(0,-cell*0.15),q+Vector2(cell*0.14,cell*0.06)]),c.darkened(0.22))
			else:draw_circle(q,cell*0.065,c.darkened(0.14))
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
		if not known:draw_circle(middle,cell*0.35,Color(0.7,0.7,0.59,0.45))
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
		if points.size()>1:draw_polyline(points,Color(0.64,0.24,0.18,0.72),2,true)

func _local() -> void:
	var scale_value := local_scale()
	var origin := size*0.5+pan-Vector2(1600,1600)*scale_value
	var region: Dictionary=WolfWorldData.REGIONS[local_region]
	var color := Color(region.ground)
	var rect := Rect2(origin,WolfWorldData.SIZE*scale_value)
	draw_rect(rect,color)
	if not game.state.visited.has(local_region):
		draw_rect(rect,Color(0.60,0.63,0.53,0.80))
		draw_string(ThemeDB.fallback_font,Vector2(40,size.y*0.5),"Dieser Ort ist noch unerforscht.",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#334b3d"))
		return
	var data: Dictionary=game.world if local_region==game.state.region else WolfWorldData.generate(local_region)
	for vertical in [true,false]:
		var path := WolfWorldData.path_points(local_region,vertical)
		for i in range(path.size()-1):draw_line(origin+path[i]*scale_value,origin+path[i+1]*scale_value,Color("#ded1a3"),maxf(2,90*scale_value))
	if region.biome=="river":
		var river := PackedVector2Array()
		for y in range(0,3201,50):river.append(origin+Vector2(WolfWorldData.river_x(y),y)*scale_value)
		draw_polyline(river,Color("#53adbb"),155*scale_value,true)
	if region.biome=="coast":
		draw_rect(Rect2(origin,Vector2(425,3200)*scale_value),Color("#5dabb7"))
		draw_rect(Rect2(origin+Vector2(0,1535)*scale_value,Vector2(460,130)*scale_value),Color("#d2c38d"))
	for obj in data.objects:
		var q: Vector2=origin+obj.p*scale_value
		if not Rect2(Vector2.ZERO,size).grow(15).has_point(q):continue
		match obj.kind:
			"tree":draw_circle(q,maxf(1,36*scale_value),color.darkened(0.24))
			"rock":draw_circle(q,maxf(1,23*scale_value),Color("#9eaa98"))
			"water":
				if obj.variant==0:draw_circle(q,190*obj.scale*scale_value,Color("#52abb8"))
			"den":_paw(q,5,Color("#584a32"))
			"discovery":
				draw_arc(q,5,0,TAU,16,Color("#f7e098"),2)
				if magnification>1.3:draw_string(ThemeDB.fallback_font,q+Vector2(8,4),obj.title,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#233e31"))
			"landmark":draw_circle(q,4,Color("#d6c185"))
			"bridge":draw_line(q-Vector2(12,0),q+Vector2(12,0),Color("#805b35"),5)
			"house":draw_rect(Rect2(q-Vector2(5,5),Vector2(10,10)),Color("#835738"))
	if local_region==game.state.region:
		for a in data.animals:
			if a.kind=="wolf":_paw(origin+a.p*scale_value,3,Color("#e7dfc4"))
		_paw(origin+game.state.pos*scale_value,6,Color("#fff0b3"))
	if game.state.waypoint_region==local_region:draw_arc(origin+game.state.waypoint_pos*scale_value,8,0,TAU,24,Color("#a54638"),3)

func _paw(p: Vector2,r: float,color: Color) -> void:
	draw_circle(p+Vector2(0,r*0.3),r*0.65,color)
	for i in range(3):draw_circle(p+Vector2((i-1)*r*0.65,-r*0.55),r*0.30,color)
