class_name WolfWildernessPaths
extends RefCounted

# Visual wild-animal trails are independent of the old generator reservations.
# No random-number stream, collision rule or saved place changes.
const MAX_CACHED := 16
const SECTION_SPACING := 42.0
const MOUTH_DISTANCE := 62.0
const BANDS := [-1.0,-0.62,0.0,0.62,1.0]
const BAND_WEIGHT := [0.0,0.55,0.86,0.55,0.0]
static var cache: Dictionary = {}
static var recent: Array[int] = []

static func for_region(region: int,objects: Array=[]) -> Dictionary:
	if not cache.has(region):
		if objects.is_empty():objects=WolfWorldData.generate(region).objects
		cache[region]=build(region,objects)
	recent.erase(region);recent.append(region)
	while recent.size()>MAX_CACHED:cache.erase(recent.pop_front())
	return cache[region]

static func style(biome: String) -> Dictionary:
	match biome:
		"pine":return {"kind":"needles","color":Color("#8d8062"),"width":0.91}
		"oak","forest","ruins":return {"kind":"leaves","color":Color("#958165"),"width":1.0}
		"alpine":return {"kind":"stone","color":Color("#a3a297"),"width":0.76}
		"snow":return {"kind":"snow","color":Color("#d1dedd"),"width":0.82}
		"coast":return {"kind":"sand","color":Color("#cabb8e"),"width":0.98}
		"river","lake":return {"kind":"gravel","color":Color("#b0a691"),"width":0.88}
		"marsh":return {"kind":"peat","color":Color("#858565"),"width":0.82}
	return {"kind":"grass","color":Color("#9da274"),"width":0.84}

static func build(region: int,objects: Array) -> Dictionary:
	var info: Dictionary=WolfWorldData.REGIONS[region]
	var palette := style(info.biome)
	var phase := float(info.seed)*0.017
	var collision := WolfCollisionIndex.new();collision.build(objects)
	var junction := Vector2(1600+sin(phase)*21,1574+cos(phase*0.73)*24)
	var directions: Array[String]=[]
	for direction in ["north","west","east","south"]:
		if info.links.has(direction) and not (region==0 and direction=="south"):directions.append(direction)
	# Two or three arms, never a four-way road through every region.
	if directions.size()>3:directions.remove_at(posmod(region*7+int(info.seed),directions.size()))
	if region!=0 and directions.size()>2 and (info.biome in ["meadow","alpine","snow","coast"] or region%4==2):directions.remove_at(posmod(region*3,directions.size()))
	var network := {"region":region,"kind":palette.kind,"color":palette.color,"junction":junction,"branches":[],"vertices":PackedVector2Array(),"weights":PackedFloat32Array(),"tints":PackedFloat32Array(),"length":0.0,"mouths":[]}
	for index in range(directions.size()):
		var fading: bool=index==2 and region%3!=1
		var fraction := 0.64+fposmod(phase,0.18) if fading else 1.0
		var branch := _branch(region,junction,directions[index],fraction,phase+index*1.73,float(palette.width),objects)
		_trim_to_safe(branch,region,collision)
		if branch.points.size()<3:continue
		network.branches.append(branch)
		network.length+=branch.length
		_add_strip(network,branch)
		var mouth := _section(branch,1)
		for band in range(BANDS.size()):network.mouths.append({"p":mouth[band],"weight":float(BAND_WEIGHT[band]),"angle":junction.angle_to_point(mouth[band])})
	# All strips share these same cross-sections. One fan fills only the
	# intervening junction: no intersecting rectangles or duplicate surfaces.
	network.mouths.sort_custom(func(a: Dictionary,b: Dictionary):return a.angle<b.angle)
	for i in range(network.mouths.size()):
		var a: Dictionary=network.mouths[i]
		var b: Dictionary=network.mouths[(i+1)%network.mouths.size()]
		var angle_gap := fposmod(float(b.angle)-float(a.angle),TAU)
		if angle_gap<PI/3:
			_add_triangle(network,junction,a.p,b.p,0.86,a.weight,b.weight)
		else:
			# Round the unused side into grass instead of spanning a
			# backwards, overlapping fan across a two-arm bend.
			var previous: Vector2=a.p
			var previous_weight: float=a.weight
			var steps := ceili(angle_gap/(PI/6))
			for step in range(1,steps):
				var point := junction+Vector2.from_angle(float(a.angle)+angle_gap*float(step)/steps)*17
				_add_triangle(network,junction,previous,point,0.86,previous_weight,0)
				previous=point;previous_weight=0
			_add_triangle(network,junction,previous,b.p,0.86,previous_weight,b.weight)
	_index_segments(network)
	return network

static func _branch(region: int,junction: Vector2,direction: String,fraction: float,phase: float,width_scale: float,objects: Array) -> Dictionary:
	var horizontal := direction in ["east","west"]
	var endpoint: float=3200.0 if direction in ["east","south"] else 0.0
	var origin: float=junction.x if horizontal else junction.y
	var distance := absf(endpoint-origin)*fraction
	var count := maxi(3,ceili((distance-MOUTH_DISTANCE)/SECTION_SPACING))
	var result := {"direction":direction,"points":PackedVector2Array([junction]),"half_widths":PackedFloat32Array([15.0*width_scale]),"fade":PackedFloat32Array([1.0]),"length":distance,"fades_out":fraction<0.999}
	for i in range(count+1):
		var travelled := lerpf(MOUTH_DISTANCE,distance,float(i)/count)
		var t := travelled/absf(endpoint-origin)
		var along := lerpf(origin,endpoint,t)
		var legacy := _legacy_center(along,region)
		var start_center := _legacy_center(origin,region)
		var start_offset: float=(junction.y if horizontal else junction.x)-start_center
		var wander: float=sin(t*PI)*(sin(t*PI*3+phase)*9+sin(t*PI*5-phase)*3.5)
		var across := legacy+start_offset*pow(1-t,4)+wander
		var point := Vector2(along,across) if horizontal else Vector2(across,along)
		if horizontal and WolfWorldData.REGIONS[region].biome=="river":
			point.y=lerpf(1600,point.y,smoothstep(145,500,absf(point.x-WolfWorldData.river_x(1600))))
		if horizontal and WolfWorldData.REGIONS[region].biome=="coast":point.y=lerpf(1600,point.y,smoothstep(560,730,point.x))
		var width := width_scale*(13.8+2.6*sin(travelled*0.007+phase)+1.1*cos(travelled*0.021-phase))
		var fade := smoothstep(0,240,distance-travelled) if fraction<0.999 else 1.0
		if not _safe(point,region,objects):
			# An old boulder or plant stays in place; the trail fades before it.
			result.fades_out=true
			var actual_end: float=junction.distance_to(result.points[-1])
			for section in range(1,result.points.size()):
				var remaining: float=actual_end-junction.distance_to(result.points[section])
				result.fade[section]=smoothstep(0,180,maxf(remaining,0))
				result.half_widths[section]*=0.25+0.75*sqrt(result.fade[section])
			break
		result.points.append(point)
		result.half_widths.append(width*(0.25+0.75*sqrt(fade)) if fraction<0.999 else width)
		result.fade.append(fade)
	return result

static func _legacy_center(along: float,region: int) -> float:
	var t := clampf(along/3200,0,1)
	return 1600+sin(t*TAU)*sin(t*PI)*140*sin(float(region)*0.7+1.0)

static func _safe(point: Vector2,region: int,objects: Array) -> bool:
	return point.is_finite() and not WolfWorldData.water_blocked(point,region) and WolfWorldData.walkable(point,objects)

static func _trim_to_safe(branch: Dictionary,region: int,collision: WolfCollisionIndex) -> void:
	# Check the actual painted shoulders, not only their free centreline.
	var trimmed := true
	while trimmed and branch.points.size()>2:
		trimmed=false
		for index in range(1,branch.points.size()-1):
			var a := _section(branch,index)
			var b := _section(branch,index+1)
			var section_safe := true
			for band in range(BANDS.size()-1):
				if not _triangle_safe(a[band],b[band],b[band+1],region,collision) or not _triangle_safe(a[band],b[band+1],a[band+1],region,collision):section_safe=false;break
			if section_safe:continue
			branch.points.resize(index+1);branch.half_widths.resize(index+1);branch.fade.resize(index+1)
			branch.fades_out=true
			var end: float=branch.points[0].distance_to(branch.points[-1])
			branch.length=end
			for section in range(1,branch.points.size()):
				var remaining: float=end-branch.points[0].distance_to(branch.points[section])
				branch.fade[section]=smoothstep(0,180,maxf(remaining,0))
				branch.half_widths[section]*=0.25+0.75*sqrt(branch.fade[section])
			trimmed=true;break

static func _triangle_safe(a: Vector2,b: Vector2,c: Vector2,region: int,collision: WolfCollisionIndex) -> bool:
	for point in [a,b,c,(a+b+c)/3,(a+b)/2,(b+c)/2,(c+a)/2]:
		if not collision.walkable(point) or WolfWorldData.water_blocked(point,region):return false
	return true

static func _section(branch: Dictionary,index: int) -> PackedVector2Array:
	var points: PackedVector2Array=branch.points
	var tangent: Vector2=points[mini(index+1,points.size()-1)]-points[maxi(index-1,0)]
	var side := Vector2(-tangent.y,tangent.x).normalized()*float(branch.half_widths[index])
	var section := PackedVector2Array()
	for band in BANDS:section.append((points[index]+side*float(band)).clamp(Vector2.ZERO,Vector2(3200,3200)))
	return section

static func _add_strip(network: Dictionary,branch: Dictionary) -> void:
	for index in range(1,branch.points.size()-1):
		var a := _section(branch,index)
		var b := _section(branch,index+1)
		for band in range(BANDS.size()-1):
			var aw: float=float(BAND_WEIGHT[band])*float(branch.fade[index])
			var az: float=float(BAND_WEIGHT[band+1])*float(branch.fade[index])
			var bw: float=float(BAND_WEIGHT[band])*float(branch.fade[index+1])
			var bz: float=float(BAND_WEIGHT[band+1])*float(branch.fade[index+1])
			_add_triangle(network,a[band],b[band],b[band+1],aw,bw,bz)
			_add_triangle(network,a[band],b[band+1],a[band+1],aw,bz,az)

static func _add_triangle(network: Dictionary,a: Vector2,b: Vector2,c: Vector2,aw: float,bw: float,cw: float) -> void:
	var area := (b-a).cross(c-a)
	if absf(area)<0.001:return
	# Godot uses clockwise front faces. Positive X/Y order yields upward X/Z normals.
	if area<0:
		var point := b;b=c;c=point
		var weight := bw;bw=cw;cw=weight
	for point in [a,b,c]:
		network.vertices.append(point)
		network.tints.append(0.92+0.10*sin(point.x*0.028+point.y*0.031)+0.045*cos(point.x*0.012-point.y*0.017))
	for weight in [aw,bw,cw]:network.weights.append(weight)

static func vertex_colors(network: Dictionary,color: Color) -> PackedColorArray:
	var colors := PackedColorArray()
	for index in range(network.vertices.size()):
		var tint: float=network.tints[index]
		colors.append(Color(color.r*tint,color.g*tint,color.b*tint,float(network.weights[index])*0.79))
	return colors

static func mesh_2d(network: Dictionary,color: Color) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if network.vertices.is_empty():return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=network.vertices
	arrays[Mesh.ARRAY_COLOR]=vertex_colors(network,color)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

static func contains(point: Vector2,network: Dictionary,padding: float=0.0) -> bool:
	var segments: Array=network.segment_cells.get(Vector2i(point/128),[]) if padding<=16 else network.segments
	for segment in segments:
		var a: Vector2=segment.a
		var b: Vector2=segment.b
		var delta := b-a
		var t := clampf((point-a).dot(delta)/maxf(delta.length_squared(),0.001),0,1)
		var width: float=lerpf(segment.aw,segment.bw,t)+padding
		if lerpf(segment.af,segment.bf,t)>0.1 and point.distance_squared_to(a+delta*t)<width*width:return true
	return false

static func _index_segments(network: Dictionary) -> void:
	network.segments=[];network.segment_cells={}
	for branch in network.branches:
		for index in range(branch.points.size()-1):
			var a: Vector2=branch.points[index]
			var b: Vector2=branch.points[index+1]
			var segment := {"a":a,"b":b,"aw":branch.half_widths[index],"bw":branch.half_widths[index+1],"af":branch.fade[index],"bf":branch.fade[index+1]}
			network.segments.append(segment)
			var radius: float=maxf(segment.aw,segment.bw)+16
			var lo := Vector2i((Vector2(minf(a.x,b.x),minf(a.y,b.y))-Vector2.ONE*radius)/128)
			var hi := Vector2i((Vector2(maxf(a.x,b.x),maxf(a.y,b.y))+Vector2.ONE*radius)/128)
			for y in range(lo.y,hi.y+1):
				for x in range(lo.x,hi.x+1):
					var cell := Vector2i(x,y)
					if not network.segment_cells.has(cell):network.segment_cells[cell]=[]
					network.segment_cells[cell].append(segment)
