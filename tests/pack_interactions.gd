extends SceneTree

const PACK = preload("res://scripts/pack_interactions.gd")
const WORLD_HASH := "681fd8f2d02213bd55029cfbfc777b3038bd535b1cd6459c049545340cc4f283"
var errors := 0
var checks := 0

func check(value: bool,message: String) -> void:
	checks += 1
	if value:print("PASS: "+message)
	else:push_error("FAIL: "+message);errors += 1

func _initialize() -> void:
	call_deferred("run")

func wolf(point: Vector2,role: String="Mutter",phase: float=0,young: bool=false) -> Dictionary:
	return {"kind":"wolf","p":point,"home":point,"role":role,"phase":phase,"young":young,"facing":Vector2.UP,"speed":0.0,"gait":0.0,"mood":"lauschen"}

func context(point: Vector2) -> Dictionary:
	return {"region":0,"hour":7.5,"now":0.0,"elapsed":0.0,"escort":false,"player_pos":point,"player_facing":Vector2.UP,"player_speed":0.0,"player_mood":"lauschen","signal":{},"meeting":false}

func simulate(members: Array,motion: WolfAnimalMotion,ctx: Dictionary,ticks: int,dt: float=0.035) -> Dictionary:
	var began := Time.get_ticks_usec()
	var safe := true
	var bounded := true
	var bodies := true
	var greeted: Dictionary = {}
	var approached: Dictionary = {}
	var played: Dictionary = {}
	for tick in range(ticks):
		ctx.now += dt;ctx.elapsed += dt
		for member in members:
			var before: Vector2 = member.p
			var plan: Dictionary = PACK.plan(member,members,motion,ctx)
			var player_radius: float = float(ctx.get("player_radius",25.0))
			var next := motion.advance_pack(member,plan.target,plan.speed,dt,ctx.now,members,ctx.player_pos,player_radius)
			if not motion.segment_free(before,next):safe = false
			if before.distance_to(next) > maxf(34.0,float(plan.speed))*minf(dt,0.1)+0.001:bounded = false
			if not motion.body_step_free(before,next,member,members,ctx.player_pos,player_radius) and before.distance_to(next) > 0.0001:bodies = false
			member.speed = before.distance_to(next)/maxf(dt,0.0001)
			member.p = next;member.mood = plan.mood;member.behavior = plan.behavior;member.target_pos = plan.look_target
			if plan.mood == "begrüßen":greeted[WolfPackLife.animal_key(member)] = true
			if plan.behavior == "approach":approached[WolfPackLife.animal_key(member)] = true
			if plan.behavior == "play":played[WolfPackLife.animal_key(member)] = true
	return {"safe":safe,"bounded":bounded,"bodies":bodies,"greeted":greeted,"approached":approached,"played":played,"microseconds":Time.get_ticks_usec()-began}

func clear_bodies(members: Array,motion: WolfAnimalMotion,player: Vector2) -> bool:
	for member in members:
		if not motion.body_step_free(member.p,member.p,member,members,player):return false
	return true

func run() -> void:
	var motion := WolfAnimalMotion.new();motion.configure(0,[])
	var members: Array = [wolf(Vector2(1490,1600)),wolf(Vector2(1600,1735),"Vater",1.2),wolf(Vector2(1690,1590),"Geschwister",2.4,true),wolf(Vector2(1570,1500),"Geschwister",3.6,true)]
	var ctx := context(Vector2(1600,1600))
	var cohort_source: Array = [{"kind":"deer"}]+members+[wolf(Vector2(2200,2200),"Vater",8)]
	check(PACK.cohort(cohort_source).size() == 4,"pack planning is bounded to four wolves and excludes wildlife")
	var notice: Dictionary = PACK.plan(members[0],members,motion,ctx)
	check(notice.behavior == "notice" and notice.speed == 0 and notice.attention > 0.5,"a quiet nearby pup is noticed before a parent approaches")
	var result := simulate(members,motion,ctx,180)
	check(result.safe and result.bounded and result.bodies,"all four social approaches use real bounded body-aware movement")
	check(result.approached.size() == 4,"mother, father and both young wolves make short local approaches")
	check(result.greeted.size() >= 3,"the family reaches actual separate greeting places rather than just changing text")
	check(clear_bodies(members,motion,ctx.player_pos),"greeting positions leave every torso and the player's body clear")
	for member in members:
		check(member.p.distance_to(ctx.player_pos) >= motion.body_radius(member)+25+3-0.01,"greeting keeps the "+str(member.role)+" outside the pup's body")
	var old_target: Vector2 = members[0].get("_social_target",members[0].p)
	ctx.player_speed = 90;ctx.player_pos += Vector2(250,0)
	var ended: Dictionary = PACK.plan(members[0],members,motion,ctx)
	check(ended.behavior not in ["greet","approach"] and ended.target != old_target,"a greeting ends when the pup leaves; the family does not become permanent followers")

	# An explicit fresh action starts a new brief response, once per serial.
	var invited := wolf(Vector2(1440,1600))
	var invitation: Array = [invited]
	var invite_ctx := context(Vector2(1560,1600))
	invite_ctx.signal = {"action":"greet","region":0,"serial":1,"at":0.0}
	var invite_result := simulate(invitation,motion,invite_ctx,135)
	check(invite_result.greeted.size() == 1 and invite_result.bodies,"a real greeting action produces an actual short approach and friendly halt")
	var expires: float = invited._social_until
	PACK.plan(invited,invitation,motion,invite_ctx)
	check(invited._social_until == expires,"repeated frames of one greeting signal cannot restart its duration")
	invite_ctx.signal = {"action":"greet","region":0,"serial":2,"at":invite_ctx.elapsed}
	PACK.plan(invited,invitation,motion,invite_ctx)
	check(float(invited._social_until) > expires,"a later real greeting can invite another friendly response")
	invited.companion = true;invite_ctx.escort = true
	var companion_greet: Dictionary = PACK.plan(invited,invitation,motion,invite_ctx)
	check(companion_greet.mood == "begrüßen" and companion_greet.speed == 0,"a nearby escort mother also responds physically to a new greeting")
	invite_ctx.howling = true
	check(PACK.plan(invited,invitation,motion,invite_ctx).mood == "heulen","an escort mother can reply to a real call without losing mission priority")
	invited.companion = false
	var adult_player := context(Vector2(1600,1600));adult_player.player_radius = 40.0
	var adult_group: Array = [wolf(Vector2(1490,1600)),wolf(Vector2(1690,1640),"Geschwister",2.4,true)]
	var adult_result := simulate(adult_group,motion,adult_player,130)
	var adult_spacing := true
	for member in adult_group:
		if not motion.body_step_free(member.p,member.p,member,adult_group,adult_player.player_pos,40):adult_spacing = false
	check(adult_result.greeted.size() == 2 and adult_result.bodies and adult_spacing,"greeting places also respect a fully grown saved player's larger real body")

	# Opposing bodies must walk around one another, not veto both whole routes.
	var crossing: Array = [wolf(Vector2(1300,1600)),wolf(Vector2(1740,1600),"Vater",1.2)]
	var cross_safe := true
	var cross_bounded := true
	for i in range(400):
		for index in range(2):
			var animal: Dictionary = crossing[index]
			var before: Vector2 = animal.p
			var target := Vector2(1780,1600) if index == 0 else Vector2(1260,1600)
			var next := motion.advance_pack(animal,target,90,0.035,i*0.035,crossing,Vector2(2600,2600))
			if not motion.body_step_free(before,next,animal,crossing,Vector2(2600,2600)):cross_safe = false
			if before.distance_to(next) > 90*0.035+0.001:cross_bounded = false
			animal.p = next
	check(cross_safe and cross_bounded,"opposing pack members sweep each other's bodies without teleporting")
	check(crossing[0].p.distance_to(Vector2(1780,1600)) < 10 and crossing[1].p.distance_to(Vector2(1260,1600)) < 10,"opposing pack routes make progress instead of mutually freezing")
	check(motion.player_step_free(Vector2(1550,1600),Vector2(1650,1600),[wolf(Vector2(1600,1600))]) == false,"the player cannot sweep through a standing parent even when both endpoints are free")
	check(motion.player_step_free(Vector2(1550,1600),Vector2(1520,1600),[wolf(Vector2(1600,1600))]),"a player already touching an old cached body can take real separating steps")
	# A held stick can be blocked at a true body boundary with measured speed0.
	# The parent must walk out of the way, not treat that input as quiet company.
	var yielding := wolf(Vector2(1600,1683));yielding.companion = true
	var yielding_group: Array = [yielding]
	var yield_ctx := context(Vector2(1600,1600));yield_ctx.player_facing = Vector2.DOWN;yield_ctx.player_mood = "laufen";yield_ctx.player_radius = 40.0;yield_ctx.escort = true
	var initial_body: Vector2 = yielding.p
	check(not motion.player_step_free(yield_ctx.player_pos,yield_ctx.player_pos+Vector2(0,4),yielding_group,40),"a held forward stick is genuinely blocked by a standing parent body")
	var yield_plan: Dictionary = PACK.plan(yielding,yielding_group,motion,yield_ctx)
	check(yield_plan.behavior == "yield" and yield_plan.speed > 0 and yielding.p == initial_body,"blocked movement requests a friendly side step without directly moving the parent's position")
	var yield_safe := true
	var highest_side := 0.0
	for tick in range(150):
		var before_player: Vector2 = yield_ctx.player_pos
		var requested: Vector2 = before_player+Vector2(0,120*0.035)
		if motion.player_step_free(before_player,requested,yielding_group,40):yield_ctx.player_pos = requested
		yield_ctx.player_speed = before_player.distance_to(yield_ctx.player_pos)/0.035
		yield_ctx.now += 0.035;yield_ctx.elapsed += 0.035
		var before: Vector2 = yielding.p
		var step_plan: Dictionary = PACK.plan(yielding,yielding_group,motion,yield_ctx)
		var next := motion.advance_pack(yielding,step_plan.target,step_plan.speed,0.035,yield_ctx.now,yielding_group,yield_ctx.player_pos,40)
		if not motion.segment_free(before,next) or not motion.body_step_free(before,next,yielding,yielding_group,yield_ctx.player_pos,40) or before.distance_to(next) > maxf(34.0,float(step_plan.speed))*0.035+0.001:yield_safe = false
		yielding.p = next;yielding.speed = before.distance_to(next)/0.035
		highest_side = maxf(highest_side,absf(next.x-initial_body.x))
	check(yield_safe and highest_side > 80,"the parent really walks sideways and leaves both bodies separated throughout the held input")
	check(yield_ctx.player_pos.y > initial_body.y+35,"the held stick can continue past the parent without teleportation or disabling body checks")
	yield_ctx.player_mood = "lauschen";yield_ctx.player_speed = 0
	check(PACK.plan(yielding,yielding_group,motion,yield_ctx).behavior != "yield","the short side step ends when actual movement intent stops")

	# A legacy overlap is resolved solely by walking, including an idle animal.
	var overlapped := wolf(Vector2(1600,1600))
	var overlap_group: Array = [overlapped]
	var overlap_start: Vector2 = overlapped.p
	var overlap_safe := true
	for i in range(100):
		var before: Vector2 = overlapped.p
		var next := motion.advance_pack(overlapped,overlapped.p,0,0.035,i*0.035,overlap_group,Vector2(1600,1600))
		if before.distance_to(next) > 34*0.035+0.001 or not motion.body_step_free(before,next,overlapped,overlap_group,Vector2(1600,1600)):overlap_safe = false
		overlapped.p = next
	check(overlap_safe and overlapped.p.distance_to(overlap_start) >= 68,"an old overlap is resolved by small honest steps even from an idle pose")
	check(overlapped.p.distance_to(overlap_start) < 71,"overlap recovery stops once bodies are clear instead of pushing an animal far away")

	# First home halt: the mother was left at her morning routine north of den.
	# A physical south entrance is visible to the pup but hidden from mother.
	var home := WolfWorldData.generate(0)
	var home_motion := WolfAnimalMotion.new();home_motion.configure(0,home.objects)
	var family: Array = PACK.cohort(home.animals)
	family[0].p = Vector2(1450,1890)
	var home_ctx := context(Vector2(1579.677,2316.123));home_ctx.meeting = true;home_ctx.meeting_center = Vector2(1580,2180)
	check(not home_motion.segment_free(family[0].p,home_ctx.player_pos),"the first home halt starts with mother genuinely occluded by the den")
	var home_result := simulate(family,home_motion,home_ctx,650)
	check(home_result.safe and home_result.bounded and home_result.bodies,"the mother and family physically detour around the den and each other")
	check(family[0].p.distance_to(home_ctx.player_pos) < 125 and home_motion.segment_free(family[0].p,home_ctx.player_pos),"mission-priority meeting brings the mother to reachable real pup proximity without escort")
	check(family[0].speed <= 1 and family[0].behavior == "meeting","mother actually stands still for the home halt rather than passing a fake proximity flag")
	check(clear_bodies(family,home_motion,home_ctx.player_pos),"den meeting retains separate bodies for every family member")
	home_ctx.signal = {"action":"greet","region":0,"serial":3,"at":home_ctx.elapsed};home_ctx.howling = true
	var priority: Dictionary = PACK.plan(family[0],family,home_motion,home_ctx)
	check(priority.behavior == "meeting" and priority.speed == 0,"the real mission halt outranks both greeting and howl routines")
	home_ctx.player_mood = "ruhen"
	var resting: Dictionary = PACK.plan(family[0],family,home_motion,home_ctx)
	check(resting.mood == "ruhen" and resting.speed == 0,"an arrived mother can share real calm rest at the home halt")
	var edge_mother := wolf(Vector2(1450,1890))
	var edge_ctx := context(Vector2(1580,1930));edge_ctx.meeting = true;edge_ctx.meeting_center = Vector2(1580,2180)
	var edge_result := simulate([edge_mother],home_motion,edge_ctx,400)
	check(edge_result.safe and edge_result.bodies and edge_mother.p.distance_to(edge_ctx.player_pos) < 125 and edge_mother.p.distance_to(edge_ctx.meeting_center) < 300 and edge_mother.speed <= 1,"at the north meeting boundary mother enters both the real home zone and pup proximity before stopping")

	# Genuine intra-family greetings at a quiet daytime home, without player bait.
	var peers: Array = [wolf(Vector2(1400,1600)),wolf(Vector2(1710,1600),"Vater",1.2),wolf(Vector2(1545,1600),"Geschwister",2.4,true),wolf(Vector2(1850,1600),"Geschwister",3.6,true)]
	var peer_ctx := context(Vector2(2500,2500));peer_ctx.hour = 13;peer_ctx.now = 12
	var peer_result := simulate(peers,motion,peer_ctx,175)
	check(peer_result.greeted.size() >= 2,"a parent and young wolf exchange a brief actual greeting with one another")
	check(peer_result.safe and peer_result.bodies and clear_bodies(peers,motion,peer_ctx.player_pos),"intra-family greetings keep both shared rest approaches and torsos physically clear")

	var river := WolfAnimalMotion.new();river.configure(2,[])
	var escort := wolf(Vector2(740,1120));escort.companion = true
	var river_ctx := context(Vector2(1280,1120));river_ctx.region = 2;river_ctx.escort = true
	var river_result := simulate([escort],river,river_ctx,550)
	check(river_result.safe and river_result.bounded and river_result.bodies,"body-aware escort still respects actual river water and bridge openings")
	check(escort.p.distance_to(river_ctx.player_pos) < 125 and river.segment_free(escort.p,river_ctx.player_pos),"the parent completes a real bridge detour to the waiting pup")
	var night := wolf(Vector2(1770,2480))
	var night_ctx := context(Vector2(2600,2600));night_ctx.hour = 23
	var night_result := simulate([night],motion,night_ctx,1250)
	check(night_result.safe and night.p.distance_to(WolfPackLife.routine(23,"Mutter").target) < 18 and night.mood == "ruhen" and night.speed == 0,"short social behaviour preserves an actual protected night return and rest")
	var night_family: Array = PACK.cohort(WolfWorldData.generate(0).animals)
	var night_family_ctx := context(Vector2(2600,2600));night_family_ctx.hour = 23
	var before_routes := home_motion.pack_route_count
	var night_family_result := simulate(night_family,home_motion,night_family_ctx,2300)
	var all_resting := true
	for member in night_family:
		if member.mood != "ruhen" or member.speed > 1:
			all_resting = false
			print("Night arrival still moving: ",member.role," phase=",member.phase," pos=",member.p," goal=",member.get("_motion_goal")," path=",member.get("_motion_path")," mood=",member.mood," speed=",member.speed)
			for sibling in night_family:print("Night cohort: ",sibling.role," ",sibling.phase," ",sibling.p)
			for point in member.get("_motion_path",[]):print("Night mark: ",point," body=",home_motion.body_step_free(point,point,member,night_family,night_family_ctx.player_pos)," static=",home_motion.segment_free(member.p,point))
	check(night_family_result.safe and night_family_result.bodies and clear_bodies(night_family,home_motion,night_family_ctx.player_pos),"the whole family reaches separate actual night places, including both siblings")
	check(all_resting,"all four wolves eventually lie quietly at night instead of circling a body-blocked sibling target")
	var restored_graph := home_motion.navigation != null
	if restored_graph:
		for id in home_motion.navigation.get_point_ids():
			if home_motion.navigation.is_point_disabled(id):restored_graph = false
	check(restored_graph,"temporary body reservations restore every shared navigation node before returning")
	check(home_motion.pack_route_count-before_routes > 0 and home_motion.pack_route_count-before_routes <= 8,"the obstructed night approach needs only a bounded handful of body detours")
	print("Four-wolf night controller: %.1f us/frame, %d extra body routes in %.1f active seconds" % [float(night_family_result.microseconds)/2300,home_motion.pack_route_count-before_routes,2300*0.035])
	var howl_ctx := context(invited.p+Vector2(90,0));howl_ctx.now = 1;howl_ctx.howling = true
	var howl_plan: Dictionary = PACK.plan(invited,invitation,motion,howl_ctx)
	check(howl_plan.mood == "heulen" and howl_plan.speed == 0,"a real nearby call receives a brief pack reply ahead of ordinary greeting")

	# Optional shared play uses the same local body-aware navigation as greeting.
	# It must neither move the pup nor forge a mission/escort checkpoint.
	var playful := wolf(Vector2(1450,1600),"Geschwister",2.4,true)
	var play_group: Array = [playful]
	var play_ctx := context(Vector2(1600,1600))
	play_ctx.signal = {"action":"play","region":0,"serial":91,"at":0.0}
	var first_play: Dictionary = PACK.plan(playful,play_group,motion,play_ctx)
	check(first_play.behavior == "play_approach" and first_play.speed > 0,"a deliberate play signal calls a nearby sibling along a real path")
	var play_result := simulate(play_group,motion,play_ctx,165)
	check(play_result.played.size() == 1,"sibling actually reaches a playful animation position")
	check(play_result.safe and play_result.bounded and play_result.bodies and clear_bodies(play_group,motion,play_ctx.player_pos),"play remains body-safe and moves at bounded speed")
	var play_until: float = playful._play_until
	PACK.plan(playful,play_group,motion,play_ctx)
	check(is_equal_approx(float(playful._play_until),play_until),"the same play signal cannot extend its duration frame by frame")
	play_ctx.signal = {"action":"play","region":0,"serial":92,"at":play_ctx.elapsed}
	PACK.plan(playful,play_group,motion,play_ctx)
	check(float(playful._play_until) > play_until,"a fresh deliberate play event can start a new short turn")
	play_ctx.player_pos += Vector2(350,0)
	play_ctx.player_speed = 90
	var departed: Dictionary = PACK.plan(playful,play_group,motion,play_ctx)
	check(departed.behavior not in ["play","play_approach"],"the wolf stops playing and does not follow indefinitely when the pup runs off")
	var mission_play := context(Vector2(1580,2320))
	mission_play.meeting = true;mission_play.meeting_center = Vector2(1580,2180)
	mission_play.signal = {"action":"play","region":0,"serial":93,"at":0.0}
	var mission_parent := wolf(Vector2(1570,2280))
	var mission_plan: Dictionary = PACK.plan(mission_parent,[mission_parent],home_motion,mission_play)
	check(mission_plan.behavior == "meeting","home mission proximity outranks optional play invitations")

	var hashes := ""
	for region in range(WolfWorldData.REGIONS.size()):hashes += JSON.stringify(WolfWorldData.generate(region)).sha256_text()
	check(hashes.sha256_text() == WORLD_HASH,"all 256 generated regions retain the published seed/object/animal/track hash")
	print("Wolf pack interactions: %d checks, %d failures" % [checks,errors])
	quit(1 if errors > 0 else 0)
