class_name WolfWorldData
extends RefCounted

const SIZE := Vector2(1600, 1600)
const SPAWN := Vector2(790, 970)
const REGIONS := [
	{"name":"Rudelhöhle", "subtitle":"Ein sicherer Anfang unter alten Kiefern", "ground":"#789979", "seed":41, "links":{"east":1,"north":3}},
	{"name":"Kiefernwald", "subtitle":"Harzduft, weicher Moosboden und frische Fährten", "ground":"#527a63", "seed":84, "links":{"west":0,"north":2}},
	{"name":"Flussauen", "subtitle":"Kühles Wasser zwischen Schilf und Birken", "ground":"#87a67b", "seed":127, "links":{"south":1,"west":3}},
	{"name":"Bergwiese", "subtitle":"Weite Blicke und das Heulen aus dem Tal", "ground":"#a4ac87", "seed":172, "links":{"south":0,"east":2}}
]

static func generate(region: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = REGIONS[region].seed
	var objects: Array[Dictionary] = []
	# Main paths cross at the same coordinates in every connected region.
	for i in range(95 if region != 3 else 52):
		var p := Vector2(rng.randf_range(90,1510),rng.randf_range(90,1510))
		if absf(p.x-800)<130 or absf(p.y-800)<115 or p.distance_to(SPAWN)<155:
			continue
		if region == 2 and absf(p.x-480)<145:
			continue
		objects.append({"kind":"tree", "p":p, "scale":rng.randf_range(0.75,1.25), "variant":i%3})
	for i in range(18):
		var p := Vector2(rng.randf_range(110,1490),rng.randf_range(110,1490))
		if absf(p.x-800)>140 and absf(p.y-800)>115 and p.distance_to(SPAWN)>180:
			objects.append({"kind":"rock", "p":p, "scale":rng.randf_range(0.6,1.25),"variant":i%3})
	objects.append({"kind":"water", "p":Vector2(480,800) if region==2 else Vector2(1110,1070), "scale":2.0 if region==2 else 1.0,"variant":1 if region==2 else 0})
	objects.append({"kind":"den", "p":Vector2(790,1090) if region==0 else Vector2(1250,400),"scale":1.0,"variant":0})
	objects.append({"kind":"food", "p":Vector2(690,1020),"scale":1.0,"variant":0})
	objects.append({"kind":"landmark", "p":Vector2(1090,520),"scale":1.0,"variant":0})
	var animals: Array[Dictionary] = []
	for i in range(5):
		animals.append({"kind":"deer" if i<2 else "rabbit", "p":Vector2(900+i*95,650-i*50),"home":Vector2(900+i*95,650-i*50),"phase":float(i)*1.8})
	if region==0:
		animals.append({"kind":"wolf", "p":Vector2(720,1130),"home":Vector2(720,1130),"phase":0.0})
		animals.append({"kind":"wolf", "p":Vector2(880,1120),"home":Vector2(880,1120),"phase":2.5})
	var tracks: Array[Dictionary] = []
	for i in range(7):
		tracks.append({"id":"%d:%d"%[region,i],"p":Vector2(820+i*42,905-i*57),"species":"Reh" if region%2==0 else "Hase", "found":false})
	return {"objects":objects,"animals":animals,"tracks":tracks}

static func solid_radius(obj: Dictionary) -> float:
	match obj.kind:
		"tree": return 23.0*obj.scale
		"rock": return 27.0*obj.scale
		"den": return 54.0
		"water": return 0.0 if obj.variant==1 else 120.0*obj.scale
	return 0.0

static func walkable(p: Vector2, objects: Array) -> bool:
	for obj in objects:
		var r := solid_radius(obj)
		if r>0.0 and p.distance_to(obj.p)<r+13.0:
			return false
	return true

static func exit_at(p: Vector2, region: int) -> String:
	if p.x>1580 and absf(p.y-800)<100 and REGIONS[region].links.has("east"): return "east"
	if p.x<20 and absf(p.y-800)<100 and REGIONS[region].links.has("west"): return "west"
	if p.y<20 and absf(p.x-800)<100 and REGIONS[region].links.has("north"): return "north"
	if p.y>1580 and absf(p.x-800)<100 and REGIONS[region].links.has("south"): return "south"
	return ""

static func entry_point(direction: String) -> Vector2:
	match direction:
		"east":return Vector2(50,800)
		"west":return Vector2(1550,800)
		"north":return Vector2(800,1550)
	return Vector2(800,50)
