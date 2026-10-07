class_name WolfState
extends RefCounted

const SAVE_PATH := "user://wolf_save_v1.json"
static var save_path := SAVE_PATH
var region := 0
var pos := WolfWorldData.SPAWN
var facing := Vector2(0,-1)
var hunger := 85.0
var thirst := 85.0
var energy := 100.0
var bond := 40.0
var elapsed := 0.0
var found: Array[String] = []
var visited: Array[int] = [0]
var landmarks: Array[int] = []
var observations: Array[String] = []
var journal: Array[String] = ["Tag 1 · Du verlässt vorsichtig die Rudelhöhle. Der vertraute Geruch deiner Familie begleitet dich."]
var drank := false
var rested := false
var howled := false
var completed: Array[String] = []
var food_cooldown := 0.0
var discoveries: Array[int] = []
var pack_contacts := 0
var xp := 0
var distance_walked := 0.0
var marked: Array[int] = []

func tick(dt: float, moving: bool, sprint: bool) -> void:
	elapsed += dt
	thirst = maxf(0,thirst-dt*0.018)
	hunger = maxf(0,hunger-dt*0.01)
	energy = clampf(energy + dt*(-0.8 if sprint and moving else -0.025 if moving else 0.16),0,100)
	food_cooldown=maxf(0,food_cooldown-dt)

func level() -> int:
	return 1+int(xp/100)

func biome_count(kind: String) -> int:
	var count := 0
	for index in visited:
		if WolfWorldData.REGIONS[index].biome==kind:count+=1
	return count

func quests() -> Array[Dictionary]:
	return [
		{"id":"drink","name":"Kühles Wasser","hint":"Untersuche das Wasser vom Ufer aus.","done":drank,"progress":"1/1" if drank else "0/1"},
		{"id":"tracks","name":"Die erste Fährte","hint":"Schnüffle und untersuche drei goldene Spuren.","done":found.size()>=3,"progress":"%d/3"%mini(found.size(),3)},
		{"id":"pack","name":"Eine vertraute Antwort","hint":"Heule nahe der Familie an deiner Rudelhöhle.","done":howled,"progress":"1/1" if howled else "0/1"},
		{"id":"family","name":"Vier vertraute Pfoten","hint":"Untersuche einen Wolf nahe der Höhle. Lerne das Rudel kennen.","done":pack_contacts>=1,"progress":"%d/1"%mini(pack_contacts,1)},
		{"id":"explore","name":"Vier Düfte der Wildnis","hint":"Erkunde vier Gebiete über die Wege am Kartenrand.","done":visited.size()>=4,"progress":"%d/4"%mini(visited.size(),4)},
		{"id":"observe","name":"Leise Pfoten","hint":"Beobachte Reh und Hase aus der 3D-Sicht. Bleibe auf Abstand.","done":observations.has("Reh") and observations.has("Hase"),"progress":"%d/2"%int(int(observations.has("Reh"))+int(observations.has("Hase")))},
		{"id":"landmarks","name":"Orte, die bleiben","hint":"Untersuche Wegsteine in vier verschiedenen Gebieten.","done":landmarks.size()>=4,"progress":"%d/4"%mini(landmarks.size(),4)},
		{"id":"rest","name":"Geborgen im Rudel","hint":"Ruhe in der Nähe einer Höhle.","done":rested,"progress":"1/1" if rested else "0/1"},
		{"id":"trail12","name":"Die Nase lernt dazu","hint":"Lies zwölf Spuren entlang der Fährten.","done":found.size()>=12,"progress":"%d/12"%mini(found.size(),12)},
		{"id":"secret1","name":"Eine verborgene Lichtung","hint":"Finde die goldene Entdeckung südwestlich in einem Gebiet.","done":discoveries.size()>=1,"progress":"%d/1"%mini(discoveries.size(),1)},
		{"id":"snow","name":"Pfoten im Schnee","hint":"Erreiche Frostgrat oder Schneekiefern im Norden.","done":biome_count("snow")>=1,"progress":"%d/1"%mini(biome_count("snow"),1)},
		{"id":"river","name":"Das Lied des Wassers","hint":"Erkunde Flussauen und Wasserfalltal.","done":biome_count("river")>=2,"progress":"%d/2"%biome_count("river")},
		{"id":"fox","name":"Roter Schatten","hint":"Beobachte einen Fuchs aus dem Wolfsblick.","done":observations.has("Fuchs"),"progress":"1/1" if observations.has("Fuchs") else "0/1"},
		{"id":"ruins","name":"Steine voller Geschichten","hint":"Finde die Moosruinen westlich des Startgebiets.","done":visited.has(10),"progress":"1/1" if visited.has(10) else "0/1"},
		{"id":"coast","name":"Ein neuer Horizont","hint":"Erkunde die Dünenküste im Südwesten.","done":visited.has(12),"progress":"1/1" if visited.has(12) else "0/1"},
		{"id":"secret8","name":"Verborgene Heimat","hint":"Entdecke acht besondere Lichtungen oder Naturorte.","done":discoveries.size()>=8,"progress":"%d/8"%mini(discoveries.size(),8)},
		{"id":"mark","name":"Mein Weg durch die Wildnis","hint":"Markiere deinen Duft in sechs verschiedenen Gebieten.","done":marked.size()>=6,"progress":"%d/6"%mini(marked.size(),6)},
		{"id":"trail40","name":"Fährtenkundige Pfoten","hint":"Lies vierzig unterschiedliche Spuren.","done":found.size()>=40,"progress":"%d/40"%mini(found.size(),40)},
		{"id":"explore16","name":"Die große Wildnis","hint":"Erkunde alle sechzehn verbundenen Gebiete.","done":visited.size()>=16,"progress":"%d/16"%visited.size()},
		{"id":"stones16","name":"Das Gedächtnis der Landschaft","hint":"Präge dir in jedem Gebiet einen Wegstein ein.","done":landmarks.size()>=16,"progress":"%d/16"%landmarks.size()}
	]

func record(message: String) -> void:
	journal.push_front(message)
	if journal.size()>60: journal.resize(60)

func save_to(path: String = "") -> bool:
	if path.is_empty():path=save_path
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify({"version":2,"region":region,"pos":[pos.x,pos.y],"facing":[facing.x,facing.y],"hunger":hunger,"thirst":thirst,"energy":energy,"bond":bond,"elapsed":elapsed,"found":found,"visited":visited,"landmarks":landmarks,"observations":observations,"journal":journal,"drank":drank,"rested":rested,"howled":howled,"completed":completed,"food_cooldown":food_cooldown,"discoveries":discoveries,"pack_contacts":pack_contacts,"xp":xp,"distance_walked":distance_walked,"marked":marked}))
	return true

func load_from(path: String = "") -> bool:
	if path.is_empty():path=save_path
	if not FileAccess.file_exists(path):return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or int(data.get("version",0)) not in [1,2]:return false
	if not data.get("pos") is Array or data.pos.size()!=2:return false
	region=clampi(int(data.get("region",0)),0,WolfWorldData.REGIONS.size()-1)
	pos=Vector2(clampf(float(data.pos[0]),20,3180),clampf(float(data.pos[1]),20,3180))
	var f = data.get("facing",[0,-1])
	if f is Array and f.size()==2:facing=Vector2(float(f[0]),float(f[1])).normalized()
	for key in ["hunger","thirst","energy","bond"]: set(key,clampf(float(data.get(key,80)),0,100))
	elapsed=maxf(0,float(data.get("elapsed",0)))
	food_cooldown=maxf(0,float(data.get("food_cooldown",0)))
	for key in ["found","observations","journal","completed"]:
		var arr: Array[String]=[]
		if data.get(key) is Array:
			for value in data[key]:
				if value is String:arr.append(value)
		set(key,arr)
	for key in ["visited","landmarks","discoveries","marked"]:
		var arr: Array[int]=[]
		if data.get(key) is Array:
			for value in data[key]:
				if int(value)>=0 and int(value)<WolfWorldData.REGIONS.size() and not arr.has(int(value)):arr.append(int(value))
		set(key,arr)
	if int(data.version)==1:pos*=2.0
	xp=maxi(0,int(data.get("xp",completed.size()*25)))
	pack_contacts=maxi(0,int(data.get("pack_contacts",0)))
	distance_walked=maxf(0,float(data.get("distance_walked",0)))
	if not visited.has(region):visited.append(region)
	drank=bool(data.get("drank",false))
	rested=bool(data.get("rested",false))
	howled=bool(data.get("howled",false))
	return true
