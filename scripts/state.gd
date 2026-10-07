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

func tick(dt: float, moving: bool, sprint: bool) -> void:
	elapsed += dt
	thirst = maxf(0,thirst-dt*0.018)
	hunger = maxf(0,hunger-dt*0.01)
	energy = clampf(energy + dt*(-0.8 if sprint and moving else -0.025 if moving else 0.16),0,100)
	food_cooldown=maxf(0,food_cooldown-dt)

func quests() -> Array[Dictionary]:
	return [
		{"id":"drink","name":"Kühles Wasser","hint":"Gehe an den Rand eines Teichs und trinke.","done":drank,"progress":"1/1" if drank else "0/1"},
		{"id":"tracks","name":"Die erste Fährte","hint":"Schnüffle. Untersuche drei goldene Spuren in der Nähe.","done":found.size()>=3,"progress":"%d/3"%mini(found.size(),3)},
		{"id":"pack","name":"Eine vertraute Antwort","hint":"Kehre zur Rudelhöhle zurück und heule nahe deiner Familie.","done":howled,"progress":"1/1" if howled else "0/1"},
		{"id":"explore","name":"Vier Düfte der Wildnis","hint":"Folge den breiten Wegen zu allen vier Gebieten.","done":visited.size()>=4,"progress":"%d/4"%visited.size()},
		{"id":"observe","name":"Leise Pfoten","hint":"Beobachte Reh und Hase aus der 3D-Sicht. Nicht zu nah!","done":observations.size()>=2,"progress":"%d/2"%observations.size()},
		{"id":"landmarks","name":"Orte, die bleiben","hint":"Untersuche den alten Wegstein in jedem Gebiet.","done":landmarks.size()>=4,"progress":"%d/4"%landmarks.size()},
		{"id":"rest","name":"Geborgen im Rudel","hint":"Ruhe nahe einer Höhle.","done":rested,"progress":"1/1" if rested else "0/1"}
	]

func record(message: String) -> void:
	journal.push_front(message)
	if journal.size()>60: journal.resize(60)

func save_to(path: String = "") -> bool:
	if path.is_empty():path=save_path
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify({"version":1,"region":region,"pos":[pos.x,pos.y],"facing":[facing.x,facing.y],"hunger":hunger,"thirst":thirst,"energy":energy,"bond":bond,"elapsed":elapsed,"found":found,"visited":visited,"landmarks":landmarks,"observations":observations,"journal":journal,"drank":drank,"rested":rested,"howled":howled,"completed":completed,"food_cooldown":food_cooldown}))
	return true

func load_from(path: String = "") -> bool:
	if path.is_empty():path=save_path
	if not FileAccess.file_exists(path):return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version",0)!=1:return false
	if not data.get("pos") is Array or data.pos.size()!=2:return false
	region=clampi(int(data.get("region",0)),0,3)
	pos=Vector2(clampf(float(data.pos[0]),20,1580),clampf(float(data.pos[1]),20,1580))
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
	for key in ["visited","landmarks"]:
		var arr: Array[int]=[]
		if data.get(key) is Array:
			for value in data[key]:
				if int(value)>=0 and int(value)<4 and not arr.has(int(value)):arr.append(int(value))
		set(key,arr)
	if not visited.has(region):visited.append(region)
	drank=bool(data.get("drank",false))
	rested=bool(data.get("rested",false))
	howled=bool(data.get("howled",false))
	return true
