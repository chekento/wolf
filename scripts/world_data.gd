class_name WolfWorldData
extends RefCounted

const GRID_SIZE := 8
const SIZE := Vector2(3200,3200)
const CENTER := Vector2(1600,1600)
const SPAWN := Vector2(1580,1940)
const REGION_INFO := [
	["Rudelhöhle","Vertraute Stimmen zwischen Blumen und alten Kiefern","forest",Vector2i(1,2)],
	["Kiefernwald","Harzduft und goldene Fährten unter dichten Kronen","pine",Vector2i(2,2)],
	["Flussauen","Klare Strömung, Schilf und kleine Holzbrücken","river",Vector2i(2,1)],
	["Bergwiese","Wildblumen und weite Blicke in das Tal","meadow",Vector2i(1,1)],
	["Frostgrat","Frischer Schnee knirscht unter deinen Pfoten","snow",Vector2i(0,0)],
	["Schneekiefern","Tierspuren zwischen weiß gepuderten Nadelbäumen","snow",Vector2i(1,0)],
	["Wasserfalltal","Schaum und kühler Sprühnebel am Bach","river",Vector2i(2,0)],
	["Steinbockhöhe","Hohe Felsen und ein weiter Himmel","alpine",Vector2i(3,0)],
	["Uralter Wald","Moosige Stämme und verborgene Lichtungen","forest",Vector2i(0,1)],
	["Spiegelsee","Ein stilles Ufer mit Seerosen und Libellen","lake",Vector2i(3,1)],
	["Moosruinen","Alte Steine werden langsam vom Wald zurückerobert","ruins",Vector2i(0,2)],
	["Eichenhain","Sonnenflecken tanzen unter breiten Blättern","oak",Vector2i(3,2)],
	["Dünenküste","Salzige Luft, Sand und Muscheln am Wasser","coast",Vector2i(0,3)],
	["Schilfmoor","Leise Schritte zwischen Schilf und feuchten Mulden","marsh",Vector2i(1,3)],
	["Dorfrand","Du hältst Abstand und beobachtest die Menschenorte","village",Vector2i(2,3)],
	["Abendlichtung","Goldenes Gras und sichere Plätze zum Ausruhen","meadow",Vector2i(3,3)]
]
static var REGIONS: Array[Dictionary] = _make_regions()

static func _make_regions() -> Array[Dictionary]:
	var infos: Array = REGION_INFO.duplicate(true)
	# Keep original IDs and local coordinates for existing saves.
	for info in infos:info[3]+=Vector2i(2,2)
	var names := [
		["Nordkap","Eiswindbucht","Weiße Tundra","Polarweide","Schneetal","Felsnadel","Adlergrat","Nordlichtpass"],
		["Frostküste","Fichtenhang","Kristallbach","Wintertal","Gletscherwald","Geröllhang","Gipfelweide","Steinmeer"],
		["Robbenbucht","Nebelwald","Frostgrat","Schneekiefern","Wasserfalltal","Steinbockhöhe","Tannenpass","Quellengrund"],
		["Weststrand","Farnschlucht","Uralter Wald","Bergwiese","Flussauen","Spiegelsee","Biberteich","Morgenwald"],
		["Muschelküste","Wurzelwald","Moosruinen","Rudelhöhle","Kiefernwald","Eichenhain","Wildblumental","Osthang"],
		["Winddünen","Salzwiese","Dünenküste","Schilfmoor","Dorfrand","Abendlichtung","Hirschwiese","Hasental"],
		["Südstrand","Regenmoor","Erlenbruch","Weidenbach","Buchenwald","Luchsschlucht","Sonnengrat","Wilder Hang"],
		["Möwenbucht","Seerosenmoor","Birkeninsel","Südauen","Schattenwald","Farnwiese","Warmer Fels","Südhorizont"]
	]
	var descriptions := {"forest":"Alte Stämme, Wurzelpfade und vertraute Tiergerüche","pine":"Kühle Nadeln und leise Schritte auf weichem Waldboden","river":"Das Wasser trägt neue Düfte durch die Landschaft","meadow":"Gräser bewegen sich im Wind; kleine Tiere lauschen","snow":"Frische Trittsiegel liegen zwischen Schnee und Felsen","alpine":"Steinige Höhen mit geschützten Mulden und weitem Blick","lake":"Ein ruhiges Ufer mit Seerosen und spiegelndem Wasser","ruins":"Moose und Wurzeln überwachsen alte Steine","oak":"Lichtflecken und Rascheln unter breiten Blättern","coast":"Salzige Luft und flache Wellen am Sandstrand","marsh":"Schilf, feuchte Erde und das Rufen der Vögel","village":"Du beobachtest aus sicherer Entfernung den Dorfrand"}
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var coord := Vector2i(x,y)
			var known := false
			for info in infos:
				if info[3]==coord:known=true;break
			if known:continue
			var biome := "coast" if x==0 else "snow" if y<2 and x<5 else "alpine" if y<3 or x==7 else "marsh" if y>5 and x<3 else "river" if x==3 else "lake" if x==6 and y==3 else "pine" if y==3 else "meadow" if x==6 or (y+x)%5==0 else "oak" if y>5 else "forest"
			infos.append([names[y][x],descriptions[biome],biome,coord])
	var regions: Array[Dictionary]=[]
	var colors := {"forest":"#719348","pine":"#5c813f","river":"#8ca357","meadow":"#a2b75e","snow":"#d4e6ec","alpine":"#9bad8c","lake":"#81a951","ruins":"#789348","oak":"#8b9e49","coast":"#cebd7a","marsh":"#6c9155","village":"#9aab57"}
	for i in range(infos.size()):
		var info: Array=infos[i]
		var links := {}
		for direction in ["north","south","west","east"]:
			var delta: Vector2i={"north":Vector2i.UP,"south":Vector2i.DOWN,"west":Vector2i.LEFT,"east":Vector2i.RIGHT}[direction]
			for j in range(infos.size()):
				if infos[j][3]==info[3]+delta:links[direction]=j
		regions.append({"name":info[0],"subtitle":info[1],"biome":info[2],"coord":info[3],"ground":colors[info[2]],"seed":41+i*43,"links":links})
	return regions

static func species(kind: String) -> String:
	return {"wolf":"Wolf","deer":"Reh","rabbit":"Hase","fox":"Fuchs"}.get(kind,"Tier")

static func nature_sites(region: int) -> Array[Dictionary]:
	var biome: String=REGIONS[region].biome
	var titles := {"forest":["Wurzelversteck","Lichtfenster","Alter Schlafplatz"],"pine":["Harziger Stamm","Nadellichtung","Fuchsdurchlass"],"river":["Kieselbank","Biberzweige","Ruhige Flussbucht"],"snow":["Spuren im Pulverschnee","Windgeschützte Mulde","Kristalle am Fels"],"alpine":["Aussichtsfels","Grasmulde","Adlerschatten"],"coast":["Muschelsaum","Treibhölzer","Dünensenke"],"marsh":["Schilffenster","Trockene Insel","Vogelufer"],"meadow":["Wildblumeninsel","Hasenmulde","Graslichtung"],"lake":["Seerosenbucht","Libellenufer","Spiegelnder Stein"],"ruins":["Moosbogen","Wurzelmauer","Steinversteck"],"oak":["Eichenwurzel","Laubmulde","Sonnenbank"],"village":["Sicherer Beobachtungsplatz","Feldrand","Rückweg in den Wald"]}
	var sites: Array[Dictionary]=[]
	for i in range(3):
		var pos: Vector2=[Vector2(640,2500),Vector2(2580,2670),Vector2(640,560)][i]
		if biome=="coast":pos.x=maxf(pos.x,700)
		sites.append({"kind":"discovery","p":pos,"scale":1.0,"variant":i,"site":"%d:%d"%[region,i],"title":titles[biome][i],"description":"Du hältst inne. Wind, Boden und Tiergerüche ergeben ein neues Stück deiner Heimat."})
	return sites

static func path_points(region: int, vertical: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(41):
		var t := float(i)/40
		var bend := sin(t*TAU)*sin(t*PI)*140*sin(float(region)*0.7+1.0)
		points.append(Vector2(1600+bend,t*3200) if vertical else Vector2(t*3200,1600+bend))
	return points

static func on_path(p: Vector2,region: int,margin: float=95) -> bool:
	var ty := clampf(p.y/3200,0,1)
	var tx := clampf(p.x/3200,0,1)
	var bx := sin(ty*TAU)*sin(ty*PI)*140*sin(float(region)*0.7+1)
	var by := sin(tx*TAU)*sin(tx*PI)*140*sin(float(region)*0.7+1)
	return absf(p.x-1600-bx)<margin or absf(p.y-1600-by)<margin

static func river_x(y: float) -> float:
	return 970+sin(y/410)*70

static func water_blocked(p: Vector2,region: int) -> bool:
	if REGIONS[region].biome=="coast" and p.x<425 and absf(p.y-1600)>65:return true
	if REGIONS[region].biome=="river":
		return absf(p.x-river_x(p.y))<78 and absf(p.y-1600)>64 and absf(p.y-800)>64 and absf(p.y-2600)>64
	return false

static func generate(region: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed=REGIONS[region].seed
	var objects: Array[Dictionary]=[]
	var biome: String=REGIONS[region].biome
	for i in range(560 if biome in ["forest","pine","oak"] else 340):
		var p := Vector2(rng.randf_range(70,3130),rng.randf_range(70,3130))
		if on_path(p,region,110) or p.distance_to(SPAWN)<190 or p.distance_to(Vector2(2180,1040))<170:continue
		if biome=="river" and absf(p.x-river_x(p.y))<170:continue
		if biome=="coast" and p.x<560:continue
		if p.distance_to(Vector2(2220,2140))<300:continue
		if biome=="village" and p.distance_to(Vector2(2400,720))<650:continue
		var variant := 0 if biome in ["pine","snow","alpine"] else i%3
		objects.append({"kind":"tree","p":p,"scale":rng.randf_range(0.85,1.45),"variant":variant})
	for i in range(75):
		var p := Vector2(rng.randf_range(120,3080),rng.randf_range(120,3080))
		if not on_path(p,region,115) and p.distance_to(SPAWN)>230 and p.distance_to(Vector2(2180,1040))>180 and p.distance_to(Vector2(2220,2140))>290:
			objects.append({"kind":"rock","p":p,"scale":rng.randf_range(0.7,1.35),"variant":i%3})
	for i in range(80):
		var p := Vector2(rng.randf_range(120,3080),rng.randf_range(120,3080))
		if not on_path(p,region,70) and not water_blocked(p,region):
			objects.append({"kind":"bush" if i%3==0 else "flowers","p":p,"scale":rng.randf_range(0.7,1.2),"variant":i%3})
	objects.append({"kind":"water","p":Vector2(970,1600) if biome=="river" else Vector2(2220,2140),"scale":1.65 if biome=="lake" else 1.2,"variant":1 if biome=="river" else 0})
	objects.append({"kind":"den","p":Vector2(1580,2180) if region==0 else Vector2(2500,800),"scale":1.0,"variant":0})
	objects.append({"kind":"food","p":Vector2(1380,2040),"scale":1.0,"variant":0})
	objects.append({"kind":"landmark","p":Vector2(2180,1040),"scale":1.0,"variant":0})
	objects.append_array(nature_sites(region))
	if biome=="river":
		for y in [800,1600,2600]:objects.append({"kind":"bridge","p":Vector2(river_x(y),y),"scale":1.0,"variant":0})
	if region==6:objects.append({"kind":"waterfall","p":Vector2(river_x(580),580),"scale":1.0,"variant":0})
	if biome=="ruins":
		for i in range(5):objects.append({"kind":"ruin","p":Vector2(570+i*80,700+sin(i*1.1)*100),"scale":1.0,"variant":i%3})
	if biome=="village":
		for i in range(4):objects.append({"kind":"house","p":Vector2(2060+i*220,650+float(i%2)*220),"scale":1.0,"variant":i%3})
	var animals: Array[Dictionary]=[]
	for i in range(9):
		var p := Vector2(1800+i%3*140,1300-i/3*170)
		for attempt in range(80):
			if walkable(p,objects) and not water_blocked(p,region):break
			p+=Vector2(32,20)
		var kind := "deer" if i<3 else "rabbit" if i<7 else "fox"
		animals.append({"kind":kind,"p":p,"home":p,"phase":float(i)*1.8,"facing":Vector2.LEFT,"mood":"grasen","speed":0.0,"gait":0.0})
	if region==0:
		for i in range(4):
			var p := Vector2(1430+i*100,2260+float(i%2)*90)
			animals.append({"kind":"wolf","p":p,"home":p,"phase":float(i)*1.2,"facing":Vector2.UP,"young":i>=2,"role":["Mutter","Vater","Geschwister","Geschwister"][i],"mood":"ruhen","speed":0.0,"gait":0.0})
	for member in animals:
		if member.kind=="wolf":objects=objects.filter(func(o:Dictionary):return o.kind not in ["tree","rock"] or o.p.distance_to(member.home)>100)
	var tracks: Array[Dictionary]=[]
	for trail in range(3):
		for i in range(9):
			var endpoint: Vector2=animals[[0,3,7][trail]].home
			var start: Vector2=[Vector2(1640,1810),Vector2(1460,1580),Vector2(1560,1450)][trail]
			var p := start.lerp(endpoint,float(i)/8)+Vector2(sin(i*1.2)*18,cos(i*1.3)*10)
			if i==8:p=endpoint
			# Reserve a usable small clearing around every clue.
			objects=objects.filter(func(o:Dictionary):return o.kind not in ["tree","rock"] or o.p.distance_to(p)>65)
			tracks.append({"id":"%d:%d"%[region,trail*9+i],"p":p,"species":["Reh","Hase","Fuchs"][trail],"trail":trail,"animal_index":[0,3,7][trail],"freshness":80-trail*13,"found":false})
	for site in nature_sites(region):
		objects=objects.filter(func(o:Dictionary):return o.kind not in ["tree","rock"] or o.p.distance_to(site.p)>150)
	var decor: Array[Dictionary]=[]
	for i in range(1600):
		var p := Vector2(rng.randf_range(10,3190),rng.randf_range(10,3190))
		if not water_blocked(p,region):decor.append({"p":p,"size":rng.randf_range(2,12),"variant":i%7})
	return {"objects":objects,"animals":animals,"tracks":tracks,"decor":decor}

static func solid_radius(obj: Dictionary) -> float:
	match obj.kind:
		"tree":return 22.0*obj.scale
		"rock":return 30.0*obj.scale
		"den":return 68.0
		"water":return 0.0 if obj.variant==1 else 190.0*obj.scale
		"house":return 95.0
		"ruin":return 30.0
	return 0.0

static func walkable(p: Vector2,objects: Array) -> bool:
	for obj in objects:
		var r := solid_radius(obj)
		if r>0 and p.distance_to(obj.p)<r+13:return false
	return true

static func exit_at(p: Vector2,region: int) -> String:
	if p.x>3180 and absf(p.y-1600)<110 and REGIONS[region].links.has("east"):return "east"
	if p.x<20 and absf(p.y-1600)<110 and REGIONS[region].links.has("west"):return "west"
	if p.y<20 and absf(p.x-1600)<110 and REGIONS[region].links.has("north"):return "north"
	if p.y>3180 and absf(p.x-1600)<110 and REGIONS[region].links.has("south"):return "south"
	return ""

static func entry_point(direction: String) -> Vector2:
	match direction:
		"east":return Vector2(55,1600)
		"west":return Vector2(3145,1600)
		"north":return Vector2(1600,3145)
	return Vector2(1600,55)

static func index_at(coord: Vector2i) -> int:
	for i in range(REGIONS.size()):
		if REGIONS[i].coord==coord:return i
	return -1

static func height_at(p: Vector2,region: int) -> float:
	var biome: String=REGIONS[region].biome
	if biome in ["river","lake","marsh","coast"]:return 0
	# Gentle continuous hills vanish at exits and on paths, keeping bridges safe.
	var edge := sin(clampf(p.x/3200,0,1)*PI)*sin(clampf(p.y/3200,0,1)*PI)
	var amplitude := 1.2 if biome in ["alpine","snow","meadow"] else 0.5
	var ty := clampf(p.y/3200,0,1)
	var tx := clampf(p.x/3200,0,1)
	var bx := sin(ty*TAU)*sin(ty*PI)*140*sin(float(region)*0.7+1)
	var by := sin(tx*TAU)*sin(tx*PI)*140*sin(float(region)*0.7+1)
	var distance := minf(absf(p.x-1600-bx),absf(p.y-1600-by))
	var path_weight := smoothstep(90.0,260.0,distance)
	return sin(p.x/600)*cos(p.y/680)*edge*amplitude*path_weight
