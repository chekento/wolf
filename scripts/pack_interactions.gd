class_name WolfPackInteractions
extends RefCounted

# Live, regional behaviour only. No world-generation RNG or saved coordinates
# are changed. Four wolves are the complete home cohort, not a growing flock.
const MAX_MEMBERS := 4
const PLAYER_RADIUS := 25.0

static func cohort(animals: Array) -> Array:
	var members: Array = []
	for animal in animals:
		if animal.get("kind", "") != "wolf":continue
		members.append(animal)
		if members.size() == MAX_MEMBERS:break
	return members

static func plan(animal: Dictionary,members: Array,navigation: WolfAnimalMotion,context: Dictionary) -> Dictionary:
	var position: Vector2 = animal.p
	var player: Vector2 = context.player_pos
	var player_radius: float = float(context.get("player_radius",PLAYER_RADIUS))
	var distance := position.distance_to(player)
	var now: float = context.now
	animal._near_active_until = -1.0
	var quiet: bool = float(context.player_speed) <= 1.0 and context.player_mood != "laufen"
	var parent: bool = not animal.get("young",false) and (animal.get("role","") == "Mutter" or animal.get("companion",false))
	var accompanying: bool = animal.get("companion",false) or (bool(context.escort) and animal.get("role","") == "Mutter")
	var meeting: bool = parent and bool(context.get("meeting",false))
	var visible: bool = distance < 380 and navigation.segment_free(position,player)
	var result := _routine(animal,members,navigation,context)
	result.attention = clampf(1.0-distance/380.0,0.0,0.65) if visible else 0.0
	# Zero measured speed can mean a pup is pressing against a real body.
	# Its requested world direction still lives in facing/mood. Make room by
	# walking aside; never misread that blocked input as an invitation to rest.
	var give_way := _yield_request(animal,members,navigation,context,player_radius)
	if give_way.is_finite():
		result.target = give_way;result.speed = 55.0;result.mood = "wandern";result.behavior = "yield"
		result.look_target = player;result.attention = 0.65
		return result
	var invitation: Dictionary = context.get("signal",{})
	if not invitation.is_empty() and invitation.get("action","") == "greet" and int(invitation.get("region",-1)) == int(context.region) and float(context.elapsed)-float(invitation.get("at",-100)) < 4 and distance < 155:
		var event := "%d:%d" % [int(invitation.region),int(invitation.serial)]
		if event != str(animal.get("_social_event","")):
			animal._social_event = event
			animal._social_until = now+4.5
			animal._social_anchor = player
			animal._social_cooldown = now+30.0+float(animal.get("phase",0))*2
	# A deliberate family play invitation is an ephemeral, local signal.
	# Wolves travel to safe individual play spots instead of teleporting
	# into an animation, and unrelated animals do not react.
	if not invitation.is_empty() and invitation.get("action","") == "play" and (str(invitation.get("target","")).is_empty() or str(invitation.target)==WolfPackLife.animal_key(animal)) and int(invitation.get("region",-1)) == int(context.region) and float(context.elapsed)-float(invitation.get("at",-100)) >= 0 and float(context.elapsed)-float(invitation.get("at",-100)) < 4 and distance < 210:
		var play_event := "%d:%d" % [int(invitation.region),int(invitation.serial)]
		if play_event != str(animal.get("_play_event","")):
			animal._play_event = play_event
			animal._play_until = now+7.0
			animal._play_anchor = player
	# Cuddling is a targeted invitation: only the selected real family
	# member responds by walking to a safe place, never teleporting.
	if not invitation.is_empty() and invitation.get("action","")=="cuddle" and str(invitation.get("target",""))==WolfPackLife.animal_key(animal) and int(invitation.get("region",-1))==int(context.region) and float(context.elapsed)-float(invitation.get("at",-100))>=0 and float(context.elapsed)-float(invitation.get("at",-100))<4 and distance<190:
		var cuddle_event := "%d:%d"%[int(invitation.region),int(invitation.serial)]
		if cuddle_event != str(animal.get("_cuddle_event","")):
			animal._cuddle_event=cuddle_event
			animal._cuddle_until=now+5.5
			animal._cuddle_anchor=player
	if bool(context.get("howling",false)) and distance < 500 and not meeting:
		result.target = position;result.speed = 0.0;result.mood = "heulen";result.look_target = player;result.attention = 0.7
		return result
	# A real mission halt outranks calls, greeting invitations and sibling play.
	# Rest/arrival is reported only after actually walking within a clear 125.
	if meeting or accompanying:
		animal.erase("_peer_until")
		animal.erase("_notice_at")
		var goal_center: Vector2 = context.get("meeting_center",Vector2(INF,INF)) if meeting else Vector2(INF,INF)
		var goal_radius: float = float(context.get("meeting_radius",300.0))
		var within_goal: bool = not goal_center.is_finite() or position.distance_to(goal_center) < goal_radius-2.0
		var arrived: bool = within_goal and distance < 122 and visible and navigation.body_step_free(position,position,animal,members,player,player_radius)
		var preferred: Vector2 = player-Vector2(context.player_facing)*105+Vector2(18,15)
		if quiet or meeting:preferred = player+player.direction_to(position)*100
		if goal_center.is_finite() and not within_goal:preferred = player+player.direction_to(goal_center)*100
		animal._near_active_until = now+0.2
		result.target = position if arrived else _near_target(animal,members,navigation,player,preferred,100.0,"meeting" if meeting else "escort",now,goal_center,goal_radius,player_radius)
		result.speed = 0.0 if arrived else 220.0 if distance > 500 else 175.0 if distance > 340 else 125.0 if distance > 200 else 70.0
		result.mood = ("ruhen" if context.player_mood == "ruhen" else "lauschen") if arrived else "begleiten"
		var friendly: bool = not meeting and arrived and quiet and now < float(animal.get("_social_until",-1)) and context.player_mood != "ruhen"
		if friendly:result.mood = "begrüßen"
		result.behavior = "meeting" if meeting else "greet" if friendly else "escort"
		result.look_target = player
		result.attention = 0.65
		return result
	if now<float(animal.get("_cuddle_until",-1)) and not meeting and not accompanying:
		var cuddle_anchor: Vector2=animal.get("_cuddle_anchor",player)
		if cuddle_anchor.distance_to(player)>155 or float(context.player_speed)>55:
			animal._cuddle_until=-1.0
		else:
			var space := maxf(65.0 if animal.get("young",false) else 82.0,navigation.body_radius(animal)+player_radius+10.0)
			var away := player.direction_to(position)
			if away.length_squared()<.01:away=Vector2.from_angle(float(animal.get("phase",0))+.3)
			var nearby_point := player+away*space
			animal._near_active_until=now+.2
			var cuddle_target := _near_target(animal,members,navigation,player,nearby_point,space,"cuddle",now,Vector2(INF,INF),INF,player_radius)
			var reached: bool=position.distance_to(cuddle_target)<10 and visible
			result.target=position if reached else cuddle_target
			result.speed=0.0 if reached else 42.0
			result.mood="begrüßen" if reached else "wandern"
			result.behavior="cuddle" if reached else "cuddle_approach"
			result.look_target=player
			result.attention=.95
			return result
	# Mission halts and escort navigation outrank play. Otherwise a playful
	# invitation produces a real approach, a bow and a wagging tail. Releasing
	# the player position or beginning to run cancels the play naturally.
	if now < float(animal.get("_play_until",-1)):
		var play_anchor: Vector2 = animal.get("_play_anchor",player)
		if play_anchor.distance_to(player) > 155 or float(context.player_speed) > 55:
			animal._play_until = -1.0
		else:
			var radius := maxf(88.0 if not animal.get("young",false) else 76.0,navigation.body_radius(animal)+player_radius+15.0)
			var away := player.direction_to(position)
			if away.length_squared() < 0.01:away = Vector2.from_angle(float(animal.get("phase",0))+.4)
			var preferred := player+away*radius
			animal._near_active_until = now+0.2
			var target := _near_target(animal,members,navigation,player,preferred,radius,"play",now,Vector2(INF,INF),INF,player_radius)
			var arrived: bool = position.distance_to(target) < 8 and visible
			result.target = position if arrived else target
			result.speed = 0.0 if arrived else 64.0
			result.mood = "spielen" if arrived else "wandern"
			result.behavior = "play" if arrived else "play_approach"
			result.look_target = player
			result.attention = 0.95
			return result
	# Nearby quiet family members first notice the pup, then make a short
	# invitation. It ends naturally; this is not a second permanent escort.
	var may_notice: bool = visible and distance < 210 and quiet and now >= float(animal.get("_social_cooldown",-1))
	if may_notice:
		if not animal.has("_notice_at"):animal._notice_at = now
		var delay := 0.6 if parent else 1.1 if not animal.get("young",false) else 1.6
		if now-float(animal._notice_at) >= delay:
			animal._social_until = now+5.0
			animal._social_anchor = player
			animal._social_cooldown = now+38.0+float(animal.get("phase",0))*2
			animal.erase("_notice_at")
		else:
			result.target = position;result.speed = 0.0;result.mood = "lauschen";result.behavior = "notice";result.attention = 0.7
			result.look_target = player
	else:animal.erase("_notice_at")
	if now < float(animal.get("_social_until",-1)):
		var invited_at: Vector2 = animal.get("_social_anchor",player)
		if invited_at.distance_to(player) > 130 or float(context.player_speed) > 45:
			animal._social_until = -1.0
		else:
			var radius := maxf(82.0 if not animal.get("young",false) else 70.0,navigation.body_radius(animal)+player_radius+14.0)
			var preferred: Vector2 = player+player.direction_to(position)*radius
			animal._near_active_until = now+0.2
			var target := _near_target(animal,members,navigation,player,preferred,radius,"greet",now,Vector2(INF,INF),INF,player_radius)
			var arrived: bool = position.distance_to(target) < 7 and visible
			result.target = position if arrived else target
			result.speed = 0.0 if arrived else 36.0
			result.mood = ("ruhen" if context.player_mood == "ruhen" else "begrüßen") if arrived else "wandern"
			result.behavior = "social" if arrived and context.player_mood == "ruhen" else "greet" if arrived else "approach"
			result.look_target = player;result.attention = 0.9
			return result
	if int(context.region) == 0 and not accompanying and not meeting and distance > 230 and float(context.hour) >= 8 and float(context.hour) < 21:
		_start_peer(animal,members,navigation,context)
		if now < float(animal.get("_peer_until",-1)):
			var peer := _find(members,str(animal.get("_peer_key","")))
			if not peer.is_empty() and position.distance_to(peer.p) < 240:
				var goal: Vector2 = animal._peer_goal
				var arrived: bool = position.distance_to(goal) < 7
				result.target = position if arrived else goal;result.speed = 0.0 if arrived else 34.0
				result.mood = "begrüßen" if arrived else "wandern";result.behavior = "social"
				result.look_target = peer.p;result.attention = 0.8
				return result
	return result

static func _yield_request(animal: Dictionary,members: Array,navigation: WolfAnimalMotion,context: Dictionary,player_radius: float) -> Vector2:
	var now: float = context.now
	if context.player_mood != "laufen":
		animal.erase("_yield_until")
		return Vector2(INF,INF)
	var direction: Vector2 = context.player_facing
	if direction.length_squared() < 0.01:return Vector2(INF,INF)
	direction = direction.normalized()
	var cached: Vector2 = animal.get("_yield_target",Vector2(INF,INF))
	if now < float(animal.get("_yield_until",-1)) and cached.is_finite() and animal.p.distance_to(cached) > 5 and navigation.walkable(cached):return cached
	var offset: Vector2 = animal.p-context.player_pos
	var radius := navigation.body_radius(animal)+player_radius+3.0
	var side := direction.orthogonal()
	if offset.dot(direction) < 0 or offset.dot(direction) > radius+28 or absf(offset.dot(side)) > radius+6:return Vector2(INF,INF)
	var sign_side := 1.0 if offset.dot(side) >= 0 else -1.0
	for sign_value in [sign_side,-sign_side]:
		for lateral in [90.0,70.0]:
			var target: Vector2 = animal.p+side*float(sign_value)*float(lateral)
			if not navigation.segment_free(animal.p,target) or not navigation.body_step_free(target,target,animal,members,context.player_pos,player_radius):continue
			animal._yield_target = target;animal._yield_until = now+1.8
			return target
	return Vector2(INF,INF)

static func _routine(animal: Dictionary,members: Array,navigation: WolfAnimalMotion,context: Dictionary) -> Dictionary:
	var result: Dictionary = WolfPackLife.routine(float(context.hour),str(animal.get("role","Mutter"))).duplicate()
	if int(context.region) != 0:result = {"target":animal.home,"speed":24.0,"mood":"wandern"}
	if animal.get("young",false):
		# The older 45/35 offset left the siblings' sleeping torsos overlapping.
		# These are walked routine destinations, never generator/save positions.
		if float(animal.get("phase",0)) > 3:result.target += Vector2(75,75)
		if result.mood == "spielen":
			var partner: Dictionary = {}
			for member in members:
				if member != animal and member.get("young",false):partner = member;break
			result = WolfPackLife.sibling_play(animal,partner,result.target,float(context.now))
	var free := navigation.nearest_free(result.target)
	if free.is_finite():result.target = free
	var arrived: bool = animal.p.distance_to(result.target) < 12
	if result.mood == "ruhen":
		if arrived:result.speed = 0.0
		else:result.mood = "wandern"
	elif arrived and result.mood == "wandern":result.speed = 0.0;result.mood = "lauschen"
	result.behavior = result.get("behavior","routine")
	result.look_target = result.target
	result.attention = 0.0
	return result

static func _near_target(animal: Dictionary,members: Array,navigation: WolfAnimalMotion,anchor: Vector2,preferred: Vector2,radius: float,mode: String,now: float,goal_center: Vector2=Vector2(INF,INF),goal_radius: float=INF,player_radius: float=PLAYER_RADIUS) -> Vector2:
	var cached: Vector2 = animal.get("_social_target",Vector2(INF,INF))
	var old_anchor: Vector2 = animal.get("_social_target_anchor",Vector2(INF,INF))
	if cached.is_finite() and (not goal_center.is_finite() or cached.distance_to(goal_center) < goal_radius-4.0) and old_anchor.distance_to(anchor) < 24 and str(animal.get("_social_target_mode","")) == mode and navigation.segment_free(cached,anchor) and _target_clear(cached,anchor,animal,members,navigation,now,player_radius):return cached
	var direction := anchor.direction_to(preferred)
	if direction.length_squared() < 0.01:direction = Vector2.from_angle(float(animal.get("phase",0))+0.4)
	# Unlike nearest_free(player), every candidate leaves the pup's real body
	# clear and has an unobstructed line back to the meeting, including at den.
	var offsets: Array = [0.0,0.40,-0.40,0.85,-0.85,1.3,-1.3,1.8,-1.8,2.4,-2.4,PI]
	for ring in [radius,minf(118.0,radius+18.0)]:
		for offset in offsets:
			var candidate: Vector2 = anchor+direction.rotated(float(offset))*float(ring)
			if goal_center.is_finite() and candidate.distance_to(goal_center) >= goal_radius-4.0:continue
			if not navigation.segment_free(candidate,anchor) or not _target_clear(candidate,anchor,animal,members,navigation,now,player_radius):continue
			animal._social_target = candidate;animal._social_target_anchor = anchor;animal._social_target_mode = mode
			return candidate
	return animal.p

static func _target_clear(point: Vector2,anchor: Vector2,animal: Dictionary,members: Array,navigation: WolfAnimalMotion,now: float,player_radius: float) -> bool:
	if not navigation.body_step_free(point,point,animal,members,anchor,player_radius):return false
	for member in members:
		if member == animal or now >= float(member.get("_near_active_until",-1)) or not member.get("_social_target") is Vector2:continue
		if point.distance_to(member._social_target) < navigation.body_radius(animal)+navigation.body_radius(member)+8.0:return false
	return true

static func _find(members: Array,key: String) -> Dictionary:
	for member in members:
		if WolfPackLife.animal_key(member) == key:return member
	return {}

static func _start_peer(animal: Dictionary,members: Array,navigation: WolfAnimalMotion,context: Dictionary) -> void:
	var now: float = context.now
	var cycle := floori(now/36.0)
	if fposmod(now,36.0) < 12 or fposmod(now,36.0) > 18 or int(animal.get("_peer_cycle",-1)) == cycle:return
	if now < float(animal.get("_peer_until",-1)):return
	var sequence := posmod(cycle,3)
	var wanted := "Geschwister" if sequence == 0 else "Vater" if sequence == 1 else "Geschwister"
	var leader: bool = (sequence == 0 and animal.get("role","") == "Mutter") or (sequence == 1 and animal.get("role","") == "Mutter") or (sequence == 2 and animal.get("young",false) and float(animal.get("phase",0)) < 3)
	if not leader:return
	for peer in members:
		if peer == animal or peer.get("role","") != wanted or peer.get("companion",false) or now < float(peer.get("_peer_until",-1)):continue
		var separation: float = animal.p.distance_to(peer.p)
		if separation < 55 or separation > 225 or not navigation.segment_free(animal.p,peer.p):continue
		var desired := navigation.body_radius(animal)+navigation.body_radius(peer)+18.0
		var center: Vector2 = (animal.p+peer.p)*0.5
		var away: Vector2 = peer.p.direction_to(animal.p)
		var first: Vector2 = center+away*desired*0.5
		var second: Vector2 = center-away*desired*0.5
		if not navigation.walkable(first) or not navigation.walkable(second):continue
		var player_radius: float = float(context.get("player_radius",PLAYER_RADIUS))
		if not navigation.body_step_free(first,first,animal,members,context.player_pos,player_radius) or not navigation.body_step_free(second,second,peer,members,context.player_pos,player_radius):continue
		animal._peer_until = now+6.0;peer._peer_until = now+6.0
		animal._peer_cycle = cycle;peer._peer_cycle = cycle
		animal._peer_key = WolfPackLife.animal_key(peer);peer._peer_key = WolfPackLife.animal_key(animal)
		animal._peer_goal = first;peer._peer_goal = second
		return
