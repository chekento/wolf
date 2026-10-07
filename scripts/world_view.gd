class_name WolfWorldView
extends Node3D

const UNIT := 0.032
var game: Node
var region_built := -1
var camera: Camera3D
var contents: Node3D
var animal_nodes: Array[WolfAnimalModel]=[]
var sky_material: ProceduralSkyMaterial
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

func _ready() -> void:
	camera=Camera3D.new()
	camera.fov=76
	camera.near=0.05
	camera.far=175
	add_child(camera)
	env=WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode=Environment.BG_SKY
	var sky := Sky.new()
	sky_material=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color("#4f9ee0")
	sky_material.sky_horizon_color=Color("#dae9db")
	sky_material.ground_horizon_color=Color("#dae9db")
	sky_material.ground_bottom_color=Color("#70895f")
	sky.sky_material=sky_material
	e.sky=sky
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("#d1dfd0")
	e.ambient_light_energy=0.6
	e.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.environment=e
	add_child(env)
	sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-50,-30,0)
	sun.light_color=Color("#fff0ca")
	sun.light_energy=0.8
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=40
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
	var key := kind+color.to_html()
	if not batches.has(key):batches[key]={"kind":kind,"color":color,"transforms":[]}
	var basis := Basis(Vector3.UP,rotation).scaled(dimensions)
	batches[key].transforms.append(Transform3D(basis,p))

func flush_batches() -> void:
	for key in batches:
		var batch: Dictionary=batches[key]
		var mm := MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=WolfForestMesh.get_mesh(batch.kind) if batch.kind in ["pine","leaf","trunk","stone"] else sphere_mesh() if batch.kind=="sphere" else cone_mesh() if batch.kind=="cone" else BoxMesh.new()
		# A default BoxMesh has size 1×1×1.
		mm.instance_count=batch.transforms.size()
		for i in range(batch.transforms.size()):mm.set_instance_transform(i,batch.transforms[i])
		var n := MultiMeshInstance3D.new()
		n.multimesh=mm
		n.material_override=nature_material(batch.color,1 if batch.kind in ["pine","leaf"] else 2 if batch.kind=="trunk" else 0)
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

func build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ground := Color(WolfWorldData.REGIONS[game.state.region].ground)
	for y in range(40):
		for x in range(40):
			for offset in [Vector2(0,0),Vector2(0,1),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(1,0)]:
				var p: Vector2 = (Vector2(x,y)+offset)*80
				st.set_color(ground.lightened(0.06*sin(p.x*0.01+p.y*0.016)))
				st.add_vertex(world_pos(p))
	st.generate_normals()
	var n := MeshInstance3D.new()
	n.mesh=st.commit()
	var m := nature_material(ground,0)
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
		path_mesh.material_override=nature_material(Color("#bcb280") if WolfWorldData.REGIONS[game.state.region].biome!="snow" else Color("#edf4ef"),0)
		contents.add_child(path_mesh)

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
	food_node=null
	var biome: String=WolfWorldData.REGIONS[game.state.region].biome
	build_ground()
	if biome=="river":
		for y in range(0,3200,50):
			add_shape("box",Vector3(WolfWorldData.river_x(y)*UNIT,-0.06,y*UNIT),Vector3(6.0,0.12,1.7),Color("#52b9c9"))
	if biome=="coast":
		add_shape("box",Vector3(6.7,-0.04,51.2),Vector3(14.2,0.07,102.4),Color("#46afc2"))
		add_shape("box",Vector3(7.1,0.01,51.2),Vector3(14.7,0.06,4.2),Color("#d2c38d"))
	for obj in game.world.objects:
		var p := world_pos(obj.p)
		var s: float=obj.scale
		match obj.kind:
			"tree":
				var trunk := Color("#8e693e") if obj.variant!=2 else Color("#e0debd")
				add_shape("trunk",p+Vector3(0,1.7*s,0),Vector3(0.55,3.4*s,0.55),trunk)
				if obj.variant==0:
					for i in range(5):
						var color := Color("#386a37").lightened(i*0.055)
						add_shape("pine",p+Vector3(0,(2.0+i*0.8)*s,0),Vector3((1.8-i*0.25)*s,2.1*s,(1.8-i*0.25)*s),color,float(i)*0.6)
						if biome=="snow":add_shape("cone",p+Vector3(0,(2.4+i*0.8)*s,0),Vector3((1.5-i*0.24)*s,1.1*s,(1.5-i*0.24)*s),Color("#e1f0ef"))
				else:
					for i in range(5):
						var angle := i*TAU/5
						add_shape("leaf",p+Vector3(cos(angle)*1.2,3.7+float(i%2)*0.65,sin(angle)*1.2)*s,Vector3(2.4,2.4,2.4)*s,Color("#709e3f").lightened(i*0.025))
					add_shape("leaf",p+Vector3(0,4.6*s,0),Vector3(2.5,2.4,2.5)*s,Color("#a5b849"))
			"rock":
				add_shape("stone",p+Vector3(0,0.45*s,0),Vector3(2.0,1.45,1.7)*s,Color("#a4afa0") if biome!="snow" else Color("#d9e9ec"))
				add_shape("sphere",p+Vector3(-0.3,0.85,0.1)*s,Vector3(1.2,0.3,0.9)*s,Color("#829345") if biome!="snow" else Color("#f4faf8"))
			"flowers","bush":
				add_shape("sphere",p+Vector3(0,0.28,0),Vector3(1.0,0.8,1.0)*s,Color("#5e8e30"))
				for i in range(3):
					add_shape("sphere",p+Vector3(sin(i*2)*0.3,0.7,cos(i*2)*0.3)*s,Vector3(0.17,0.12,0.17),Color("#f3d751") if i%2==0 else Color("#f7efce"))
			"water":
				if obj.variant==1:continue
				var pond := CylinderMesh.new()
				pond.top_radius=190*s*UNIT
				pond.bottom_radius=pond.top_radius
				pond.height=0.05
				pond.radial_segments=40
				var pond_node := mesh_at(contents,pond,p+Vector3(0,0.025,0),Color("#4eb7c9"))
				pond_node.material_override=nature_material(Color("#4eb7c9"),3)
				for i in range(12):
					var angle := i*TAU/12
					add_shape("sphere",p+Vector3(cos(angle)*(pond.top_radius+0.4),0.2,sin(angle)*(pond.top_radius+0.4)),Vector3(0.8,0.55,0.7),Color("#a7b39b"))
			"den":
				for side in [-1,1]:
					add_shape("sphere",p+Vector3(side*1.8,0.8,0),Vector3(2.4,2.9,3.0),Color("#a29e7f"))
				add_shape("sphere",p+Vector3(0,2.0,0),Vector3(5.1,1.8,3.2),Color("#b2ad91"))
				add_shape("box",p+Vector3(0,0.8,-0.2),Vector3(2.5,1.6,0.1),Color("#273d2d"))
			"landmark","discovery":
				add_shape("sphere",p+Vector3(0,0.6,0),Vector3(1.7,1.8,1.2),Color("#b9b28b"))
				add_shape("sphere",p+Vector3(0,1.35,-0.2),Vector3(0.28,0.28,0.28),Color("#e8cf7e"))
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
				sphere(food_node,Vector3(0,0.1,0),Vector3(0.9,0.4,0.7),Color("#bd8d6d"))
	for t in game.world.tracks:
		var n := Node3D.new()
		contents.add_child(n)
		n.position=world_pos(t.p)+Vector3(0,0.04,0)
		for side in [-1,1]:
			box(n,Vector3(side*0.25,0,side*0.14),Vector3(0.18,0.012,0.18),Color("#f5d372"))
			for toe in [-1,0,1]:box(n,Vector3(side*0.25+toe*0.07,0,-0.16+side*0.14),Vector3(0.05,0.012,0.06),Color("#f5d372"))
		track_nodes[t.id]=n
	for a in game.world.animals:
		var n := make_animal(a.kind)
		if a.get("young",false):n.scale*=0.73
		contents.add_child(n)
		animal_nodes.append(n)
	# Mountains are genuine volumes in the distant landscape.
	for i in range(16):
		var angle := i*TAU/16
		var p := Vector3(51.2+cos(angle)*100,8,51.2+sin(angle)*100)
		add_shape("cone",p,Vector3(18,36,18),Color("#8ca79b"))
		add_shape("cone",p+Vector3(0,13,0),Vector3(7,12,7),Color("#dae6df"))
	flush_batches()
	sync_camera()

func make_animal(kind: String) -> WolfAnimalModel:
	var n := WolfAnimalModel.new()
	n.build(kind)
	return n

func sync_camera() -> void:
	var bob := 0.0 if game.state.reduced_motion else sin(game.player_gait*2)*0.012*clampf(game.player_speed/120,0,1)
	camera.position=world_pos(game.state.pos)+Vector3(0,0.65+game.state.growth()*0.15+bob,0)
	camera.rotation=Vector3(pitch,yaw,0)
	for i in range(mini(animal_nodes.size(),game.world.animals.size())):
		var a: Dictionary=game.world.animals[i]
		animal_nodes[i].position=world_pos(a.p)
		var facing: Vector2=a.get("facing",Vector2.UP)
		animal_nodes[i].rotation.y=lerp_angle(animal_nodes[i].rotation.y,atan2(-facing.x,-facing.y),0.18)
		animal_nodes[i].animate(a.get("gait",0.0),a.get("speed",0.0),a.get("mood","lauschen"),game.clock+a.phase,game.state.reduced_motion)
	for id in track_nodes:track_nodes[id].visible=game.scent_time>0 or game.state.found.has(id)
	if food_node!=null:food_node.visible=game.state.food_cooldown<=0
	lighting_timer+=1
	if lighting_timer>=12:
		lighting_timer=0
		update_lighting()
		for m in scene_materials:
			m.set_shader_parameter("wind_phase",game.clock)
			m.set_shader_parameter("animation_amount",0.0 if game.state.reduced_motion else 1.0)

func look(delta: Vector2) -> void:
	yaw-=delta.x*0.005
	pitch=clampf(pitch-delta.y*0.004,-1.25,0.65)

func enter() -> void:
	yaw=atan2(-game.state.facing.x,-game.state.facing.y)
	pitch=-0.14
	camera.current=true
	update_lighting()
	sync_camera()

func update_lighting() -> void:
	var daylight: float=game.state.sunlight()
	var rain: bool=game.state.weather()=="Regen"
	sun.light_energy=0.15+daylight*0.9
	sun.light_color=Color("#ffe5ac").lerp(Color("#e9f5ff"),daylight)
	sun.rotation_degrees.x=-20-daylight*55
	env.environment.ambient_light_energy=0.22+daylight*0.5
	env.environment.ambient_light_color=Color("#6879a9").lerp(Color("#d1dfc3"),daylight)
	sky_material.sky_top_color=Color("#10213d").lerp(Color("#6d9ec7") if rain else Color("#519bd5"),daylight)
	sky_material.sky_horizon_color=Color("#394463").lerp(Color("#dce8d6"),daylight)

func nature_material(color: Color,surface: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader=nature_shader
	m.set_shader_parameter("base_color",color)
	m.set_shader_parameter("surface_kind",surface)
	m.set_shader_parameter("wind_phase",game.clock)
	m.set_shader_parameter("animation_amount",0.0 if game.state.reduced_motion else 1.0)
	scene_materials.append(m)
	return m
