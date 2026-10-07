class_name WolfAnimalModel
extends Node3D

# Articulated, vertex-coloured mesh: the silhouette and joints are authored
# here, not assembled from scaled spheres. Shared meshes/materials stay small.
static var material_cache: Dictionary = {}
var torso: Node3D
var neck: Node3D
var head: Node3D
var tail: Node3D
var ears: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var kind := "wolf"
var phase := 0.0
var body_scale := 1.0

static func mat() -> StandardMaterial3D:
	if not material_cache.has("fur"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo=true
		m.roughness=0.92
		m.cull_mode=BaseMaterial3D.CULL_DISABLED
		material_cache.fur=m
	return material_cache.fur

func piece(parent: Node3D,points: Array,radii: Array,color: Color,segments: int=12) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(points.size()-1):
		for side in range(segments):
			for coord in [Vector2i(row,side),Vector2i(row+1,side),Vector2i(row+1,side+1),Vector2i(row,side),Vector2i(row+1,side+1),Vector2i(row,side+1)]:
				var a := float(coord.y)/segments*TAU
				var r: Vector2=radii[coord.x]
				var previous := maxi(0,coord.x-1)
				var next := mini(points.size()-1,coord.x+1)
				var tangent: Vector3=(points[next]-points[previous]).normalized()
				var axis := Vector3.RIGHT if absf(tangent.dot(Vector3.RIGHT))<0.8 else Vector3.UP
				var u := (axis-tangent*axis.dot(tangent)).normalized()
				var v := tangent.cross(u).normalized()
				var p: Vector3=points[coord.x]+u*cos(a)*r.x+v*sin(a)*r.y
				# Cream underside, darker dorsal fur, with gentle facets.
				var shade := 0.07*sin(a*3.0+row*1.7)
				var c := color.lightened(shade) if shade>0 else color.darkened(-shade)
				if sin(a)<-0.45 and kind in ["wolf","fox"]:c=c.lerp(Color("#e4d8ba"),0.68)
				tool.set_color(c)
				tool.add_vertex(p)
	tool.generate_normals()
	var n := MeshInstance3D.new()
	n.mesh=tool.commit()
	n.material_override=mat()
	parent.add_child(n)
	return n

func ellipsoid(parent: Node3D,p: Vector3,scale_value: Vector3,color: Color) -> MeshInstance3D:
	var centers: Array=[]
	var widths: Array=[]
	for i in range(9):
		var t := float(i)/8.0*PI
		centers.append(p+Vector3(0,0,-cos(t)*scale_value.z))
		widths.append(Vector2(sin(t)*scale_value.x,sin(t)*scale_value.y))
	return piece(parent,centers,widths,color)

func pivot(parent: Node3D,p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position=p
	parent.add_child(n)
	return n

func build(species: String,young: bool=false) -> void:
	kind=species
	var fur := Color("#85867b") if kind=="wolf" else Color("#bf7740") if kind=="fox" else Color("#ae8c5c") if kind=="deer" else Color("#ab9780")
	body_scale=0.48 if kind=="rabbit" else 0.82 if kind=="fox" else 1.14 if kind=="deer" else 1.0
	if young:body_scale*=0.73
	scale=Vector3.ONE*body_scale
	torso=pivot(self,Vector3(0,0.76,0))
	piece(torso,[Vector3(0,0,-0.69),Vector3(0,0.02,-0.46),Vector3(0,0.01,-0.05),Vector3(0,-0.04,0.40),Vector3(0,-0.04,0.66)],[Vector2(0.05,0.06),Vector2(0.31,0.38),Vector2(0.34,0.33),Vector2(0.29,0.28),Vector2(0.06,0.07)],fur,16)
	# Shoulder ruff and natural chest contour.
	ellipsoid(torso,Vector3(0,0.10,-0.43),Vector3(0.34,0.38,0.39),fur.lightened(0.07))
	neck=pivot(torso,Vector3(0,0.18,-0.50))
	ellipsoid(neck,Vector3(0,0.10,-0.12),Vector3(0.24,0.32,0.27),fur)
	head=pivot(neck,Vector3(0,0.25,-0.26))
	ellipsoid(head,Vector3.ZERO,Vector3(0.275,0.245,0.29),fur.lightened(0.05))
	# Tapered, long muzzle is distinct from the skull.
	piece(head,[Vector3(0,-0.06,-0.15),Vector3(0,-0.09,-0.34),Vector3(0,-0.11,-0.52),Vector3(0,-0.11,-0.55)],[Vector2(0.18,0.13),Vector2(0.145,0.09),Vector2(0.09,0.065),Vector2(0.065,0.035)],Color("#e1d7ba"))
	ellipsoid(head,Vector3(0,-0.10,-0.548),Vector3(0.080,0.052,0.045),Color("#25352d"))
	for side in [-1,1]:
		ellipsoid(head,Vector3(side*0.23,0.02,-0.175),Vector3(0.047,0.047,0.037),Color("#cda550"))
		ellipsoid(head,Vector3(side*0.24,0.021,-0.198),Vector3(0.018,0.034,0.014),Color("#1f2b25"))
		ellipsoid(head,Vector3(side*0.242,0.035,-0.206),Vector3(0.009,0.009,0.009),Color("#f8f1d3"))
		var ear := pivot(head,Vector3(side*0.19,0.17,0.015))
		ears.append(ear)
		var length := 0.62 if kind=="rabbit" else 0.27
		piece(ear,[Vector3(0,0,0.04),Vector3(0,length*0.4,0.035),Vector3(side*0.025,length,0)],[Vector2(0.115,0.055),Vector2(0.080,0.036),Vector2(0,0)],fur)
		piece(ear,[Vector3(0,0.015,-0.025),Vector3(0,length*0.4,-0.024),Vector3(side*0.018,length*0.86,-0.013)],[Vector2(0.065,0.012),Vector2(0.055,0.007),Vector2.ZERO],Color("#cead9b"))
	for i in range(4):
		var side := -1.0 if i%2==0 else 1.0
		var front := i<2
		var z := -0.42 if front else 0.43
		var limb := pivot(torso,Vector3(side*0.225,-0.16,z))
		legs.append(limb)
		var knee := pivot(limb,Vector3(0,-0.31,0.03 if front else -0.055))
		knees.append(knee)
		piece(limb,[Vector3(0,0,0),Vector3(0,-0.16,0.02),Vector3(0,-0.32,0.02)],[Vector2(0.105,0.075),Vector2(0.085,0.070),Vector2(0.065,0.055)],fur,10)
		piece(knee,[Vector3(0,0,0.01),Vector3(0,-0.25,-0.025),Vector3(0,-0.36,-0.06)],[Vector2(0.068,0.05),Vector2(0.05,0.042),Vector2(0.058,0.045)],fur,10)
		ellipsoid(knee,Vector3(0,-0.36,-0.075),Vector3(0.095,0.06,0.15),Color("#c7baa0") if kind in ["wolf","fox"] else fur)
		for toe in [-1,0,1]:ellipsoid(knee,Vector3(toe*0.045,-0.366,-0.17),Vector3(0.026,0.022,0.042),Color("#ad9f86"))
	tail=pivot(torso,Vector3(0,-0.01,0.56))
	if kind=="rabbit":ellipsoid(tail,Vector3(0,0,0.07),Vector3(0.13,0.14,0.14),Color("#e2d8c5"))
	else:
		piece(tail,[Vector3.ZERO,Vector3(0,-0.04,0.22),Vector3(0,-0.14,0.46),Vector3(0,-0.30,0.70),Vector3(0,-0.35,0.79)],[Vector2(0.10,0.10),Vector2(0.15,0.15),Vector2(0.15,0.14),Vector2(0.085,0.07),Vector2.ZERO],fur)
		if kind in ["wolf","fox"]:ellipsoid(tail,Vector3(0,-0.27,0.64),Vector3(0.11,0.10,0.16),Color("#ded5bf"))
	if kind=="deer":
		for side in [-1,1]:
			piece(head,[Vector3(side*0.14,0.17,0.01),Vector3(side*0.21,0.40,0.0),Vector3(side*0.32,0.72,-0.10)],[Vector2(0.038,0.038),Vector2(0.03,0.03),Vector2(0.008,0.008)],Color("#796244"),7)
			piece(head,[Vector3(side*0.22,0.39,0),Vector3(side*0.39,0.53,-0.17),Vector3(side*0.49,0.64,-0.19)],[Vector2(0.026,0.026),Vector2(0.020,0.020),Vector2(0.004,0.004)],Color("#796244"),7)
		for i in range(9):ellipsoid(torso,Vector3((-1 if i%2==0 else 1)*0.31,0.10+sin(i*2)*0.1,-0.25+float(i/2)*0.15),Vector3(0.012,0.032,0.03),Color("#e1d2ab"))

func animate(gait: float,speed: float,mood: String,time: float,reduced: bool=false) -> void:
	if torso==null:return
	var movement := clampf(speed/65.0,0,1)
	if reduced:movement*=0.3
	torso.position.y=0.76+sin(gait*2)*0.018*movement
	torso.rotation.z=sin(gait)*0.028*movement
	torso.rotation.x=0
	for i in range(legs.size()):
		var wave := sin(gait+(0 if i in [0,3] else PI))
		legs[i].rotation.x=wave*0.44*movement
		knees[i].rotation.x=maxf(0,-wave)*0.50*movement
	head.rotation=Vector3(-0.09+sin(time*1.7)*0.025,0,0)
	tail.rotation=Vector3(sin(time*1.7)*0.05,sin(time*2.2)*0.12,0)
	for i in range(ears.size()):ears[i].rotation.z=sin(time*0.9+i*2)*0.06
	if movement<0.1:
		if mood in ["grasen","schnüffeln"]:neck.rotation.x=0.55+sin(time*2)*0.05
		elif mood=="heulen":neck.rotation.x=-0.5;head.rotation.x=-0.45
		elif mood=="ruhen":
			torso.position.y=0.40+sin(time*1.6)*0.012
			for limb in legs:limb.rotation.x=1.0
			neck.rotation.x=0.20
		elif mood=="spielen":
			torso.rotation.x=-0.13
			tail.rotation.y=sin(time*6)*0.35
		else:neck.rotation.x=0;head.rotation.y=sin(time*0.7+phase)*0.17
	else:neck.rotation.x=0
