class_name WolfSessionCache
extends RefCounted

const MAX_WORLDS := 16
var worlds: Dictionary = {}
var snapshots: Dictionary = {}
var recent: Array[int] = []

func capture(region: int, world: Dictionary) -> void:
	var animals: Array[Dictionary] = []
	for animal in world.get("animals",[]):
		if animal.get("companion",false):continue
		animals.append({"kind":animal.kind,"p":[animal.p.x,animal.p.y],"facing":[animal.facing.x,animal.facing.y],"mood":animal.get("mood","lauschen"),"gait":animal.get("gait",0.0),"alarm":animal.get("alarm",0.0)})
	snapshots[str(region)]=animals

func region_world(region: int) -> Dictionary:
	if not worlds.has(region):
		var world := WolfWorldData.generate(region)
		var animals: Array=world.animals
		var remembered: Array=snapshots.get(str(region),[])
		for index in range(mini(animals.size(),remembered.size())):
			var item: Dictionary=remembered[index]
			var animal: Dictionary=animals[index]
			if item.get("kind","")!=animal.kind:continue
			var p: Array=item.get("p",[])
			if p.size()!=2:continue
			var point := Vector2(float(p[0]),float(p[1])).clamp(Vector2(95,95),WolfWorldData.SIZE-Vector2(95,95))
			if WolfWorldData.walkable(point,world.objects) and not WolfWorldData.water_blocked(point,region):animal.p=point
			var facing: Array=item.get("facing",[0,-1])
			if facing.size()==2:animal.facing=Vector2(float(facing[0]),float(facing[1])).normalized()
			animal.gait=maxf(0,float(item.get("gait",0)))
			animal.alarm=clampf(float(item.get("alarm",0)),0,3)
			animal.mood=str(item.get("mood","lauschen"))
		worlds[region]=world
	recent.erase(region)
	recent.append(region)
	while recent.size()>MAX_WORLDS:
		var oldest: int=recent.pop_front()
		capture(oldest,worlds[oldest])
		worlds.erase(oldest)
	return worlds[region]

func save_cache(path: String) -> bool:
	var pending := path+".pending"
	var file := FileAccess.open(pending,FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify({"version":1,"animals":snapshots}))
	file.flush()
	var valid := file.get_error()==OK
	file.close()
	if valid and DirAccess.rename_absolute(pending,path)==OK:return true
	DirAccess.remove_absolute(pending)
	return false

func load_cache(path: String) -> void:
	if not FileAccess.file_exists(path):return
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or int(data.get("version",0))!=1 or not data.get("animals") is Dictionary:return
	for key in data.animals:
		if not str(key).is_valid_int():continue
		var index := int(key)
		if index<0 or index>=WolfWorldData.REGIONS.size() or not data.animals[key] is Array:continue
		var entries: Array[Dictionary]=[]
		for item in data.animals[key]:
			# Preserve animal indices when a damaged entry is skipped.
			if not item is Dictionary or not _vector_valid(item.get("p")) or not _vector_valid(item.get("facing")):
				entries.append({});continue
			var gait=item.get("gait",0)
			var alarm=item.get("alarm",0)
			if not _number_valid(gait) or not _number_valid(alarm):entries.append({});continue
			entries.append({"kind":str(item.get("kind","")),"p":item.p,"facing":item.facing,"mood":str(item.get("mood","lauschen")),"gait":float(gait),"alarm":float(alarm)})
		snapshots[str(index)]=entries

func _number_valid(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _vector_valid(value: Variant) -> bool:
	return value is Array and value.size()==2 and _number_valid(value[0]) and _number_valid(value[1])

func clear_cache(path: String) -> void:
	worlds.clear();snapshots.clear();recent.clear()
	if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
