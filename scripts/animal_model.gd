class_name WolfAnimalModel
extends Node3D

# Original articulated wildlife. Meshes are shared by species and merged per
# joint, so eyes, fur markings and toes do not each cost a separate draw call.
static var material_cache: Dictionary = {}
static var mesh_cache: Dictionary = {}
const PLAYER_GAIT_DISTANCE := 22.0
const ANIMAL_GAIT_DISTANCE := 18.0
var torso: Node3D
var neck: Node3D
var head: Node3D
var jaw: Node3D
var tail: Node3D
var ears: Array[Node3D] = []
var eyes: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var paws: Array[Node3D] = []
var limb_geometry: Array[Vector3] = []
var paw_sizes: Array[Vector3] = []
var foot_targets: Array[Vector3] = []
var foot_ground: Array[float] = [0.0,0.0,0.0,0.0]
var foot_planted: Array[bool] = [true,true,true,true]
var kind := "wolf"
var phase := 0.0
var body_scale := 1.0
var body_height := 0.79
var last_time := -1.0
var _last_cycle := 0.0
var _movement := 0.0
var _rest_amount := 0.0
var _step_velocity := 6.0
var _leg_cycles: Array[float] = [0.0,0.0,0.0,0.0]
var _leg_duties: Array[float] = [.66,.66,.66,.66]
var _swing_starts: Array[float] = [0.0,0.0,0.0,0.0]
var _swing_from: Array[float] = [0.0,0.0,0.0,0.0]
var _swing_to: Array[float] = [0.0,0.0,0.0,0.0]
var _was_moving := false
var _feeding_amount := 0.0
var muzzle_tip := Vector3.ZERO
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
				# Longitudinal taper belongs in the normal as well as the outline.
				# Pure radial normals made cheeks and shoulders light like barrels.
				var span: float=maxf(.001,points[after].distance_to(points[before]))
				var slope: Vector2=(radii[after]-radii[before])/span
				var axial := -(slope.x*cos(angle)*cos(angle)/maxf(r.x,.018)+slope.y*sin(angle)*sin(angle)/maxf(r.y,.018))
				var normal := (u*cos(angle)/maxf(r.x,0.018)+v*sin(angle)/maxf(r.y,0.018)+tangent*axial).normalized()
				if r.length()<0.015:normal=-tangent if coord.x==0 else tangent
				var c := color
				if dorsal:
					c=c.lerp(color.darkened(0.20),smoothstep(-0.025,0.20,radial.y)*0.8)
					if kind in ["wolf","fox"]:c=c.lerp(Color("#cfc9b6"),smoothstep(0.0,0.18,-radial.y)*0.5)
					# Fur variation is painted into the existing joint surface. No
					# transparent fur cards or extra draw calls are needed.
					var fleck := sin(p.z*31.0+p.y*23.0)*sin(p.x*35.0-p.z*17.0)
					c=c.lightened(maxf(0,fleck)*.045).darkened(maxf(0,-fleck)*.035)
					if parent==head and kind in ["wolf","fox"]:
						var mask := smoothstep(.015,.12,absf(p.x))*smoothstep(-.19,-.03,p.z)
						c=c.lerp(Color("#67706b") if kind=="wolf" else Color("#8e593b"),mask*.32)
					if parent==torso and kind=="deer":
						var belly := smoothstep(.06,.25,-radial.y)
						c=c.lerp(Color("#c6b592"),belly*.46)
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
	var fur := Color("#8e9593") if kind=="wolf" else Color("#bd783d") if fox else Color("#a78150") if deer else Color("#9b8d79")
	var cream := Color("#d6d1bd") if not fox else Color("#e4d9bf")
	body_scale=0.70 if rabbit else 0.82 if fox else 1.08 if deer else 1.0
	if young:body_scale*=0.73
	scale=Vector3.ONE*body_scale
	body_height=0.47 if rabbit else 0.715 if fox else 1.10 if deer else 0.79
	torso=pivot(self,Vector3(0,body_height,0),"Torso")
	if rabbit:
		ellipsoid(torso,Vector3(0,-0.035,0.10),Vector3(0.26,0.275,0.44),fur,16,true)
		ellipsoid(torso,Vector3(0,-0.06,-0.24),Vector3(0.17,0.215,0.20),cream)
	else:
		var width := .205 if deer else .205 if fox else .28
		var depth := .295 if deer else .235 if fox else .315
		piece(torso,[Vector3(0,.0,-.70),Vector3(0,.025,-.51),Vector3(0,.045,-.27),Vector3(0,.025,-.02),Vector3(0,.025,.22),Vector3(0,-.035,.48),Vector3(0,-.055,.63),Vector3(0,-.055,.69)],[Vector2(.028,.045),Vector2(width*.88,depth),Vector2(width,depth*.98),Vector2(width*.89,depth*.85),Vector2(width*.72,depth*.68),Vector2(width*.82,depth*.80),Vector2(width*.62,depth*.67),Vector2(.018,.026)],fur,16,true)
		ellipsoid(torso,Vector3(0,-.015,-.46),Vector3(width*.91,depth*1.02,.235),fur,14,true)
		ellipsoid(torso,Vector3(0,-.15,-.49),Vector3(width*.64,.215,.17),cream if not deer else fur.lightened(.08))
		if not deer:
			for side in [-1,1]:
				piece(torso,[Vector3(side*width*.60,.065,-.51),Vector3(side*width*.95,-.07,-.38),Vector3(side*width*1.02,-.17,-.28),Vector3(side*width*.91,-.21,-.24)],[Vector2(.10,.09),Vector2(.095,.08),Vector2(.055,.045),Vector2(.008,.008)],fur.lightened(.055))
	neck=pivot(torso,Vector3(0,0.11 if not rabbit else 0.08,-0.48 if not rabbit else -0.25),"Neck")
	if deer:
		piece(neck,[Vector3(0,-.06,.045),Vector3(0,.12,-.055),Vector3(0,.32,-.135),Vector3(0,.52,-.16)],[Vector2(.15,.18),Vector2(.14,.155),Vector2(.115,.13),Vector2(.088,.095)],fur,14,true)
		head=pivot(neck,Vector3(0,0.53,-0.16),"Head")
	elif rabbit:
		ellipsoid(neck,Vector3(0,0.04,-0.03),Vector3(0.16,0.19,0.18),fur)
		head=pivot(neck,Vector3(0,0.13,-0.11),"Head")
	else:
		ellipsoid(neck,Vector3(0,.09,-.06),Vector3(.177 if fox else .225,.235,.255),fur,14,true)
		piece(neck,[Vector3(0,.015,-.13),Vector3(0,-.10,-.18),Vector3(0,-.22,-.12),Vector3(0,-.26,-.065)],[Vector2(.14,.13),Vector2(.12,.09),Vector2(.07,.055),Vector2(.010,.010)],cream)
		head=pivot(neck,Vector3(0,0.24,-0.24),"Head")
	var skull := Vector3(.145,.145,.245) if deer else Vector3(.18,.165,.20) if rabbit else Vector3(.178,.175,.25) if fox else Vector3(.218,.195,.285)
	ellipsoid(head,Vector3(0,0.005,0.035),skull,fur,16,true)
	var muzzle_length := .22 if rabbit else .43 if deer else .53 if fox else .525
	var muzzle_width := .084 if deer else .096 if rabbit else .107 if fox else .135
	muzzle_tip=Vector3(0,-.10,-muzzle_length)
	piece(head,[Vector3(0,-.07,-.10),Vector3(0,-.09,-muzzle_length*.58),Vector3(0,-.105,-muzzle_length*.91),muzzle_tip],[Vector2(muzzle_width,.089),Vector2(muzzle_width*.88,.071),Vector2(muzzle_width*.61,.038),Vector2(.017,.024)],cream if not deer else fur.lightened(.05),14)
	if not rabbit:
		# A furred nasal bridge sits above pale lip fur, giving the muzzle a
		# tapered silhouette instead of a single pale cone.
		piece(head,[Vector3(0,-.005,-.115),Vector3(0,-.015,-muzzle_length*.59),Vector3(0,-.055,-muzzle_length*.93)],[Vector2(muzzle_width*.87,.067),Vector2(muzzle_width*.67,.050),Vector2(muzzle_width*.39,.018)],fur,12,true)
	ellipsoid(head,muzzle_tip,Vector3(.049 if deer else .029 if rabbit else .063,.029 if rabbit else .036,.027),Color("#29312c"))
	for side in [-1,1]:
		if not rabbit:ellipsoid(head,muzzle_tip+Vector3(side*.042,-.006,-.016),Vector3(.012,.013,.010),Color("#18231f"),6)
		piece(head,[Vector3(side*muzzle_width*.76,-.128,-muzzle_length*.35),Vector3(side*muzzle_width*.66,-.127,-muzzle_length*.76)],[Vector2(.005,.005),Vector2(.002,.002)],Color("#514d40"),6)
	jaw=pivot(head,Vector3(0,-0.145,-0.12),"Jaw")
	piece(jaw,[Vector3(0,0,0),Vector3(0,-0.018,-muzzle_length*0.45),Vector3(0,-0.006,-muzzle_length*0.83)],[Vector2(muzzle_width*0.90,0.042),Vector2(muzzle_width*0.70,0.034),Vector2(0.03,0.014)],cream.darkened(0.04))
	for side in [-1,1]:
		if not deer and not rabbit:
			piece(head,[Vector3(side*skull.x*.65,-.025,-.035),Vector3(side*skull.x*1.04,-.09,.045),Vector3(side*skull.x*1.11,-.13,.105),Vector3(side*skull.x*.92,-.15,.16)],[Vector2(.085,.06),Vector2(.088,.060),Vector2(.055,.040),Vector2(.009,.009)],cream)
		var eye := pivot(head,Vector3(side*skull.x*0.94,0.018,-0.13 if not rabbit else -0.07),"Eye"+str(side))
		eyes.append(eye)
		ellipsoid(eye,Vector3.ZERO,Vector3(.021,.030 if not rabbit else .035,.040),Color("#28332b"))
		ellipsoid(eye,Vector3(side*.009,0,-.007),Vector3(.015,.023,.026),Color("#be984e") if not deer and not rabbit else Color("#654c32"))
		ellipsoid(eye,Vector3(side*.021,0,-.014),Vector3(.010,.019,.011),Color("#202923"))
		ellipsoid(eye,Vector3(side*0.025,0.009,-0.020),Vector3(0.005,0.007,0.005),Color("#f7f0d9"),8)
		ellipsoid(head,Vector3(side*skull.x*.88,.063,-.14),Vector3(.043,.014,.060),fur.darkened(.18))
		var ear := pivot(head,Vector3(side*0.105 if deer else side*0.13 if rabbit else side*0.17,0.13 if deer else 0.15,0.08),"Ear"+str(side))
		ears.append(ear)
		var tip := Vector3(side*.225,.175,.02) if deer else Vector3(side*.045,.65,.07) if rabbit else Vector3(side*.032,.35 if fox else .25,.009)
		if rabbit:
			piece(ear,[Vector3.ZERO,tip*.25,tip*.62,tip*.88,tip],[Vector2(.042,.030),Vector2(.073,.030),Vector2(.070,.025),Vector2(.039,.020),Vector2(.012,.010)],fur,12,true)
			piece(ear,[tip*.13+Vector3(0,0,-.028),tip*.37+Vector3(0,0,-.030),tip*.72+Vector3(0,0,-.025),tip*.91+Vector3(0,0,-.014)],[Vector2(.021,.006),Vector2(.043,.006),Vector2(.035,.006),Vector2(.009,.005)],Color("#b79a86"),10)
		else:
			piece(ear,[Vector3.ZERO,tip*.32,tip*.67,tip],[Vector2(.083,.043),Vector2(.088 if deer else .071,.033),Vector2(.056,.026),Vector2(.009,.007)],fur,12,true)
			piece(ear,[Vector3(0,.018,-.037),tip*.35+Vector3(0,0,-.030),tip*.72+Vector3(0,0,-.022),tip*.93+Vector3(0,0,-.009)],[Vector2(.048,.006),Vector2(.049,.007),Vector2(.029,.006),Vector2(.004,.004)],Color("#bbab96"),10)
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
		limb_geometry.append(Vector3(upper,lower,bend))
		piece(limb,[Vector3.ZERO,Vector3(0,-upper*0.5,bend*0.45),Vector3(0,-upper,bend)],[Vector2(thickness*1.18,thickness),Vector2(thickness,thickness*0.75),Vector2(thickness*0.71,thickness*0.68)],fur,10)
		if not front:ellipsoid(limb,Vector3(0,-upper*0.2,0.018),Vector3(thickness*1.55,upper*0.72,0.13 if not rabbit else 0.21),fur,12,true)
		piece(knee,[Vector3.ZERO,Vector3(0,-lower*0.52,0.04 if not front else -0.025),Vector3(0,-lower,-0.045)],[Vector2(thickness*0.72,thickness*0.65),Vector2(thickness*0.5,thickness*0.44),Vector2(thickness*0.62,thickness*0.50)],fur if not fox else Color("#514539"),10)
		var foot_size := Vector3(0.065,0.047,0.089) if deer else Vector3(0.08,0.051,0.21) if rabbit and not front else Vector3(0.085,0.045,0.125)
		var paw := pivot(knee,Vector3(0,-lower,-0.082),"Paw"+str(i))
		paws.append(paw)
		paw_sizes.append(foot_size)
		foot_targets.append(Vector3(limb.position.x,foot_size.y,limb.position.z+bend-.082))
		ellipsoid(paw,Vector3.ZERO,foot_size,Color("#554a3d") if deer else cream.darkened(0.13),12)
		if deer:
			piece(paw,[Vector3(0,.003,-.048),Vector3(0,-.025,-.078)],[Vector2(0.006,0.024),Vector2(0.004,0.023)],Color("#302f28"),6)
		else:
			for toe in [-1,0,1]:ellipsoid(paw,Vector3(toe*.031,-.007,-.088 if not rabbit else -.118),Vector3(.017,.016,.032),cream.darkened(.19),8)
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
			piece(head,[Vector3(side*.09,.14,.085),Vector3(side*.12,.27,.11),Vector3(side*.15,.43,.15),Vector3(side*.20,.57,.16),Vector3(side*.22,.65,.10)],[Vector2(.027,.025),Vector2(.025,.023),Vector2(.019,.019),Vector2(.013,.013),Vector2(.002,.002)],antler,8)
			piece(head,[Vector3(side*.12,.29,.11),Vector3(side*.15,.39,-.02),Vector3(side*.18,.46,-.095)],[Vector2(.017,.017),Vector2(.011,.011),Vector2(.001,.001)],antler.lightened(.06),8)
			piece(head,[Vector3(side*.15,.43,.15),Vector3(side*.22,.49,.27),Vector3(side*.27,.57,.30)],[Vector2(.015,.015),Vector2(.010,.010),Vector2(.001,.001)],antler,8)
	_finish_surfaces()

func stride_length() -> float:
	return .90 if kind=="deer" else .53 if kind=="fox" else .42 if kind=="rabbit" else .65

static func renderer_gait(gait: float,player: bool) -> float:
	# NPCs and the player accumulate different distance units in gameplay.
	return gait if player else gait*ANIMAL_GAIT_DISTANCE/PLAYER_GAIT_DISTANCE

func cycle_phase(gait: float) -> float:
	# Gameplay gait is real distance / 22. Match each anatomical stride to
	# that distance, including the gradual size of a young player.
	return gait*(PLAYER_GAIT_DISTANCE*.032*TAU)/(stride_length()*maxf(scale.x,.25))

func set_foot_heights(heights: Array[float]) -> void:
	if heights.size()==4:foot_ground=heights

func foot_position(index: int) -> Vector3:
	return torso.transform*legs[index].transform*knees[index].transform*paws[index].position

func nose_position() -> Vector3:
	return torso.transform*neck.transform*head.transform*muzzle_tip

func _solve_leg(index: int,target: Vector3,blend: float,torso_inverse: Transform3D) -> void:
	var geometry: Vector3=limb_geometry[index]
	var local: Vector3=torso_inverse*target-legs[index].position
	var upper_length := Vector2(geometry.x,geometry.z).length()
	var lower_length := Vector2(geometry.y,.082).length()
	var distance := clampf(Vector2(local.y,local.z).length(),absf(upper_length-lower_length)+.001,upper_length+lower_length-.001)
	var bend := acos(clampf((distance*distance-upper_length*upper_length-lower_length*lower_length)/(2*upper_length*lower_length),-1,1))*(-1.0 if index<2 else 1.0)
	var direction := atan2(local.z,-local.y)
	var upper_direction := direction-atan2(lower_length*sin(bend),upper_length+lower_length*cos(bend))
	var upper_angle := atan2(geometry.z,geometry.x)-upper_direction
	var lower_angle := atan2(-.082,geometry.y)-upper_direction-bend-upper_angle
	legs[index].rotation.x=lerp_angle(legs[index].rotation.x,upper_angle,blend)
	knees[index].rotation.x=lerp_angle(knees[index].rotation.x,lower_angle,blend)
	# Ankle cancellation keeps the pads/hooves horizontal during stance.
	paws[index].rotation.x=-(torso.rotation.x+legs[index].rotation.x+knees[index].rotation.x)
	paws[index].rotation.z=-torso.rotation.z

func animate(gait: float,speed: float,mood: String,time: float,reduced: bool=false,attention: float=0.0,look_angle: float=0.0) -> void:
	if torso==null:return
	var cycle := cycle_phase(gait)
	# A fresh/reset pose is deterministic; ordinary frames preserve planted
	# pads and finish airborne steps instead of snapping into a neutral pose.
	# Time-zero snapshots support anatomical checks. Repeated camera sync at
	# the same positive clock leaves the current phase untouched.
	var immediate := last_time<0 or time<last_time or (time==0.0 and last_time==0.0) or absf(cycle-_last_cycle)>PI
	var dt := minf(maxf(time-last_time,0.0),.1) if not immediate else 0.0
	var blend := 1.0 if immediate else 1.0-exp(-dt*10.0)
	var posture_blend := 1.0 if immediate else 1.0-exp(-dt*6.0)
	var distance_phase := 0.0 if immediate else maxf(0.0,cycle-_last_cycle)
	_movement=lerpf(_movement,clampf(speed/80.0,0,1),blend)
	var movement := _movement
	var moving := speed>2.8
	if moving:
		_step_velocity=maxf(6.0,speed*.032/maxf(.1,stride_length()*scale.x)*TAU) if immediate else maxf(6.0,distance_phase/maxf(dt,.001))
	var motion := .25 if reduced else 1.0
	last_time=time
	_last_cycle=cycle
	var rabbit := kind=="rabbit"
	var resting := not moving and mood=="ruhen"
	var greeting := mood=="begrüßen"
	var escaping := mood=="fliehen"
	var feeding := not moving and mood in ["grasen","schnüffeln","trinken"]
	var drinking := feeding and mood=="trinken"
	_rest_amount=lerpf(_rest_amount,1.0 if resting else 0.0,blend)
	_feeding_amount=lerpf(_feeding_amount,1.0 if feeding else 0.0,blend)
	var duty_goal := .32 if rabbit else .58 if escaping else .66
	var body_drop := .105 if kind=="deer" else .055 if kind=="fox" else .05 if rabbit else .065
	var breathing := sin(time*1.65+phase)*.004*motion*(1.0-movement)
	var target_height := body_height-body_drop*movement+sin(cycle*2)*.011*movement*motion+breathing
	var lowest_ground := minf(minf(foot_ground[0],foot_ground[1]),minf(foot_ground[2],foot_ground[3]))
	target_height-=maxf(0,-lowest_ground-.012)
	if rabbit and moving:target_height+=sin(clampf((fposmod(cycle/TAU,1.0)-.28)/.30,0,1)*PI)*.055*movement*motion
	var rest_height := (.285 if rabbit else .43 if kind=="deer" else .34 if kind=="fox" else .355)+sin(time*1.6+phase)*.007*motion
	target_height=lerpf(target_height,rest_height,_rest_amount)
	target_height-=(.14 if kind=="deer" else .04 if rabbit else .025 if kind=="wolf" else .02)*_feeding_amount
	if moving or foot_planted.has(false):
		# Ease down before rear-pad landing rather than imposing a sudden
		# height limit only when the approaching pad has reached the ground.
		for i in range(4):
			var geometry: Vector3=limb_geometry[i]
			var reach := Vector2(geometry.x,geometry.z).length()+Vector2(geometry.y,.082).length()-.012
			var landing_z := geometry.z-.082-stride_length()*duty_goal*.5
			var landing_height := foot_ground[i]+paw_sizes[i].y-legs[i].position.y+sqrt(maxf(.001,reach*reach-landing_z*landing_z))
			target_height=minf(target_height,landing_height)
	torso.position.y=lerpf(torso.position.y,target_height,blend)
	var bow := -.14 if mood=="spielen" and not moving else -.055 if escaping else 0.0
	var feeding_bow := (-.14 if kind=="deer" else -.045 if rabbit else -.025)*_feeding_amount
	torso.rotation.x=lerp_angle(torso.rotation.x,bow+feeding_bow+(sin(cycle)*.065*movement*motion if rabbit else 0.0),blend)
	torso.rotation.z=lerp_angle(torso.rotation.z,sin(cycle)*.012*movement*motion,blend)
	# Walk becomes diagonal trot gradually. Correction is limited to swing,
	# so changing speed never drags a supporting paw across the soil.
	var trot := smoothstep(45.0,105.0,speed)
	var offsets: Array[float]=[0.0,PI,lerpf(PI*.65,PI,trot),lerpf(PI*1.65,TAU,trot)]
	if escaping and kind=="deer":offsets=[0.0,.25,PI,PI+.25]
	if rabbit:offsets=[PI,PI+.12,0.0,.12]
	for i in range(4):
		var was_planted := foot_planted[i]
		var previous_phase := fposmod(_leg_cycles[i],TAU)/TAU
		if immediate:
			_leg_cycles[i]=cycle+offsets[i]
			_leg_duties[i]=duty_goal
		else:
			_leg_cycles[i]+=distance_phase
			if not was_planted:
				if moving:
					var error := wrapf(cycle+offsets[i]-_leg_cycles[i],-PI,PI)
					_leg_cycles[i]+=clampf(error,-distance_phase*.30,distance_phase*.30)
				else:
					# Only airborne paws complete a step after travel stops.
					_leg_cycles[i]+=dt*_step_velocity
		var phase_value := fposmod(_leg_cycles[i],TAU)/TAU
		if not immediate and phase_value<previous_phase:_leg_duties[i]=duty_goal
		var duty := _leg_duties[i]
		if not immediate and moving and not _was_moving and was_planted and phase_value<duty:
			# Start the first stance at the actual standing pad, rather than
			# holding a neutral pad down for an entire front-to-back stride.
			var neutral_phase := (foot_targets[i].z-legs[i].position.z-limb_geometry[i].z+.082+stride_length()*duty*.5)/stride_length()
			var phase_shift := maxf(0.0,minf(neutral_phase,duty-.02)-phase_value)
			_leg_cycles[i]+=phase_shift*TAU
			phase_value+=phase_shift
		var planted := (not moving and was_planted) or phase_value<duty
		var stride := stride_length()*duty
		var z_offset := 0.0
		var lift := 0.0
		var geometry: Vector3=limb_geometry[i]
		var base_z := legs[i].position.z+geometry.z-.082
		if immediate:
			planted=not moving or phase_value<duty
			if moving:
				z_offset=lerpf(-stride*.5,stride*.5,phase_value/duty) if planted else _swing_z(stride*.5,-stride*.5,(phase_value-duty)/(1.0-duty),stride_length()*(1.0-duty))
				if not planted:lift=_swing_lift((phase_value-duty)/(1.0-duty),movement)
			_swing_starts[i]=duty
			_swing_from[i]=stride*.5
			_swing_to[i]=-stride*.5
		elif planted and moving:
			# Forward body travel is -Z. The support pad moves +Z in local
			# space by exactly the same distance, holding its world position.
			z_offset=foot_targets[i].z-base_z+distance_phase/TAU*stride_length()
			if not was_planted:z_offset=_swing_to[i]+phase_value*stride_length()
		elif not planted:
			if was_planted:
				_swing_starts[i]=phase_value
				_swing_from[i]=foot_targets[i].z-base_z+distance_phase/TAU*stride_length()
				_swing_to[i]=-stride_length()*duty_goal*.5
			var swing := clampf((phase_value-_swing_starts[i])/maxf(.02,1.0-_swing_starts[i]),0.0,1.0)
			z_offset=_swing_z(_swing_from[i],_swing_to[i],swing,stride_length()*(1.0-_swing_starts[i]))
			lift=_swing_lift(swing,maxf(movement,.35))
		else:
			var folded_z := (-.16 if i<2 else -.18 if rabbit else -.22)*_rest_amount
			if mood=="spielen":folded_z+=(-.10 if i<2 else .07)*(1.0-_rest_amount)
			z_offset=lerpf(foot_targets[i].z-base_z,folded_z,blend)
		if immediate and not moving:
			z_offset=(-.16 if i<2 else -.18 if rabbit else -.22) if resting else (-.10 if i<2 else .07) if mood=="spielen" else 0.0
		foot_planted[i]=planted
		foot_targets[i]=Vector3(legs[i].position.x,foot_ground[i]+paw_sizes[i].y+lift,base_z+z_offset)
	# Limit body height for all approaching feet as well as supporting ones;
	# their smooth trajectories must not force a late touchdown body drop.
	var supported_height := torso.position.y
	for i in range(4):
		var geometry: Vector3=limb_geometry[i]
		var reach := Vector2(geometry.x,geometry.z).length()+Vector2(geometry.y,.082).length()-.006
		var hip_offset := torso.basis*legs[i].position
		var horizontal := foot_targets[i].z-hip_offset.z
		var vertical := sqrt(maxf(.001,reach*reach-horizontal*horizontal))
		supported_height=minf(supported_height,foot_targets[i].y-hip_offset.y+vertical)
	torso.position.y=supported_height
	var torso_inverse := torso.transform.affine_inverse()
	for i in range(4):
		# Solve the current blended torso pose so body breathing cannot push
		# planted feet into the ground. Locomotion uses the exact distance phase.
		# Solve the eased trajectory exactly, rather than easing bone angles
		# that would leave a newly planted foot floating above the ground.
		_solve_leg(i,foot_targets[i],1.0,torso_inverse)
	var neck_angle := -.025+sin(time*1.65)*.015*motion
	var head_angle := -.045+sin(time*1.1)*.012*motion
	var alert := clampf(maxf(attention,.6 if greeting else 0.0),0,1)
	var head_turn := lerpf(sin(time*.7+phase)*.08*motion,clampf(look_angle,-.65,.65),alert)
	if escaping:neck_angle=-.12;head_angle=-.06
	if not moving:
		if feeding:
			# A long-necked animal must reach the plant with its actual muzzle.
			# The counter-rotation at the skull lets it feed without folding
			# the entire face into its chest.
			neck_angle=(-2.05 if kind=="deer" else -1.72 if rabbit else -1.44 if kind=="fox" else -1.48)+sin(time*(1.45 if kind=="deer" else 2.0))*.016*motion
			head_angle=.68 if kind=="deer" else .14
			if drinking:neck_angle-=.025;head_angle+=sin(time*2.9)*.018*motion
		elif mood=="heulen":neck_angle=.53;head_angle=.24;head_turn=0.0
		elif resting:
			neck_angle=-.28 if kind=="fox" else -.22
			head_angle=-.25 if kind=="fox" else -.18
			head_turn=-.55 if kind=="fox" else -.35 if not rabbit else .12
		elif greeting:neck_angle=-.08+sin(time*2.3)*.025*motion;head_angle=-.06
		elif alert>.35:neck_angle=.04+alert*.06;head_angle=.035
	neck.rotation.x=lerp_angle(neck.rotation.x,neck_angle,posture_blend)
	head.rotation.x=lerp_angle(head.rotation.x,head_angle,posture_blend)
	head.rotation.y=lerp_angle(head.rotation.y,head_turn,posture_blend)
	var chew := maxf(0.0,sin(time*(3.5 if drinking else 2.3)))*(.022 if drinking else .035)*motion if feeding else 0.0
	jaw.rotation.x=lerp_angle(jaw.rotation.x,-.12 if mood=="heulen" else -.018*movement-chew,posture_blend)
	var tail_amount := .28 if mood=="spielen" else .18 if greeting else .025 if escaping else .045
	var tail_turn := sin(time*(2.7 if greeting or mood=="spielen" else 1.1)+phase)*tail_amount*motion+sin(cycle)*.035*movement*motion
	if resting:tail_turn=.65 if kind=="fox" else -.18 if kind=="wolf" else 0.0
	tail.rotation.y=lerp_angle(tail.rotation.y,tail_turn,blend)
	tail.rotation.x=lerp_angle(tail.rotation.x,-.23 if resting else -.20 if greeting or mood=="spielen" else .08 if escaping else sin(time*1.7)*.025*motion,blend)
	for i in range(ears.size()):
		var twitch := pow(maxf(0,sin(time*.81+float(i)*2.5)),12)*.11*motion
		ears[i].rotation.z=lerp_angle(ears[i].rotation.z,(-.1 if i==0 else .1) if resting else twitch*(1 if i==0 else -1),blend)
		var ear_pitch := (1.35 if rabbit else .30 if kind=="deer" else .18 if kind=="fox" else .12) if resting else .26 if escaping else .12 if greeting else alert*.055
		ear_pitch+=(1.0 if rabbit else .70 if kind=="deer" else .90 if kind=="fox" else .80)*_feeding_amount
		ears[i].rotation.x=lerp_angle(ears[i].rotation.x,ear_pitch,posture_blend)
		var ear_turn := clampf(look_angle,-.6,.6)*alert*(.42 if i==0 else .30)
		ears[i].rotation.y=lerp_angle(ears[i].rotation.y,ear_turn,posture_blend)
	for eye in eyes:
		var blink := fposmod(time+phase,7.0 if alert>.35 else 5.8)<.13
		eye.scale.y=lerpf(eye.scale.y,.09 if resting or blink else 1.0,blend)
	_was_moving=moving

func _swing_z(from_z: float,to_z: float,t: float,tangent: float) -> float:
	# Cubic Hermite meets stance with matching local forward velocity, hence
	# a stationary world pad at both toe-off and landing.
	var t2 := t*t
	var t3 := t2*t
	return (2*t3-3*t2+1)*from_z+(t3-2*t2+t)*tangent+(-2*t3+3*t2)*to_z+(t3-t2)*tangent

func _swing_lift(t: float,amount: float) -> float:
	var arc := sin(t*PI)
	return arc*arc*(.15 if kind=="rabbit" else .12 if kind=="deer" else .095)*amount
