class_name WolfAnimalModel
extends Node3D

# Original articulated wildlife. Meshes are shared by species and merged per
# joint, so eyes, fur markings and toes do not each cost a separate draw call.
static var material_cache: Dictionary = {}
static var mesh_cache: Dictionary = {}
var torso: Node3D
var neck: Node3D
var head: Node3D
var jaw: Node3D
var tail: Node3D
var ears: Array[Node3D] = []
var eyes: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var kind := "wolf"
var phase := 0.0
var body_scale := 1.0
var body_height := 0.79
var last_time := -1.0
var _surfaces: Dictionary = {}
var _parents: Dictionary = {}

static func mat() -> StandardMaterial3D:
	if not material_cache.has("fur"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo=true
		m.vertex_color_is_srgb=true
		m.roughness=0.92
		m.cull_mode=BaseMaterial3D.CULL_DISABLED
		material_cache.fur=m
	return material_cache.fur

func _surface(parent: Node3D) -> SurfaceTool:
	var key := kind+"/"+str(parent.name)
	_parents[key]=parent
	if mesh_cache.has(key):return null
	if not _surfaces.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_surfaces[key]=st
	return _surfaces[key]

func piece(parent: Node3D,points: Array,radii: Array,color: Color,segments: int=12,dorsal: bool=false) -> void:
	var st := _surface(parent)
	if st==null:return
	for row in range(points.size()-1):
		for side in range(segments):
			for coord in [Vector2i(row,side),Vector2i(row+1,side),Vector2i(row+1,side+1),Vector2i(row,side),Vector2i(row+1,side+1),Vector2i(row,side+1)]:
				var angle := float(coord.y)/segments*TAU
				var r: Vector2=radii[coord.x]
				var before := maxi(0,coord.x-1)
				var after := mini(points.size()-1,coord.x+1)
				var tangent: Vector3=(points[after]-points[before]).normalized()
				var axis := Vector3.RIGHT if absf(tangent.dot(Vector3.RIGHT))<0.8 else Vector3.UP
				var u := (axis-tangent*axis.dot(tangent)).normalized()
				var v := tangent.cross(u).normalized()
				var radial := u*cos(angle)*r.x+v*sin(angle)*r.y
				var p: Vector3=points[coord.x]+radial
				var normal := (u*cos(angle)/maxf(r.x,0.018)+v*sin(angle)/maxf(r.y,0.018)).normalized()
				if r.length()<0.015:normal=-tangent if coord.x==0 else tangent
				var c := color
				if dorsal:
					c=c.lerp(color.darkened(0.20),smoothstep(-0.025,0.20,radial.y)*0.8)
					if kind in ["wolf","fox"]:c=c.lerp(Color("#cfc9b6"),smoothstep(0.0,0.18,-radial.y)*0.5)
				st.set_color(c.srgb_to_linear().lerp(c,.22) if RenderingServer.get_current_rendering_method()=="gl_compatibility" else c)
				st.set_normal(normal)
				st.add_vertex(p)

func ellipsoid(parent: Node3D,p: Vector3,size_value: Vector3,color: Color,segments: int=12,dorsal: bool=false) -> void:
	var centers: Array=[]
	var widths: Array=[]
	for i in range(9):
		var t := float(i)/8.0*PI
		centers.append(p+Vector3(0,0,-cos(t)*size_value.z))
		widths.append(Vector2(sin(t)*size_value.x,sin(t)*size_value.y))
	piece(parent,centers,widths,color,segments,dorsal)

func pivot(parent: Node3D,p: Vector3,label: String) -> Node3D:
	var n := Node3D.new()
	n.name=label
	n.position=p
	parent.add_child(n)
	return n

func _finish_surfaces() -> void:
	for key in _parents:
		if not mesh_cache.has(key):
			var st: SurfaceTool=_surfaces[key]
			st.index()
			mesh_cache[key]=st.commit()
		var n := MeshInstance3D.new()
		n.mesh=mesh_cache[key]
		n.material_override=mat()
		_parents[key].add_child(n)
	_surfaces.clear()
	_parents.clear()

func build(species: String,young: bool=false) -> void:
	kind=species
	var fox := kind=="fox"
	var deer := kind=="deer"
	var rabbit := kind=="rabbit"
	var fur := Color("#8e9084") if kind=="wolf" else Color("#b8783f") if fox else Color("#a88356") if deer else Color("#9c8d77")
	var cream := Color("#d6d1bd") if not fox else Color("#e4d9bf")
	body_scale=0.70 if rabbit else 0.82 if fox else 1.08 if deer else 1.0
	if young:body_scale*=0.73
	scale=Vector3.ONE*body_scale
	body_height=0.47 if rabbit else 0.715 if fox else 1.12 if deer else 0.79
	torso=pivot(self,Vector3(0,body_height,0),"Torso")
	if rabbit:
		ellipsoid(torso,Vector3(0,-0.01,0.09),Vector3(0.265,0.30,0.43),fur,16,true)
		ellipsoid(torso,Vector3(0,-0.055,-0.24),Vector3(0.19,0.24,0.20),cream)
	else:
		var width := 0.225 if deer or fox else 0.30
		var depth := 0.34 if deer else 0.26 if fox else 0.34
		piece(torso,[Vector3(0,0,-0.70),Vector3(0,0.02,-0.48),Vector3(0,0.035,-0.13),Vector3(0,-0.035,0.29),Vector3(0,-0.07,0.57),Vector3(0,-0.07,0.66)],[Vector2(0.035,0.07),Vector2(width*0.88,depth),Vector2(width,depth*0.94),Vector2(width*0.87,depth*0.75),Vector2(width*0.79,depth*0.77),Vector2(0.025,0.04)],fur,16,true)
		ellipsoid(torso,Vector3(0,-0.02,-0.46),Vector3(width*0.93,depth*1.06,0.22),fur,14,true)
		ellipsoid(torso,Vector3(0,-0.16,-0.49),Vector3(width*0.69,0.23,0.17),cream if not deer else fur.lightened(0.08))
		if not deer:
			for side in [-1,1]:
				piece(torso,[Vector3(side*width*0.6,0.07,-0.52),Vector3(side*width*1.01,-0.10,-0.35),Vector3(side*width*1.10,-0.24,-0.25)],[Vector2(0.13,0.10),Vector2(0.10,0.10),Vector2.ZERO],fur.lightened(0.055))
	neck=pivot(torso,Vector3(0,0.11 if not rabbit else 0.08,-0.48 if not rabbit else -0.25),"Neck")
	if deer:
		piece(neck,[Vector3(0,-0.04,0.04),Vector3(0,0.26,-0.12),Vector3(0,0.52,-0.16)],[Vector2(0.17,0.20),Vector2(0.15,0.16),Vector2(0.11,0.11)],fur,14,true)
		head=pivot(neck,Vector3(0,0.53,-0.16),"Head")
	elif rabbit:
		ellipsoid(neck,Vector3(0,0.04,-0.03),Vector3(0.16,0.19,0.18),fur)
		head=pivot(neck,Vector3(0,0.13,-0.11),"Head")
	else:
		ellipsoid(neck,Vector3(0,0.09,-0.05),Vector3(0.205 if fox else 0.25,0.265,0.24),fur,14,true)
		piece(neck,[Vector3(0,0.02,-0.13),Vector3(0,-0.14,-0.20),Vector3(0,-0.29,-0.09)],[Vector2(0.16,0.15),Vector2(0.13,0.10),Vector2.ZERO],cream)
		head=pivot(neck,Vector3(0,0.24,-0.24),"Head")
	var skull := Vector3(0.155,0.16,0.24) if deer else Vector3(0.19,0.17,0.21) if rabbit else Vector3(0.205,0.19,0.25) if fox else Vector3(0.24,0.215,0.28)
	ellipsoid(head,Vector3(0,0.005,0.035),skull,fur,16,true)
	var muzzle_length := 0.27 if rabbit else 0.45 if deer else 0.55 if fox else 0.56
	var muzzle_width := 0.095 if deer else 0.105 if rabbit else 0.12 if fox else 0.145
	piece(head,[Vector3(0,-0.07,-0.11),Vector3(0,-0.095,-muzzle_length*0.62),Vector3(0,-0.11,-muzzle_length*0.94),Vector3(0,-0.11,-muzzle_length)],[Vector2(muzzle_width,0.10),Vector2(muzzle_width*0.87,0.085),Vector2(muzzle_width*0.51,0.047),Vector2(0.012,0.027)],cream if not deer else fur.darkened(0.12),14)
	ellipsoid(head,Vector3(0,-0.10,-muzzle_length),Vector3(0.068 if not rabbit else 0.027,0.041,0.028),Color("#29332c"))
	jaw=pivot(head,Vector3(0,-0.145,-0.12),"Jaw")
	piece(jaw,[Vector3(0,0,0),Vector3(0,-0.018,-muzzle_length*0.45),Vector3(0,-0.006,-muzzle_length*0.83)],[Vector2(muzzle_width*0.90,0.042),Vector2(muzzle_width*0.70,0.034),Vector2(0.03,0.014)],cream.darkened(0.04))
	for side in [-1,1]:
		if not deer and not rabbit:
			piece(head,[Vector3(side*skull.x*0.64,-0.025,-0.02),Vector3(side*skull.x*1.15,-0.12,0.07),Vector3(side*skull.x*0.88,-0.17,0.15)],[Vector2(0.11,0.07),Vector2(0.105,0.07),Vector2.ZERO],cream)
		var eye := pivot(head,Vector3(side*skull.x*0.94,0.018,-0.13 if not rabbit else -0.07),"Eye"+str(side))
		eyes.append(eye)
		ellipsoid(eye,Vector3.ZERO,Vector3(0.022,0.037,0.037),Color("#28332b"))
		ellipsoid(eye,Vector3(side*0.009,0,-0.007),Vector3(0.015,0.026,0.023),Color("#bd954a") if not deer and not rabbit else Color("#573f2a"))
		ellipsoid(eye,Vector3(side*0.021,0,-0.014),Vector3(0.010,0.022,0.009),Color("#202923"))
		ellipsoid(eye,Vector3(side*0.025,0.009,-0.020),Vector3(0.005,0.007,0.005),Color("#f7f0d9"),8)
		ellipsoid(head,Vector3(side*skull.x*0.88,0.082,-0.14),Vector3(0.037,0.017,0.05),fur.darkened(0.18))
		var ear := pivot(head,Vector3(side*0.105 if deer else side*0.13 if rabbit else side*0.17,0.13 if deer else 0.15,0.08),"Ear"+str(side))
		ears.append(ear)
		var tip := Vector3(side*0.17,0.25,0.02) if deer else Vector3(side*0.045,0.59,0.07) if rabbit else Vector3(side*0.023,0.32 if fox else 0.285,0.008)
		piece(ear,[Vector3.ZERO,tip*0.42,tip],[Vector2(0.09,0.047),Vector2(0.072,0.033),Vector2.ZERO],fur,12)
		piece(ear,[Vector3(0,0.017,-0.04),tip*0.40+Vector3(0,0,-0.034),tip*0.86+Vector3(0,0,-0.008)],[Vector2(0.055,0.009),Vector2(0.047,0.008),Vector2.ZERO],Color("#b8a899"),10)
	for i in range(4):
		var side := -1.0 if i%2==0 else 1.0
		var front := i<2
		var z := (-0.36 if front else 0.29) if rabbit else -0.43 if front else 0.43
		var upper := 0.19 if rabbit else 0.34 if deer else 0.25 if fox else 0.27
		var lower := 0.20 if rabbit else 0.59 if deer else 0.31 if fox else 0.37
		var thickness := 0.055 if deer else 0.075 if fox else 0.085
		var root_y := -0.04 if rabbit else -0.13 if deer else -0.11
		var limb := pivot(torso,Vector3(side*(0.17 if rabbit else 0.19 if deer or fox else 0.215),root_y,z),"Leg"+str(i))
		legs.append(limb)
		var bend := 0.035 if front else -0.09
		var knee := pivot(limb,Vector3(0,-upper,bend),"Knee"+str(i))
		knees.append(knee)
		piece(limb,[Vector3.ZERO,Vector3(0,-upper*0.5,bend*0.45),Vector3(0,-upper,bend)],[Vector2(thickness*1.18,thickness),Vector2(thickness,thickness*0.75),Vector2(thickness*0.71,thickness*0.68)],fur,10)
		if not front:ellipsoid(limb,Vector3(0,-upper*0.2,0.018),Vector3(thickness*1.55,upper*0.72,0.13 if not rabbit else 0.21),fur,12,true)
		piece(knee,[Vector3.ZERO,Vector3(0,-lower*0.52,0.04 if not front else -0.025),Vector3(0,-lower,-0.045)],[Vector2(thickness*0.72,thickness*0.65),Vector2(thickness*0.5,thickness*0.44),Vector2(thickness*0.62,thickness*0.50)],fur if not fox else Color("#514539"),10)
		var foot_size := Vector3(0.065,0.047,0.089) if deer else Vector3(0.08,0.051,0.21) if rabbit and not front else Vector3(0.085,0.045,0.125)
		ellipsoid(knee,Vector3(0,-lower,-0.082),foot_size,Color("#554a3d") if deer else cream.darkened(0.13),12)
		if deer:
			piece(knee,[Vector3(0,-lower+0.003,-0.13),Vector3(0,-lower-0.033,-0.16)],[Vector2(0.006,0.024),Vector2(0.004,0.023)],Color("#302f28"),6)
		else:
			for toe in [-1,0,1]:ellipsoid(knee,Vector3(toe*0.031,-lower-0.007,-0.17 if not rabbit else -0.20),Vector3(0.017,0.016,0.032),cream.darkened(0.19),8)
	tail=pivot(torso,Vector3(0,-0.055,0.43 if rabbit else 0.61),"Tail")
	if rabbit:
		ellipsoid(tail,Vector3(0,0.015,0.07),Vector3(0.11,0.13,0.12),cream)
	elif deer:
		piece(tail,[Vector3.ZERO,Vector3(0,-0.045,0.10),Vector3(0,-0.13,0.16)],[Vector2(0.07,0.07),Vector2(0.065,0.052),Vector2.ZERO],cream,10)
	else:
		piece(tail,[Vector3.ZERO,Vector3(0,-0.09,0.23),Vector3(0,-0.23,0.49),Vector3(0,-0.36,0.72),Vector3(0,-0.37,0.86 if fox else 0.81)],[Vector2(0.10,0.10),Vector2(0.14 if fox else 0.125,0.15),Vector2(0.16 if fox else 0.13,0.15),Vector2(0.09,0.09),Vector2.ZERO],fur,14,true)
		piece(tail,[Vector3(0,-0.34,0.66),Vector3(0,-0.365,0.77),Vector3(0,-0.37,0.87 if fox else 0.82)],[Vector2(0.10,0.10),Vector2(0.07,0.07),Vector2.ZERO],cream if fox else fur.darkened(0.21),12)
	if deer:
		ellipsoid(torso,Vector3(0,0.0,0.51),Vector3(0.19,0.23,0.11),cream)
		for side in [-1,1]:
			var antler := Color("#7d6a4c")
			piece(head,[Vector3(side*0.10,0.15,0.06),Vector3(side*0.17,0.36,0.065),Vector3(side*0.29,0.62,0.025),Vector3(side*0.36,0.76,-0.045)],[Vector2(0.027,0.027),Vector2(0.025,0.025),Vector2(0.018,0.018),Vector2.ZERO],antler,8)
			piece(head,[Vector3(side*0.16,0.34,0.065),Vector3(side*0.28,0.43,-0.085),Vector3(side*0.31,0.57,-0.12)],[Vector2(0.018,0.018),Vector2(0.012,0.012),Vector2.ZERO],antler,8)
	_finish_surfaces()

func animate(gait: float,speed: float,mood: String,time: float,reduced: bool=false) -> void:
	if torso==null:return
	var movement := clampf(speed/65.0,0,1)
	var moving := movement>0.05
	var motion := 0.28 if reduced else 1.0
	var blend := 1.0 if last_time<0 or time<=last_time else 1.0-exp(-minf(time-last_time,0.1)*12.0)
	last_time=time
	var rabbit := kind=="rabbit"
	var resting := not moving and mood=="ruhen"
	var target_height := body_height+sin(gait*2.0)*(0.036 if rabbit else 0.015)*movement*motion
	if resting:target_height=(0.20 if rabbit else 0.42 if kind=="deer" else 0.29 if kind=="fox" else 0.34)+sin(time*1.6)*0.007*motion
	torso.position.y=lerpf(torso.position.y,target_height,blend)
	var bow := -0.18 if mood=="spielen" and not moving else 0.0
	torso.rotation.x=lerp_angle(torso.rotation.x,bow+sin(gait)*0.07*movement*motion if rabbit else bow,blend)
	torso.rotation.z=lerp_angle(torso.rotation.z,sin(gait)*0.023*movement*motion,blend)
	for i in range(legs.size()):
		var wave := sin(gait+(0.0 if i in [0,3] else PI))
		if rabbit:wave=sin(gait+(0.0 if i<2 else PI*0.8))
		var upper_angle := wave*0.48*movement*motion
		var knee_angle := maxf(0.0,-wave)*0.68*movement*motion
		if resting:
			upper_angle=(0.81 if kind=="deer" else 1.10) if i<2 else 0.80
			knee_angle=(0.76 if kind=="deer" else 0.48) if i<2 else -2.40
		elif mood=="spielen" and not moving:
			upper_angle=-0.32 if i<2 else 0.16
			knee_angle=0.35 if i<2 else 0.0
		legs[i].rotation.x=lerp_angle(legs[i].rotation.x,upper_angle,blend)
		knees[i].rotation.x=lerp_angle(knees[i].rotation.x,knee_angle,blend)
	var neck_angle := -0.025+sin(time*1.65)*0.015*motion
	var head_angle := -0.045+sin(time*1.1)*0.012*motion
	var head_turn := sin(time*0.7+phase)*0.095*motion if not moving else sin(gait)*0.025*motion
	if not moving:
		if mood in ["grasen","schnüffeln","trinken"]:
			neck_angle=-0.58+sin(time*2.0)*0.035*motion
			head_angle=-0.27
		elif mood=="heulen":neck_angle=0.53;head_angle=0.24;head_turn=0
		elif resting:neck_angle=-0.22;head_angle=-0.18;head_turn=-0.45 if not rabbit else 0.12
	neck.rotation.x=lerp_angle(neck.rotation.x,neck_angle,blend)
	head.rotation.x=lerp_angle(head.rotation.x,head_angle,blend)
	head.rotation.y=lerp_angle(head.rotation.y,head_turn,blend)
	jaw.rotation.x=lerp_angle(jaw.rotation.x,-0.12 if mood=="heulen" else -0.018*movement,blend)
	tail.rotation.y=lerp_angle(tail.rotation.y,sin(time*(4.2 if mood=="spielen" else 1.4))*(0.40 if mood=="spielen" else 0.09)*motion,blend)
	tail.rotation.x=lerp_angle(tail.rotation.x,-0.23 if resting else -0.20 if mood=="spielen" else sin(time*1.7)*0.025*motion,blend)
	for i in range(ears.size()):
		var twitch := pow(maxf(0.0,sin(time*0.81+float(i)*2.5)),12)*0.13*motion
		ears[i].rotation.z=lerp_angle(ears[i].rotation.z,(-0.10 if i==0 else 0.10) if resting else twitch*(1 if i==0 else -1),blend)
		ears[i].rotation.x=lerp_angle(ears[i].rotation.x,-0.26 if resting else 0.16 if mood=="spielen" else 0.0,blend)
	for i in range(eyes.size()):
		var blink := fposmod(time+float(i)*0.025+phase,5.8)<0.14
		eyes[i].scale.y=lerpf(eyes[i].scale.y,0.09 if resting or blink else 1.0,blend)
