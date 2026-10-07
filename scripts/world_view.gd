class_name WolfWorldView
extends Node3D

const UNIT := 0.045
var game: Node
var camera: Camera3D
var contents: Node3D
var animal_nodes: Array[Node3D] = []
var track_nodes: Dictionary = {}
var yaw := 0.0
var pitch := -0.17
var food_node: Node3D

func _ready() -> void:
	camera=Camera3D.new()
	camera.fov=78
	camera.near=0.06
	camera.far=120
	add_child(camera)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color("#b9d7cc")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("#b7c7bc")
	e.ambient_light_energy=0.8
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.environment=e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-35,0)
	sun.light_color=Color("#ffe4b2")
	sun.light_energy=1.15
	add_child(sun)

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.93
	return m

func mesh_at(parent: Node3D,mesh: Mesh,p: Vector3,color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh=mesh
	n.material_override=material(color)
	n.position=p
	parent.add_child(n)
	return n

func sphere(parent: Node3D,p: Vector3,scale_v: Vector3,color: Color) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radial_segments=10
	m.rings=5
	var n := mesh_at(parent,m,p,color)
	n.scale=scale_v
	return n

func box(parent: Node3D,p: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size=size
	return mesh_at(parent,m,p,color)

func cone(parent: Node3D,p: Vector3,radius: float,height: float,color: Color) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius=0
	m.bottom_radius=radius
	m.height=height
	m.radial_segments=9
	return mesh_at(parent,m,p,color)

func rebuild() -> void:
	if contents!=null:
		remove_child(contents)
		contents.queue_free()
	contents=Node3D.new()
	add_child(contents)
	animal_nodes.clear()
	track_nodes.clear()
	var ground := Color(WolfWorldData.REGIONS[game.state.region].ground)
	box(contents,Vector3(36,-0.12,36),Vector3(72,0.2,72),ground)
	box(contents,Vector3(36,0,36),Vector3(4.5,0.04,72),Color("#b6b292"))
	box(contents,Vector3(36,0,36),Vector3(72,0.04,4.5),Color("#b6b292"))
	if game.state.region==2:
		box(contents,Vector3(21.6,0.035,36),Vector3(6.75,0.07,72),Color("#6badae"))
		box(contents,Vector3(21.6,0.09,36),Vector3(8.1,0.12,4.2),Color("#b8b89b"))
	for obj in game.world.objects:
		var p := Vector3(obj.p.x*UNIT,0,obj.p.y*UNIT)
		var s: float=obj.scale
		match obj.kind:
			"tree":
				box(contents,p+Vector3(0,1.2*s,0),Vector3(0.3,2.4*s,0.3),Color("#76694b"))
				if obj.variant==0:
					for i in range(3):
						cone(contents,p+Vector3(0,(1.9+i*1.05)*s,0),(1.9-i*0.4)*s,2.6*s,Color("#3f7257").lightened(i*0.06))
				else:
					sphere(contents,p+Vector3(0,3*s,0),Vector3(2.7,2.6,2.7)*s,Color("#70905a"))
					sphere(contents,p+Vector3(-0.6,3.8,0.3)*s,Vector3(1.8,1.6,1.8)*s,Color("#91a96c"))
			"rock":
				sphere(contents,p+Vector3(0,0.5*s,0),Vector3(2.0,1.4,1.6)*s,Color("#a3afa5"))
			"water":
				if game.state.region!=2:
					var pond := CylinderMesh.new()
					pond.top_radius=120*UNIT
					pond.bottom_radius=120*UNIT
					pond.height=0.06
					pond.radial_segments=32
					mesh_at(contents,pond,p+Vector3(0,0.01,0),Color("#76b5b0"))
			"den":
				sphere(contents,p+Vector3(-2.0,1.0,0),Vector3(2.5,2.8,3.8),Color("#9a9a83"))
				sphere(contents,p+Vector3(2.0,1.0,0),Vector3(2.5,2.8,3.8),Color("#9a9a83"))
				sphere(contents,p+Vector3(0,2.3,0),Vector3(5.6,1.7,4.0),Color("#b4b099"))
				box(contents,p+Vector3(0,0.8,0.7),Vector3(2.5,1.6,0.1),Color("#263b37"))
			"landmark":
				box(contents,p+Vector3(0,0.95,0),Vector3(1.6,1.9,1.2),Color("#d5cfb1"))
				box(contents,p+Vector3(0,2,0),Vector3(1.9,0.3,1.5),Color("#b9b79d"))
			"food":
				food_node=Node3D.new()
				contents.add_child(food_node)
				food_node.position=p
				sphere(food_node,Vector3(0,0.15,0),Vector3(1.2,0.4,0.8),Color("#c09479"))
	for t in game.world.tracks:
		var n := Node3D.new()
		contents.add_child(n)
		n.position=Vector3(t.p.x*UNIT,0.045,t.p.y*UNIT)
		for side in [-1,1]:
			box(n,Vector3(side*0.35,0,side*0.18),Vector3(0.17,0.02,0.26),Color("#f5d389"))
			box(n,Vector3(side*0.35,0,-0.25+side*0.18),Vector3(0.24,0.02,0.1),Color("#f5d389"))
		track_nodes[t.id]=n
	for a in game.world.animals:
		var n := make_animal(a.kind)
		contents.add_child(n)
		animal_nodes.append(n)
	# Distant silhouettes surround the playable world.
	for i in range(14):
		var angle := float(i)*TAU/14
		var p := Vector3(36+cos(angle)*64,4,36+sin(angle)*64)
		cone(contents,p,13,20,Color("#8fa9a2"))
	sync_camera()

func make_animal(kind: String) -> Node3D:
	var n := Node3D.new()
	var c := Color("#acbdc3") if kind=="wolf" else Color("#baa180") if kind=="deer" else Color("#cfbca2")
	var s := 0.65 if kind=="rabbit" else 1.0
	sphere(n,Vector3(0,0.7,0),Vector3(0.7,0.9,1.4),c)
	sphere(n,Vector3(0,1.1,-0.65),Vector3(0.65,0.7,0.65),c.lightened(0.1))
	sphere(n,Vector3(0,0.98,-0.99),Vector3(0.4,0.28,0.5),Color("#e3dcc9"))
	sphere(n,Vector3(0,1.04,-1.22),Vector3(0.16,0.13,0.15),Color("#283c40"))
	for side in [-1,1]:
		cone(n,Vector3(side*0.22,1.53,-0.65),0.16,0.6 if kind=="rabbit" else 0.35,c.darkened(0.08))
		sphere(n,Vector3(side*0.26,1.18,-0.87),Vector3(0.1,0.1,0.1),Color("#283c40"))
		for z in [-0.4,0.45]:box(n,Vector3(side*0.24,0.27,z),Vector3(0.16,0.55,0.16),c.darkened(0.08))
	if kind=="deer":
		for side in [-1,1]:
			box(n,Vector3(side*0.22,1.7,-0.6),Vector3(0.07,0.65,0.07),Color("#6b6150"))
			box(n,Vector3(side*0.32,1.87,-0.6),Vector3(0.3,0.07,0.07),Color("#6b6150"))
	if kind=="wolf":sphere(n,Vector3(0,0.75,0.92),Vector3(0.25,0.3,0.9),c)
	n.scale=Vector3.ONE*s
	return n

func sync_camera() -> void:
	camera.position=Vector3(game.state.pos.x*UNIT,0.72,game.state.pos.y*UNIT)
	camera.rotation=Vector3(pitch,yaw,0)
	for i in range(animal_nodes.size()):
		var a: Dictionary=game.world.animals[i]
		animal_nodes[i].position=Vector3(a.p.x*UNIT,0,a.p.y*UNIT)
	for id in track_nodes:
		track_nodes[id].visible=game.scent_time>0 or game.state.found.has(id)
	if food_node!=null:food_node.visible=game.state.food_cooldown<=0

func look(delta: Vector2) -> void:
	yaw-=delta.x*0.005
	pitch=clampf(pitch-delta.y*0.004,-1.25,0.65)

func enter() -> void:
	yaw=atan2(-game.state.facing.x,-game.state.facing.y)
	pitch=-0.17
	camera.current=true
	sync_camera()
