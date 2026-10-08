class_name WolfForestMesh
extends RefCounted

# Small original botanical meshes, shared by MultiMeshes in every region.
static var cache: Dictionary = {}
static var lod_index_counts: Dictionary = {}

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
	if cache.has(kind):return cache[kind]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid := {}
	var segments := 14 if kind in ["leaf","pine"] else 12
	var rows := 10 if kind=="pine" else 8
	if kind in ["mushroom","shell"]:
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
	cache[kind]=mesh
	return mesh

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
