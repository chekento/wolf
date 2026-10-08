class_name WolfHabitatDetails
extends RefCounted

# Decorative plans reference existing decor indices only. They do not append
# world objects, consume the generator's RNG or participate in collisions.
const MAX_CACHED := 16
const MAX_CHUNKS := 6
const PER_CHUNK := 16
const FOOTPRINT := 36.0
static var cache: Dictionary = {}
static var recent: Array[int] = []

static func for_region(region: int,world: Dictionary) -> Dictionary:
	if not cache.has(region):cache[region]=build(region,world)
	recent.erase(region);recent.append(region)
	while recent.size()>MAX_CACHED:cache.erase(recent.pop_front())
	return cache[region]

static func kinds_for(biome: String) -> Array[String]:
	match biome:
		"forest","oak","pine","ruins":return ["habitat_litter","habitat_fungi","habitat_deadwood"]
		"river","lake","coast":return ["habitat_pebbles","habitat_driftwood"]
		"marsh":return ["habitat_sedge","habitat_moss"]
		"snow","alpine":return ["habitat_frostwood","habitat_snowtufts"]
	return ["habitat_herbs","habitat_seedheads"]

static func _chunk(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x*WolfWorldView.UNIT/24.0),floori(point.y*WolfWorldView.UNIT/24.0))

static func _clear_of_trail(point: Vector2,paths: Dictionary) -> bool:
	# The shared trail hash reserves 16-unit query padding. Inspect adjacent
	# cells for our wider tiny-group footprint without scanning every arm.
	var cell := Vector2i(point/128)
	for y in range(-1,2):
		for x in range(-1,2):
			for segment in paths.segment_cells.get(cell+Vector2i(x,y),[]):
				var delta: Vector2=segment.b-segment.a
				var t := clampf((point-segment.a).dot(delta)/maxf(delta.length_squared(),.001),0,1)
				var width: float=lerpf(segment.aw,segment.bw,t)+FOOTPRINT+8
				if lerpf(segment.af,segment.bf,t)>.1 and point.distance_squared_to(segment.a+delta*t)<width*width:return false
	return true

static func build(region: int,world: Dictionary) -> Dictionary:
	var biome: String=WolfWorldData.REGIONS[region].biome
	var paths := WolfWorldData.render_paths(region,world.objects)
	var collision := WolfCollisionIndex.new();collision.build(world.objects)
	var candidates: Array[Dictionary]=[]
	for index in range(world.decor.size()):
		var decor: Dictionary=world.decor[index]
		var point: Vector2=decor.p
		# Match the existing sparse alpine/snow/coast understory exactly.
		if index%3==0 and biome in ["snow","alpine","coast"]:continue
		if not Rect2(Vector2(80,80),Vector2(3040,3040)).has_point(point):continue
		if not _clear_of_trail(point,paths):continue
		var available := true
		for offset in [Vector2.ZERO,Vector2(FOOTPRINT,FOOTPRINT),Vector2(-FOOTPRINT,FOOTPRINT),Vector2(FOOTPRINT,-FOOTPRINT),Vector2(-FOOTPRINT,-FOOTPRINT)]:
			if not collision.walkable(point+offset) or WolfWorldData.water_blocked(point+offset,region):available=false;break
		if not available:continue
		for object in world.objects:
			if object.kind=="den" and point.distance_to(object.p)<150:available=false;break
		if available:candidates.append({"index":index,"p":point,"chunk":_chunk(point)})
	var targets: Array[Dictionary]=[{"p":WolfWorldData.water_bank(region),"shore":true}]
	if region==0:targets.append({"p":WolfWorldData.SPAWN,"shore":false})
	for object in world.objects:
		if object.kind=="discovery":targets.append({"p":object.p,"shore":false})
	for object in world.objects:
		if object.kind=="food":targets.append({"p":object.p,"shore":false})
	var chosen := {}
	var biome_kinds := kinds_for(biome)
	for target in targets:
		if chosen.size()>=MAX_CHUNKS:break
		var nearest: Dictionary={}
		var distance := INF
		for candidate in candidates:
			if chosen.has(candidate.chunk):continue
			var d: float=candidate.p.distance_squared_to(target.p)
			if d<distance:distance=d;nearest=candidate
		if nearest.is_empty():continue
		var cell: Vector2i=nearest.chunk
		var palette: Array[String]=[]
		if target.shore and biome in ["forest","oak","pine","meadow","lake","river"]:palette.assign(["habitat_pebbles","habitat_driftwood"])
		else:palette.assign(biome_kinds)
		# Rotate recipes across selected habitat cells, so the home forest
		# always shows leaves, fungi and deadwood rather than repeated litter.
		var kind: String=palette[posmod(chosen.size()+region,palette.size())]
		chosen[cell]={"kind":kind,"target":target.p}
	var entries := {}
	for cell in chosen:
		var nearby: Array[Dictionary]=[]
		for candidate in candidates:
			if candidate.chunk==cell:
				nearby.append({"index":candidate.index,"p":candidate.p,"score":candidate.p.distance_squared_to(chosen[cell].target)})
		nearby.sort_custom(func(a: Dictionary,b: Dictionary):return a.score<b.score if not is_equal_approx(a.score,b.score) else a.index<b.index)
		for candidate in nearby.slice(0,PER_CHUNK):
			var index: int=candidate.index
			var scale := .82+clampf(float(world.decor[index].size)/12.0,0,1)*.24
			entries[index]={"index":index,"p":candidate.p,"kind":chosen[cell].kind,"scale":scale,"rotation":fposmod(float(index)*2.399+float(region)*.47,TAU),"tint":Color.WHITE.darkened(float(index%4)*.022),"chunk":cell}
	return {"region":region,"biome":biome,"entries":entries,"chunks":chosen,"maximum":MAX_CHUNKS*PER_CHUNK}
