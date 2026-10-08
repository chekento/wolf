class_name WolfForestMesh
extends RefCounted

# Small original botanical meshes, shared by MultiMeshes in every region.
static var cache: Dictionary = {}
static var lod_index_counts: Dictionary = {}
const MAX_CACHED := 32
const HABITAT_KINDS := ["habitat_litter","habitat_fungi","habitat_deadwood","habitat_herbs","habitat_seedheads","habitat_pebbles","habitat_driftwood","habitat_sedge","habitat_moss","habitat_frostwood","habitat_snowtufts"]
static var recent: Array[String]=[]

static func is_habitat_mesh(kind: String) -> bool:return kind in HABITAT_KINDS

static func _remember_mesh(kind: String,mesh: Mesh) -> Mesh:
	cache[kind]=mesh;recent.erase(kind);recent.append(kind)
	while recent.size()>MAX_CACHED:
		var expired: String=recent.pop_front()
		cache.erase(expired);lod_index_counts.erase(expired)
	return mesh

static func site_style(biome: String,variant: int) -> String:
	match biome:
		"coast":return ["shells","driftwood","dune_grass"][variant%3]
		"marsh":return ["reeds","wet_log","reeds"][variant%3]
		"river","lake":return ["pebbles","driftwood","reeds"][variant%3]
		"alpine":return ["cairn","pebbles","alpine_flowers"][variant%3]
		"snow":return ["snow_rocks","pinecones","frost_grass"][variant%3]
		"pine":return ["pinecones","fallen_log","pinecones"][variant%3]
		"ruins":return ["cairn","mushrooms","fallen_log"][variant%3]
		"forest","oak":return ["mushrooms","fallen_log","flowers"][variant%3]
		_:return ["flowers","fallen_log","flowers"][variant%3]

static func triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,color: Color) -> void:
	for p in [a,b,c]:
		st.set_color(color)
		st.add_vertex(p)

static func get_mesh(kind: String) -> Mesh:
	if cache.has(kind):return _remember_mesh(kind,cache[kind])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid := {}
	var segments := 14 if kind in ["leaf","pine"] else 12
	var rows := 10 if kind=="pine" else 8
	if is_habitat_mesh(kind):
		build_habitat(st,kind)
	elif kind in ["mushroom","shell"]:
		build_nature_detail(st,kind)
	elif kind.begins_with("track_"):
		build_footprint(st,kind)
	elif kind in ["grass","fern","reed","flower"]:
		build_botanical(st,kind)
	else:
		for j in range(rows):
			for i in range(segments):
				for coord in [Vector2i(j,i),Vector2i(j+1,i),Vector2i(j+1,i+1),Vector2i(j,i),Vector2i(j+1,i+1),Vector2i(j,i+1)]:
					var a := float(coord.y)/segments*TAU
					var t := float(coord.x)/rows
					var r := 1.0
					var y := t-0.5
					var p := Vector3.ZERO
					if kind=="pine":
						r=pow(1-t,0.75)*(0.87+0.10*sin(a*6+t*8)+0.045*cos(a*3-t*9))
						y+=sin(a*6+t*11)*0.060*(1-t)
					elif kind=="leaf":
						r=pow(sin(t*PI),0.78)*(0.90+sin(a*5+t*11)*0.12+cos(a*3-t*7)*0.07)
						y=cos(t*PI)*0.5+sin(a*3+t*4)*0.065*sin(t*PI)
					elif kind in ["trunk","log"]:
						r=0.5*(1-t*0.32)*(0.94+sin(a*7+t*5)*0.055)
						if kind=="trunk":r*=1.0+pow(1.0-t,7)*0.56
					elif kind=="ridge":
						r=pow(1-t,0.92)*(0.77+sin(a*3)*0.14+cos(a*7+t*6)*0.07)
						y=t-0.5
					else:
						r=sin(t*PI)*(0.83+sin(a*3+t*8)*0.14)
						y=cos(t*PI)*0.5
					p=Vector3(cos(a)*r,y,sin(a)*r)
					if kind=="log":p=Vector3(p.x,p.z,y)
					if kind=="leaf":p.x+=sin(t*PI)*0.075
					grid[coord]=p
					var shade := 0.91+sin(a*3+t*7)*0.045+0.09*t
					st.set_color(Color(shade,shade,shade,1))
					st.add_vertex(p)
	st.index()
	st.generate_normals()
	var mesh := st.commit()
	if not grid.is_empty():mesh=with_lod(mesh,grid,segments,rows,kind)
	return _remember_mesh(kind,mesh)

static func habitat_leaf(st: SurfaceTool,p: Vector3,angle: float,length: float,width: float,color: Color) -> void:
	var direction := Vector3(cos(angle),0,sin(angle))
	var side := Vector3(-sin(angle),0,cos(angle))
	var middle := p+Vector3(0,.012,0)
	var points := [p+direction*length,p+side*width,p-direction*length*.78,p-side*width]
	for i in range(4):triangle(st,middle,points[i],points[(i+1)%4],detail_colour(color.lightened(.025 if i%2 else 0)))

static func habitat_twig(st: SurfaceTool,a: Vector3,b: Vector3,radius: float,color: Color) -> void:
	var axis := (b-a).normalized()
	var side := axis.cross(Vector3.UP).normalized()
	var up := side.cross(axis).normalized()
	for i in range(7):
		var first := (side*cos(i*TAU/7)+up*sin(i*TAU/7))*radius
		var next := (side*cos((i+1)*TAU/7)+up*sin((i+1)*TAU/7))*radius
		var shade := detail_colour(color.lightened(float(i%3)*.018))
		triangle(st,a+first,b+first*.63,b+next*.63,shade)
		triangle(st,a+first,b+next*.63,a+next,shade)
		triangle(st,a,a+next,a+first,detail_colour(Color("#ba9c70")))
		triangle(st,b,b+first*.63,b+next*.63,detail_colour(Color("#c9ac7c")))

static func habitat_pebble(st: SurfaceTool,p: Vector3,radius: float,height: float,color: Color) -> void:
	for i in range(7):
		var a := i*TAU/7.0
		var b := (i+1)*TAU/7.0
		var first := p+Vector3(cos(a)*radius,.012,sin(a)*radius*.73)
		var next := p+Vector3(cos(b)*radius,.012,sin(b)*radius*.73)
		triangle(st,p+Vector3(.015,height,-.013),first,next,detail_colour(color.lightened(float(i%3)*.025)))

static func habitat_mushroom(st: SurfaceTool,p: Vector3,scale: float,color: Color) -> void:
	for i in range(7):
		var a := i*TAU/7.0
		var b := (i+1)*TAU/7.0
		var first := Vector3(cos(a)*.026,0,sin(a)*.026)*scale
		var next := Vector3(cos(b)*.026,0,sin(b)*.026)*scale
		var top := Vector3(0,.15*scale,0)
		triangle(st,p+first,p+first+top,p+next+top,detail_colour(Color("#c5b896")))
		triangle(st,p+first,p+next+top,p+next,detail_colour(Color("#d2c4a3")))
		var rim_a := Vector3(cos(a)*.13,.15,sin(a)*.13)*scale
		var rim_b := Vector3(cos(b)*.13,.15,sin(b)*.13)*scale
		triangle(st,p+Vector3(0,.225*scale,0),p+rim_a,p+rim_b,detail_colour(color.lightened(float(i%2)*.045)))
		triangle(st,p+top,p+rim_b,p+rim_a,detail_colour(Color("#bbaa88")))

static func habitat_blade(st: SurfaceTool,p: Vector3,angle: float,height: float,width: float,color: Color,seed: bool=false) -> void:
	var direction := Vector3(cos(angle),0,sin(angle))
	var side := Vector3(-sin(angle),0,cos(angle))*width
	var middle := p+direction*.04+Vector3(0,height*.58,0)
	var tip := p+direction*.11+Vector3(0,height,0)
	triangle(st,p-side,p+side,middle+side*.55,detail_colour(color.darkened(.025)))
	triangle(st,p-side,middle+side*.55,middle-side*.55,detail_colour(color))
	triangle(st,middle-side*.55,middle+side*.55,tip,detail_colour(color.lightened(.035)))
	if seed:
		triangle(st,tip-side*1.7,tip+side*1.7,tip+Vector3(0,.055,0),detail_colour(Color("#b5a17b")))

static func build_habitat(st: SurfaceTool,kind: String) -> void:
	# Each whole clump is one low original mesh, including its small grouped
	# components. Fixed recipes and rotations keep the cache finite.
	if kind in ["habitat_litter","habitat_fungi","habitat_deadwood"]:
		var leaves := 14 if kind=="habitat_litter" else 7
		for i in range(leaves):
			var angle := float(i)*2.399
			var radius := .14+float(i%4)*.125
			var p := Vector3(cos(angle)*radius,.018,sin(angle)*radius)
			habitat_leaf(st,p,angle+.8,.08+float(i%3)*.018,.037,[Color("#8c794f"),Color("#a68b5b"),Color("#65774a"),Color("#b2986b")][i%4])
		if kind=="habitat_fungi":
			for i in range(3):habitat_mushroom(st,Vector3(-.22+float(i)*.24,.01,sin(float(i)*2.0)*.18),.75+float(i%2)*.28,Color("#9e7853").lightened(float(i)*.025))
		elif kind=="habitat_deadwood":
			habitat_twig(st,Vector3(-.47,.10,-.13),Vector3(.43,.09,.14),.085,Color("#766248"))
			habitat_twig(st,Vector3(-.11,.11,-.05),Vector3(.16,.07,-.40),.032,Color("#887152"))
		return
	if kind in ["habitat_pebbles","habitat_driftwood"]:
		for i in range(7 if kind=="habitat_pebbles" else 3):
			var angle := float(i)*2.399
			var p := Vector3(cos(angle)*(.15+float(i%3)*.14),0,sin(angle)*(.15+float(i%3)*.14))
			habitat_pebble(st,p,.09+float(i%3)*.035,.04+float(i%2)*.025,[Color("#a7ada4"),Color("#859990"),Color("#bec2ad")][i%3])
		if kind=="habitat_driftwood":
			habitat_twig(st,Vector3(-.50,.075,-.10),Vector3(.44,.07,.13),.065,Color("#ad9c7b"))
			habitat_twig(st,Vector3(-.21,.08,.01),Vector3(-.38,.055,.32),.025,Color("#a49372"))
		return
	if kind in ["habitat_moss","habitat_snowtufts"]:
		for i in range(5):
			var angle := float(i)*2.399
			var p := Vector3(cos(angle)*.32,0,sin(angle)*.32)
			habitat_pebble(st,p,.15+float(i%2)*.025,.07+float(i%3)*.016,Color("#75815a") if kind=="habitat_moss" else Color("#d2e1df"))
	if kind=="habitat_frostwood":
		habitat_twig(st,Vector3(-.49,.075,-.10),Vector3(.44,.06,.12),.065,Color("#8c8a73"))
		habitat_twig(st,Vector3(-.41,.133,-.08),Vector3(.31,.111,.10),.014,Color("#dde7df"))
		for i in range(3):habitat_pebble(st,Vector3(-.28+float(i)*.29,0,.25),.14,.045,Color("#d6e1dd"))
		return
	for i in range(8 if kind in ["habitat_sedge","habitat_seedheads"] else 6):
		var angle := float(i)*2.399
		var p := Vector3(cos(angle)*(.10+float(i%3)*.12),0,sin(angle)*(.10+float(i%3)*.12))
		var height := .29+float(i%3)*.045 if kind=="habitat_sedge" else .32+float(i%3)*.055 if kind=="habitat_seedheads" else .18+float(i%3)*.035
		var color := Color("#8c9165") if kind=="habitat_seedheads" else Color("#819071") if kind=="habitat_snowtufts" else Color("#698154")
		habitat_blade(st,p,angle,height,.013 if kind!="habitat_herbs" else .022,color,kind in ["habitat_sedge","habitat_seedheads"])
		if kind=="habitat_herbs":
			habitat_leaf(st,p+Vector3(0,.10,0),angle+.6,.10,.038,Color("#81956b"))
			for petal in range(5):
				var tip := p+Vector3(cos(angle)*.11,height,sin(angle)*.11)
				var a := float(petal)*TAU/5.0
				var b := (float(petal)+.7)*TAU/5.0
				triangle(st,tip,tip+Vector3(cos(a)*.036,.008,sin(a)*.036),tip+Vector3(cos(b)*.036,.012,sin(b)*.036),detail_colour(Color("#ddd5b8") if i%2 else Color("#bbb2c5")))

static func build_nature_detail(st: SurfaceTool,kind: String) -> void:
	if kind=="shell":
		var hinge := Vector3(0,.025,-.13)
		for i in range(18):
			var a := -PI*.06+float(i)/18.0*PI*1.12
			var b := -PI*.06+float(i+1)/18.0*PI*1.12
			var edge_a := Vector3(cos(a)*.29,.025+sin(a)*.035,sin(a)*.29)
			var edge_b := Vector3(cos(b)*.29,.025+sin(b)*.035,sin(b)*.29)
			var middle := (edge_a+edge_b)*.32+hinge*.36+Vector3(0,.08,0)
			var colour := detail_colour(Color("#e8d6b3") if i%2==0 else Color("#c6b397"))
			triangle(st,hinge,edge_a,middle,colour)
			triangle(st,hinge,middle,edge_b,colour)
			triangle(st,middle,edge_a,edge_b,colour.lightened(.06))
		return
	for i in range(12):
		var a := i*TAU/12.0
		var b := (i+1)*TAU/12.0
		var root_a := Vector3(cos(a)*.048,0,sin(a)*.048)
		var root_b := Vector3(cos(b)*.048,0,sin(b)*.048)
		triangle(st,root_a,root_a+Vector3(0,.24,0),root_b+Vector3(0,.24,0),detail_colour(Color("#d7c9a2")))
		triangle(st,root_a,root_b+Vector3(0,.24,0),root_b,detail_colour(Color("#d7c9a2")))
	for row in range(4):
		for i in range(16):
			for coord in [Vector2i(row,i),Vector2i(row+1,i),Vector2i(row+1,i+1),Vector2i(row,i),Vector2i(row+1,i+1),Vector2i(row,i+1)]:
				var t := float(coord.x)/4.0*PI*.5
				var a := float(coord.y)*TAU/16.0
				var r := sin(t)*.26*(1.0+sin(a*5)*.035)
				st.set_color(detail_colour(Color("#b78056").lightened(.09*cos(t))))
				st.add_vertex(Vector3(cos(a)*r,.23+cos(t)*.12,sin(a)*r))

static func detail_colour(color: Color) -> Color:
	return color.srgb_to_linear().lerp(color,.22) if RenderingServer.get_current_rendering_method()=="gl_compatibility" else color.srgb_to_linear()

static func with_lod(source: ArrayMesh,grid: Dictionary,segments: int,rows: int,kind: String) -> ArrayMesh:
	# The distant shape reuses the actual near vertices. Joining alternate
	# rings keeps the silhouette, wind and palette aligned with the full mesh.
	# Native screen-size LOD also chooses lighter geometry for shadow passes.
	var arrays := source.surface_get_arrays(0)
	var vertex_map := {}
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()):vertex_map[vertices[i]]=i
	var indices := PackedInt32Array()
	for j in range(0,rows,2):
		for i in range(0,segments,2):
			var a := Vector2i(j,i)
			var b := Vector2i(mini(rows,j+2),i)
			var c := Vector2i(mini(rows,j+2),mini(segments,i+2))
			var d := Vector2i(j,mini(segments,i+2))
			for coord in [a,b,c,a,c,d]:indices.append(vertex_map[grid[coord]])
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{.022:indices})
	lod_index_counts[kind]={"near":source.surface_get_array_index_len(0),"far":indices.size()}
	return result

static func footprint_pad(st: SurfaceTool,center: Vector2,radii: Vector2) -> void:
	for i in range(12):
		var a := float(i)/12.0*TAU
		var b := float(i+1)/12.0*TAU
		triangle(st,Vector3(center.x,0,center.y),Vector3(center.x+cos(b)*radii.x,0,center.y+sin(b)*radii.y),Vector3(center.x+cos(a)*radii.x,0,center.y+sin(a)*radii.y),Color.WHITE)

static func build_footprint(st: SurfaceTool,kind: String) -> void:
	for side in [-1,1]:
		var p := Vector2(side*.22,side*.13)
		if kind=="track_deer":
			for hoof in [-1,1]:footprint_pad(st,p+Vector2(hoof*.034,0),Vector2(.026,.095))
		elif kind=="track_rabbit":
			footprint_pad(st,Vector2(side*.18,-.13),Vector2(.045,.13))
			footprint_pad(st,Vector2(side*.10,.18+side*.05),Vector2(.038,.052))
		else:
			footprint_pad(st,p,Vector2(.079,.062))
			for toe in range(4):footprint_pad(st,p+Vector2((toe-1.5)*.052,-.073 if toe in [0,3] else -.104),Vector2(.026,.033))

static func build_botanical(st: SurfaceTool,kind: String) -> void:
	if kind=="fern":
		for frond in range(7):
			var angle := frond*TAU/7.0
			var direction := Vector3(cos(angle),0,sin(angle))
			var side := Vector3(-sin(angle),0,cos(angle))
			for leaf in range(5):
				var t := 0.12+float(leaf)*0.16
				var root := direction*t+Vector3(0,sin(t*PI)*0.55,0)
				var tip := direction*(t+0.16)+Vector3(0,sin((t+0.16)*PI)*0.55,0)
				var width := (1-t)*0.12
				for sign_value in [-1.0,1.0]:
					triangle(st,root,root+side*width*sign_value+direction*0.08,tip,Color(0.84+t*0.13,0.96,0.79+float(frond%2)*.06,1))
		return
	if kind=="grass":
		# A curved fan covers more soil than isolated triangular spikes. Its
		# entire clump is still one tiny shared mesh and one instanced draw.
		for blade in range(9):
			var angle := blade*2.399
			var direction := Vector3(cos(angle),0,sin(angle))
			var root := direction*(.12+float(blade%3)*.085)
			var side := Vector3(-sin(angle),0,cos(angle))*.042
			var height := .48+float(blade%4)*.075
			var middle := root+direction*.09+Vector3(0,height*.58,0)
			var tip := root+direction*.31+Vector3(0,height,0)
			var colour := Color(.82+float(blade%3)*.045,.95,.75+float(blade%2)*.08,1)
			triangle(st,root-side,root+side,middle+side*.60,colour.darkened(.045))
			triangle(st,root-side,middle+side*.60,middle-side*.60,colour)
			triangle(st,middle-side*.60,middle+side*.60,tip,colour.lightened(.045))
		return
	for blade in range(7 if kind!="flower" else 4):
		var angle := blade*2.399
		var radius := 0.20 if kind=="reed" else 0.35
		var root := Vector3(cos(angle)*radius,0,sin(angle)*radius)
		var height := 0.55+sin(blade*1.3)*0.13 if kind=="grass" else 1.2+sin(blade*1.2)*0.2 if kind=="reed" else 0.7
		var side := Vector3(-sin(angle),0,cos(angle))*(0.027 if kind=="reed" else 0.06)
		var bend := Vector3(cos(angle)*0.19,height,sin(angle)*0.19)
		triangle(st,root-side,root+side,root+bend,Color(0.89,0.98,0.82,1))
		if kind=="flower":
			var centre := root+bend
			for petal in range(5):
				var a := petal*TAU/5.0
				var b := (petal+0.65)*TAU/5.0
				triangle(st,centre,centre+Vector3(cos(a)*0.09,0.022,sin(a)*0.09),centre+Vector3(cos(b)*0.09,0.018,sin(b)*0.09),Color("#f5dec3") if blade%2==0 else Color("#ded1ed"))
		elif kind=="reed":
			var tip := root+bend
			var offset := side*1.8
			triangle(st,tip-offset,tip+offset,tip+Vector3(0,0.21,0),Color("#978263"))
