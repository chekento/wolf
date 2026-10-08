class_name WolfWorldView
extends Node3D

const UNIT := 0.032
var game: Node
var region_built := -1
var camera: Camera3D
var contents: Node3D
var animal_nodes: Array[WolfAnimalModel]=[]
var sky_material: ShaderMaterial
var lighting_timer := 0.0
var scene_materials: Array[ShaderMaterial]=[]
var nature_shader: Shader=preload("res://assets/wilderness.gdshader")
var track_nodes: Dictionary={}
var yaw := 0.0
var pitch := -0.14
var food_node: Node3D
var batches: Dictionary={}
var env: WorldEnvironment
var sun: DirectionalLight3D
var material_cache: Dictionary={}
var decorative_nodes: Array[MultiMeshInstance3D]=[]
var food_nodes: Array[Node3D]=[]
var built_season := ""
var follow_camera := false
var player_model: WolfAnimalModel
var camera_initialized := false
var camera_time := -1.0

func _ready() -> void:
	camera=Camera3D.new()
	camera.fov=72
	camera.near=0.05
	camera.far=175
	add_child(camera)
	env=WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode=Environment.BG_SKY
	var sky := Sky.new()
	sky_material=ShaderMaterial.new()
	sky_material.shader=preload("res://assets/wild-sky.gdshader")
	sky.sky_material=sky_material
	sky.radiance_size=Sky.RADIANCE_SIZE_32
	e.sky=sky
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("#d1dfd0")
	e.ambient_light_energy=0.6
	e.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	e.fog_enabled=true
	e.fog_density=0.004
	e.fog_light_color=Color("#bcc9bd")
	e.fog_light_energy=0.55
	e.fog_sun_scatter=0.15
	e.fog_sky_affect=0.06
	env.environment=e
	add_child(env)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-50,-30,0)
	sun.light_color=Color("#fff0ca")
	sun.light_energy=0.8
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=36
	add_child(sun)

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.95
	return m

func sphere_mesh() -> SphereMesh:
	var m := SphereMesh.new()
	m.radial_segments=12
	m.rings=7
	return m

func cone_mesh() -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius=0
	m.bottom_radius=1
	m.height=1
	m.radial_segments=12
	return m

func add_shape(kind: String,p: Vector3,dimensions: Vector3,color: Color,rotation: float=0) -> void:
	# Spatial chunks let Godot cull entire groves instead of drawing every tree.
	var chunk := Vector2i(floori(p.x/24.0),floori(p.z/24.0))
	# Tint belongs to each instance, not the batch. Birch trunks and individual
	# crown layers can then share one draw call without losing their palette.
	var key := kind+str(chunk)
	var center := Vector3(chunk.x*24.0+12,0,chunk.y*24.0+12)
	if not batches.has(key):batches[key]={"kind":kind,"center":center,"transforms":[],"colors":[]}
	var basis := Basis(Vector3.UP,rotation).scaled(dimensions)
	batches[key].transforms.append(Transform3D(basis,p-center))
	batches[key].colors.append(color)

func flush_batches() -> void:
	for key in batches:
		var batch: Dictionary=batches[key]
		var mm := MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.use_colors=true
		mm.mesh=WolfForestMesh.get_mesh(batch.kind) if batch.kind in ["pine","leaf","trunk","stone","grass","fern","reed","flower","log","ridge","mushroom","shell"] else sphere_mesh() if batch.kind=="sphere" else cone_mesh() if batch.kind=="cone" else BoxMesh.new()
		# A default BoxMesh has size 1×1×1.
		mm.instance_count=batch.transforms.size()
		for i in range(batch.transforms.size()):
			mm.set_instance_transform(i,batch.transforms[i])
			var colour: Color=batch.colors[i]
			mm.set_instance_color(i,painted_colour(colour))
		var n := MultiMeshInstance3D.new()
		n.multimesh=mm
		n.position=batch.center
		n.material_override=nature_material(Color.WHITE,1 if batch.kind in ["pine","leaf"] else 2 if batch.kind in ["trunk","log"] else 4 if batch.kind in ["grass","fern","reed","flower"] else 0)
		if batch.kind in ["grass","fern","reed","flower"]:
			n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.visibility_range_end=46
			n.visibility_range_end_margin=5
			decorative_nodes.append(n)
		contents.add_child(n)
	batches.clear()

func mesh_at(parent: Node3D,mesh: Mesh,p: Vector3,color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh=mesh
	n.material_override=material(color)
	n.position=p
	parent.add_child(n)
	return n

func sphere(parent: Node3D,p: Vector3,dimensions: Vector3,color: Color) -> MeshInstance3D:
	var n := mesh_at(parent,sphere_mesh(),p,color)
	n.scale=dimensions
	return n

func box(parent: Node3D,p: Vector3,dimensions: Vector3,color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size=dimensions
	return mesh_at(parent,mesh,p,color)

func world_pos(p: Vector2) -> Vector3:
	return Vector3(p.x*UNIT,height_at(p),p.y*UNIT)

func height_at(p: Vector2) -> float:
	if game==null:return 0
	return WolfWorldData.height_at(p,game.state.region)

func seasonal_color(color: Color,foliage: bool=false) -> Color:
	var season: String=game.state.season_name()
	var biome: String=WolfWorldData.REGIONS[game.state.region].biome
	if biome=="snow":return color.lerp(Color("#d4e1dc"),0.45 if foliage else 0.25)
	if season=="Herbst" and foliage:return color.lerp(Color("#b69258"),0.64 if biome not in ["pine","alpine"] else 0.16)
	if season=="Winter":return color.lerp(Color("#b8c6bd"),0.43 if biome not in ["coast","village"] else 0.18)
	if season=="Sommer":return color.darkened(0.055)
	return color

func build_river() -> void:
	for bank in [true,false]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var width := 112.0 if bank else 97.5
		for i in range(64):
			var a := Vector2(WolfWorldData.river_x(i*50.0),i*50.0)
			var b := Vector2(WolfWorldData.river_x((i+1)*50.0),(i+1)*50.0)
			for p in [a-Vector2(width,0),b-Vector2(width,0),b+Vector2(width,0),a-Vector2(width,0),b+Vector2(width,0),a+Vector2(width,0)]:
				st.add_vertex(world_pos(p)+Vector3(0,0.012 if bank else 0.024,0))
		st.generate_normals()
		var n := MeshInstance3D.new()
		n.mesh=st.commit()
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.material_override=nature_material(Color("#7c9166") if bank else Color("#639fa5"),0 if bank else 3)
		contents.add_child(n)
	for y in range(110,3200,100):
		for side in [-1,1]:
			if abs(y-800)<90 or abs(y-1600)<90 or abs(y-2600)<90:continue
			var p := Vector2(WolfWorldData.river_x(y)+side*113,y)
			add_shape("reed",world_pos(p),Vector3(0.45,0.77,0.45),Color("#85925d"),float(y)*0.01)

func build_understory(biome: String) -> void:
	for i in range(game.world.decor.size()):
		var d: Dictionary=game.world.decor[i]
		var p: Vector2=d.p
		if WolfWorldData.on_path(p,game.state.region,64) or WolfWorldData.water_blocked(p,game.state.region):continue
		if i%3==0 and biome in ["snow","alpine","coast"]:continue
		var kind := "fern" if biome in ["forest","oak","ruins"] and i%9==0 else "reed" if biome=="marsh" and i%4==0 else "flower" if biome=="meadow" and i%7==0 else "grass"
		if biome=="snow":kind="grass"
		if game.state.season_name()=="Winter" and kind=="flower":kind="grass"
		var colour := Color("#678448") if kind!="reed" else Color("#92935c")
		if biome in ["alpine","coast"]:colour=Color("#96976b")
		var s: float=0.40+float(i%4)*0.065
		if kind=="fern":s=0.64
		if kind=="reed":s=0.70
		if biome=="snow":s*=0.65
		add_shape(kind,world_pos(p),Vector3(s,s,s),seasonal_color(colour,true),float(i)*2.399)

func build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ground := Color(WolfWorldData.REGIONS[game.state.region].ground)
	ground=seasonal_color(ground.lerp(Color("#89947a"),0.24))
	for y in range(40):
		for x in range(40):
			for offset in [Vector2(0,0),Vector2(0,1),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(1,0)]:
				var p: Vector2 = (Vector2(x,y)+offset)*80
				var shade := 0.99+0.025*sin(p.x*0.009+p.y*0.011)
				st.set_color(Color(shade,shade,shade,1))
				st.add_vertex(world_pos(p))
	st.generate_normals()
	var n := MeshInstance3D.new()
	n.mesh=st.commit()
	# Terrain receives tree/animal shadows but must not write itself into the
	# mobile depth atlas: nearly coplanar soil/path surfaces produce acne.
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := nature_material(ground,5)
	n.material_override=m
	contents.add_child(n)
	for vertical in [true,false]:
		var points := WolfWorldData.path_points(game.state.region,vertical)
		var trail := SurfaceTool.new()
		trail.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(points.size()-1):
			var a: Vector2=points[i]
			var b: Vector2=points[i+1]
			var side := Vector2(-(b-a).y,(b-a).x).normalized()*34
			for p in [a-side,b-side,b+side,a-side,b+side,a+side]:trail.add_vertex(world_pos(p)+Vector3(0,0.015,0))
		trail.generate_normals()
		var path_mesh := MeshInstance3D.new()
		path_mesh.mesh=trail.commit()
		path_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		path_mesh.material_override=nature_material(Color("#aa9e79") if WolfWorldData.REGIONS[game.state.region].biome!="snow" else Color("#e4eeec"),6)
		contents.add_child(path_mesh)

func build_nature_site(p: Vector3,biome: String,variant: int) -> void:
	var style := WolfForestMesh.site_style(biome,variant)
	match style:
		"shells":
			for i in range(6):
				var q := p+Vector3(sin(i*2.4)*.75,.01,cos(i*2.4)*.65)
				add_shape("shell",q,Vector3.ONE*(.8+float(i%3)*.2),Color.WHITE,float(i)*1.2)
		"driftwood","fallen_log","wet_log":
			add_shape("log",p+Vector3(0,.22,0),Vector3(.42,.42,2.3),Color("#a29578") if style=="driftwood" else Color("#857051"),.8)
			for i in range(3):add_shape("reed" if style=="wet_log" else "grass" if style=="driftwood" else "fern",p+Vector3(-.8+i*.55,0,-.3),Vector3.ONE*.7,seasonal_color(Color("#819956"),true),float(i)*2)
		"reeds","dune_grass","frost_grass":
			for i in range(7):
				var q := p+Vector3(sin(i*2.4)*.9,0,cos(i*2.4)*.75)
				add_shape("reed" if style=="reeds" else "grass",q,Vector3.ONE*(.85+float(i%3)*.12),seasonal_color(Color("#a59d6b") if style=="dune_grass" else Color("#8b975f"),true),float(i)*1.7)
			if style=="reeds":add_shape("flower",p+Vector3(.15,0,.1),Vector3.ONE*.8,Color("#a0b09a"))
		"cairn","pebbles","snow_rocks":
			for i in range(4):
				var q := Vector3(0,.18+i*.27,0) if style=="cairn" else Vector3(sin(i*2)*.7,.13,cos(i*2)*.6)
				var s := .65-float(i)*.09 if style=="cairn" else .40+float(i%3)*.09
				add_shape("stone",p+q,Vector3(s,s*.48,s*.8),Color("#d3e1df") if style=="snow_rocks" else Color("#a3ad9b"),float(i)*.7)
		"pinecones":
			for i in range(7):add_shape("stone",p+Vector3(sin(i*2.4)*.85,.055,cos(i*2.4)*.7),Vector3(.13,.19,.13),Color("#8c6a44"),float(i))
			add_shape("grass",p+Vector3(.7,0,-.3),Vector3.ONE*.7,seasonal_color(Color("#83945c"),true))
		"mushrooms":
			for i in range(5):add_shape("mushroom",p+Vector3(sin(i*2.4)*.6,0,cos(i*2.4)*.5),Vector3.ONE*(.8+float(i%2)*.35),Color.WHITE,float(i))
			add_shape("fern",p+Vector3(-.5,0,.5),Vector3.ONE*.7,seasonal_color(Color("#819956"),true))
		_:
			for i in range(5):add_shape("flower",p+Vector3(sin(i*2.4)*.65,0,cos(i*2.4)*.65),Vector3.ONE*(.65 if style=="alpine_flowers" else 1.1),seasonal_color(Color("#8e9c5f"),true),float(i))

func rebuild() -> void:
	region_built=game.state.region
	if contents!=null:
		remove_child(contents)
		contents.queue_free()
	contents=Node3D.new()
	add_child(contents)
	animal_nodes.clear()
	track_nodes.clear()
	batches.clear()
	scene_materials.clear()
	material_cache.clear()
	decorative_nodes.clear()
	food_nodes.clear()
	built_season=game.state.season_name()
	camera_initialized=false
	food_node=null
	var biome: String=WolfWorldData.REGIONS[game.state.region].biome
	build_ground()
	build_understory(biome)
	if biome=="river":build_river()
	if biome=="coast":
		var sea := PlaneMesh.new()
		sea.size=Vector2(14.24,102.4)
		var water_node := mesh_at(contents,sea,Vector3(7.12,0.02,51.2),Color("#609da7"))
		water_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		water_node.material_override=nature_material(Color("#609da7"),3)
		add_shape("box",Vector3(7.1,0.01,51.2),Vector3(14.7,0.06,4.2),Color("#d2c38d"))
	for obj in game.world.objects:
		var p := world_pos(obj.p)
		var s: float=obj.scale
		match obj.kind:
			"tree":
				var trunk := Color("#776044") if obj.variant!=2 else Color("#d2d0b8")
				add_shape("trunk",p+Vector3(0,1.7*s,0),Vector3(0.48,3.4*s,0.48),trunk)
				for root in range(3):
					var angle := root*TAU/3.0+float(obj.p.x)*0.01
					add_shape("stone",p+Vector3(cos(angle)*0.20,0.10,sin(angle)*0.20),Vector3(0.52,0.19,0.31)*s,trunk,angle)
				if obj.variant==0:
					for i in range(5):
						var color := seasonal_color(Color("#476a46").lightened(i*0.035),true)
						add_shape("pine",p+Vector3(0,(2.0+i*0.8)*s,0),Vector3((1.8-i*0.25)*s,2.1*s,(1.8-i*0.25)*s),color,float(i)*0.6)
						if biome=="snow":add_shape("pine",p+Vector3(0,(2.38+i*0.8)*s,0),Vector3((1.45-i*0.23)*s,1.2*s,(1.45-i*0.23)*s),Color("#d5e5df"),float(i)*0.6)
				else:
					for i in range(4):
						var angle := i*TAU/5
						var leaf_colour := Color("#708d53") if obj.variant==1 else Color("#91a474")
						add_shape("leaf",p+Vector3(cos(angle)*1.05,3.7+float(i%2)*0.55,sin(angle)*1.05)*s,Vector3(2.25,2.3,2.25)*s,seasonal_color(leaf_colour.lightened(i*0.016),true))
					add_shape("leaf",p+Vector3(0,4.55*s,0),Vector3(2.3,2.3,2.3)*s,seasonal_color(Color("#9aaa70"),true))
			"rock":
				add_shape("stone",p+Vector3(0,0.45*s,0),Vector3(1.7,1.25,1.5)*s,Color("#959e8d") if biome!="snow" else Color("#cbdcdd"),float(obj.variant)*1.4)
				add_shape("stone",p+Vector3(-0.21,0.81,0.08)*s,Vector3(1.03,0.22,0.82)*s,seasonal_color(Color("#7f8d59")) if biome!="snow" else Color("#e9f1ed"),float(obj.variant)*1.4)
			"flowers","bush":
				if obj.kind=="bush":add_shape("leaf",p+Vector3(0,0.35*s,0),Vector3(0.75,0.78,0.75)*s,seasonal_color(Color("#6b8550"),true))
				var flower_kind := "grass" if game.state.season_name()=="Winter" else "flower"
				add_shape(flower_kind if obj.kind=="flowers" else "fern",p,Vector3(0.65,0.80,0.65)*s,seasonal_color(Color("#779450"),true),float(obj.variant)*1.9)
			"water":
				if obj.variant==1:continue
				var pond := CylinderMesh.new()
				pond.top_radius=190*s*UNIT
				pond.bottom_radius=pond.top_radius
				pond.height=0.05
				pond.radial_segments=40
				var pond_node := mesh_at(contents,pond,p+Vector3(0,0.025,0),Color("#609da7"))
				pond_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				pond_node.material_override=nature_material(Color("#609da7"),3)
				for i in range(12):
					var angle := i*TAU/12
					add_shape("stone",p+Vector3(cos(angle)*(pond.top_radius+0.20),0.12,sin(angle)*(pond.top_radius+0.20)),Vector3(0.7,0.4,0.6),Color("#a2ad98"),angle)
					if i%3!=0:add_shape("reed",p+Vector3(cos(angle)*(pond.top_radius+0.40),0,sin(angle)*(pond.top_radius+0.40)),Vector3(0.5,0.70,0.5),Color("#8b975f"),angle)
			"den":
				if obj.get("variant",0)==1:
					for i in range(3):add_shape("stone",p+Vector3(-0.7+i*0.6,0.12,0.45)*s,Vector3(1.0,0.45,0.9)*s,Color("#949983"),float(i))
					add_shape("log",p+Vector3(0,0.22,0.55)*s,Vector3(0.36,0.36,2.0)*s,Color("#756247"),PI/2)
					add_shape("fern",p+Vector3(0.50,0,0.6)*s,Vector3.ONE*0.8,seasonal_color(Color("#788950"),true))
					continue
				for side in [-1,1]:
					add_shape("stone",p+Vector3(side*1.3,0.8,0),Vector3(1.7,2.0,2.1),Color("#999a7f"))
				add_shape("stone",p+Vector3(0,1.65,0),Vector3(3.2,1.15,2.25),Color("#a6a68a"))
				add_shape("box",p+Vector3(0,0.8,-0.2),Vector3(2.5,1.6,0.1),Color("#273d2d"))
			"landmark","discovery":
				build_nature_site(p,biome,obj.get("variant",0))
			"bridge":
				for i in range(14):add_shape("box",p+Vector3(-3.4+i*0.5,0.18,0),Vector3(0.45,0.3,3.1),Color("#b58d52"))
				for side in [-1,1]:
					add_shape("box",p+Vector3(0,0.65,side*1.5),Vector3(7.5,0.12,0.15),Color("#754e2e"))
			"ruin":
				add_shape("box",p+Vector3(0,0.85,0),Vector3(1.6,1.7,1.4),Color("#9eaa8b"))
			"waterfall":
				for side in [-1,1]:add_shape("sphere",p+Vector3(side*3.8,1.5,0),Vector3(4,5,4),Color("#a2aca0"))
				add_shape("box",p+Vector3(0,1.8,0),Vector3(5.8,3.6,0.2),Color("#83d7df"))
				for i in range(6):add_shape("sphere",p+Vector3(-2.2+i*0.85,0.2,0.6),Vector3(1.0,0.4,0.8),Color("#d4eeee"))
			"house":
				add_shape("box",p+Vector3(0,1.4,0),Vector3(4.7,2.8,4.2),Color("#d8c69a"))
				add_shape("cone",p+Vector3(0,3.3,0),Vector3(3.8,2.2,3.8),Color("#a65c35"))
				add_shape("box",p+Vector3(0,0.8,2.11),Vector3(0.9,1.6,0.06),Color("#654a2f"))
			"food":
				food_node=Node3D.new()
				contents.add_child(food_node)
				food_node.position=p
				food_nodes.append(food_node)
				sphere(food_node,Vector3(0,0.1,0),Vector3(0.9,0.4,0.7),Color("#bd8d6d"))
	for i in range(game.world.tracks.size()):
		var t: Dictionary=game.world.tracks[i]
		var n := MeshInstance3D.new()
		n.mesh=WolfForestMesh.get_mesh("track_deer" if t.species=="Reh" else "track_rabbit" if t.species=="Hase" else "track_wolf")
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.material_override=nature_material(Color("#e0c887"),6)
		contents.add_child(n)
		n.position=world_pos(t.p)+Vector3(0,0.025,0)
		var direction := Vector2.UP
		if i+1<game.world.tracks.size() and game.world.tracks[i+1].trail==t.trail:direction=t.p.direction_to(game.world.tracks[i+1].p)
		elif i>0 and game.world.tracks[i-1].trail==t.trail:direction=game.world.tracks[i-1].p.direction_to(t.p)
		n.rotation.y=atan2(-direction.x,-direction.y)
		track_nodes[t.id]=n
	for a in game.world.animals:
		var n := make_animal(a.kind)
		if a.get("young",false):n.scale*=0.73
		contents.add_child(n)
		animal_nodes.append(n)
	player_model=make_animal("wolf")
	contents.add_child(player_model)
	player_model.visible=follow_camera
	# Mountains are genuine volumes in the distant landscape.
	for i in range(16):
		var angle := i*TAU/16
		var p := Vector3(51.2+cos(angle)*100,8,51.2+sin(angle)*100)
		add_shape("ridge",p,Vector3(22,32+float(i%3)*5,17),Color("#899e96"),float(i)*0.7)
		add_shape("ridge",p+Vector3(0,12,0),Vector3(8,11,6),Color("#cedbd5"),float(i)*0.7)
	flush_batches()
	sync_camera()

func make_animal(kind: String) -> WolfAnimalModel:
	var n := WolfAnimalModel.new()
	n.build(kind)
	return n

func sync_camera() -> void:
	if built_season!=game.state.season_name():rebuild();return
	var bob := 0.0 if game.state.reduced_motion else sin(game.player_gait*2)*0.012*clampf(game.player_speed/120,0,1)
	if follow_camera:
		var distance := 3.6
		var backward := Vector2(sin(yaw),cos(yaw))*cos(pitch)
		# No expensive physics world is needed: the same spatial solid index
		# protects the orbit ray from trees, boulders and den walls.
		for step in range(1,11):
			var sample_distance := float(step)*0.36
			var sample: Vector2=game.state.pos+backward*sample_distance/UNIT
			if not Rect2(Vector2(10,10),WolfWorldData.SIZE-Vector2(20,20)).has_point(sample) or not game.collision_index.walkable(sample):
				distance=maxf(0.0,sample_distance-0.38)
				break
		var camera_point: Vector2=game.state.pos+backward*distance/UNIT
		var desired := world_pos(game.state.pos)+Vector3(backward.x*distance,0.63-sin(pitch)*distance,backward.y*distance)
		if distance<0.10:desired=world_pos(game.state.pos)+Vector3(0,2.0,0)
		elif distance<1.15:desired.y=maxf(desired.y,world_pos(game.state.pos).y+1.9)
		desired.y=maxf(desired.y,height_at(camera_point)+0.85)
		var dt: float=maxf(0.0,game.clock-camera_time)
		camera.position=desired if not camera_initialized or game.state.reduced_motion else camera.position.lerp(desired,1.0-exp(-dt*14.0))
		var actual_point := Vector2(camera.position.x,camera.position.z)/UNIT
		if not game.collision_index.walkable(actual_point):camera.position=desired;actual_point=camera_point
		camera.position.y=maxf(camera.position.y,height_at(actual_point)+0.85)
		var aim := world_pos(game.state.pos)+Vector3(0,0.66,0)
		camera.look_at(aim,Vector3(sin(yaw),0,cos(yaw)) if Vector2(camera.position.x-aim.x,camera.position.z-aim.z).length()<0.08 else Vector3.UP)
	else:
		camera.position=world_pos(game.state.pos)+Vector3(0,0.65+game.state.growth()*0.15+bob,0)
		camera.rotation=Vector3(pitch,yaw,0)
	camera_initialized=true
	camera_time=game.clock
	if player_model!=null:
		player_model.visible=follow_camera
		player_model.position=world_pos(game.state.pos)
		player_model.scale=Vector3.ONE*game.state.growth()
		var facing: Vector2=game.state.facing
		player_model.rotation.y=lerp_angle(player_model.rotation.y,atan2(-facing.x,-facing.y),0.18)
		player_model.animate(game.player_gait,game.player_speed,game.player_mood,game.clock,game.state.reduced_motion)
	for i in range(mini(animal_nodes.size(),game.world.animals.size())):
		var a: Dictionary=game.world.animals[i]
		animal_nodes[i].position=world_pos(a.p)
		var facing: Vector2=a.get("facing",Vector2.UP)
		animal_nodes[i].rotation.y=lerp_angle(animal_nodes[i].rotation.y,atan2(-facing.x,-facing.y),0.18)
		animal_nodes[i].animate(a.get("gait",0.0),a.get("speed",0.0),a.get("mood","lauschen"),game.clock+a.phase,game.state.reduced_motion)
	for id in track_nodes:
		var known: bool=game.state.found.has(id)
		track_nodes[id].visible=game.scent_time>0 or known
		if not track_nodes[id].has_meta("known") or track_nodes[id].get_meta("known")!=known:
			track_nodes[id].set_meta("known",known)
			track_nodes[id].material_override=nature_material(Color("#889767") if known else Color("#e0c887"),6)
	for n in food_nodes:n.visible=game.state.food_cooldown<=0
	lighting_timer+=1
	if lighting_timer>=12:
		lighting_timer=0
		update_lighting()
		for m in scene_materials:
			m.set_shader_parameter("wind_phase",game.clock)
			m.set_shader_parameter("animation_amount",0.0 if game.state.reduced_motion else 1.0)

func look(delta: Vector2) -> void:
	yaw-=delta.x*0.005
	pitch=clampf(pitch-delta.y*0.004,-0.88,-0.08) if follow_camera else clampf(pitch-delta.y*0.004,-1.25,0.65)

func set_follow_camera(enabled: bool) -> void:
	follow_camera=enabled
	camera_initialized=false
	pitch=-0.30 if enabled else -0.14
	if player_model!=null:sync_camera()

func enter() -> void:
	yaw=atan2(-game.state.facing.x,-game.state.facing.y)
	pitch=-0.30 if follow_camera else -0.14
	camera_initialized=false
	camera.current=true
	update_lighting()
	sync_camera()

func update_lighting() -> void:
	var daylight: float=game.state.sunlight()
	var weather: String=game.state.weather()
	var rain: bool=weather=="Regen"
	sun.light_energy=(0.12+daylight*0.82)*(0.68 if rain else 1.0)
	sun.light_color=Color("#f7d9a0").lerp(Color("#f6f3de"),daylight)
	sun.rotation_degrees.x=-20-daylight*55
	env.environment.ambient_light_energy=0.24+daylight*0.44
	env.environment.ambient_light_color=Color("#7c88a6").lerp(Color("#d2dcc6"),daylight)
	env.environment.fog_density=0.011 if weather=="Nebel" else 0.0065 if rain else 0.004
	env.environment.fog_light_color=Color("#3b485f").lerp(Color("#b6c5b8"),daylight)
	sky_material.set_shader_parameter("top_color",Color("#111f36").lerp(Color("#8297a7") if rain else Color("#6b9dbd"),daylight))
	sky_material.set_shader_parameter("horizon_color",Color("#354156").lerp(Color("#cbd5c4"),daylight))
	sky_material.set_shader_parameter("sun_direction",sun.global_transform.basis.z.normalized())
	sky_material.set_shader_parameter("daylight",clampf((daylight-.12)/.88,0,1))
	sky_material.set_shader_parameter("cloud_cover",0.84 if rain else 0.63 if weather=="Nebel" else 0.35)
	sky_material.set_shader_parameter("wind_phase",0.0 if game.state.reduced_motion else game.clock)

func nature_material(color: Color,surface: int) -> ShaderMaterial:
	var key := color.to_html()+str(surface)
	if material_cache.has(key):return material_cache[key]
	var m := ShaderMaterial.new()
	m.shader=nature_shader
	# Compatibility leaves source_color uniforms in their original space.
	# Match the instanced palette rather than producing fluorescent soil.
	m.set_shader_parameter("base_color",painted_colour(color) if RenderingServer.get_current_rendering_method()=="gl_compatibility" else color)
	m.set_shader_parameter("surface_kind",surface)
	m.set_shader_parameter("wind_phase",game.clock)
	m.set_shader_parameter("animation_amount",0.0 if game.state.reduced_motion else 1.0)
	scene_materials.append(m)
	material_cache[key]=m
	return m

func painted_colour(color: Color) -> Color:
	return color.srgb_to_linear().lerp(color,.22) if RenderingServer.get_current_rendering_method()=="gl_compatibility" else color.srgb_to_linear()
