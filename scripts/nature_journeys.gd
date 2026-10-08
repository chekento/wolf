class_name WolfNatureJourneys
extends RefCounted

const VERSION := 1
const KINDS := ["scent","water","tracks","watch","places","rest"]
const CACHE_LIMIT := 16
static var _definitions: Dictionary = {}
static var _region_order: Array[int] = []

static func definitions(region: int) -> Array[Dictionary]:
	if region<0 or region>=WolfWorldData.REGIONS.size():return []
	if _definitions.has(region):
		_region_order.erase(region);_region_order.append(region)
		return _definitions[region]
	var world: Dictionary=WolfWorldData.generate(region)
	var sites: Array[Dictionary]=WolfWorldData.nature_sites(region)
	var shelter: Dictionary={}
	for object in world.objects:
		if object.kind=="den" and int(object.variant)==1:shelter=object;break
	if shelter.is_empty():
		for object in world.objects:
			if object.kind=="den":shelter=object;break
	var result: Array[Dictionary]=[
		{"id":"%d:scent"%region,"kind":"scent","title":"Ein vertrauter Duft","text":"Du prüfst %s und setzt dort einen eigenen Duft. Eine kleine Erinnerung verbindet deinen nächsten Weg mit diesem Ort."%sites[0].title,"summary":"Einen Naturort wirklich prüfen und danach einen Duft setzen.","skill":"nose","stages":[_site(sites[0],region),{"action":"mark","region":region,"p":sites[0].p,"radius":150.0,"objective":"Setze jetzt bei %s deinen Duft."%sites[0].title}]},
		{"id":"%d:water"%region,"kind":"water","title":"Das Ufer im Gedächtnis","text":"Feuchte Erde und ein sicherer Zugang gehören zum Wasser. Nach dem Trinken prüfst du %s. Zwei selbst erlebte Orte geben deinem Rückweg Richtung."%sites[2].title,"summary":"Frisches Trinken und danach ein bestimmter Naturort.","skill":"nose","stages":[{"action":"drink","region":region,"p":WolfWorldData.water_bank(region),"radius":170.0,"objective":"Trinke mit Aktion vom trockenen Wasserufer dieses Gebiets."},_site(sites[2],region)]},
		{"id":"%d:tracks"%region,"kind":"tracks","title":"Zwei Trittsiegel","text":"Ein Hase hat den Boden zwischen den Stämmen überquert. Schnüffle und vergleiche zwei konkrete Trittsiegel derselben Fährte in ihrer Reihenfolge. Auch eine bekannte Spur musst du jetzt selbst prüfen.","summary":"Zwei bestimmte Hasenspuren frisch und in Reihenfolge lesen.","skill":"nose","stages":[{"action":"track","region":region,"p":world.tracks[9].p,"radius":100.0,"track_id":world.tracks[9].id,"objective":"Schnüffle und lies das erste markierte Hasentrittsiegel mit Aktion."},{"action":"track","region":region,"p":world.tracks[11].p,"radius":100.0,"track_id":world.tracks[11].id,"objective":"Folge der Fährte und prüfe das nächste markierte Hasentrittsiegel mit Aktion."}]},
		{"id":"%d:watch"%region,"kind":"watch","title":"Geduld im Rehwechsel","text":"Ein Reh prüft den Wind und seine Umgebung. Du bleibst mit Abstand ruhig. Danach erkundest du %s, ohne ein Tier aufzuscheuchen."%sites[3].title,"summary":"Dasselbe ruhige Reh beobachten, danach einen Naturort prüfen.","skill":"stealth","stages":[{"action":"watch","region":region,"p":world.animals[0].p+Vector2(0,230),"radius":420.0,"seconds":4.0,"species":"Reh","objective":"Wähle Beobachten im 3D-Wolfsblick. Halte dasselbe ruhige Reh vier aktive Sekunden mit Abstand und freier Sicht im Blick."},_site(sites[3],region)]},
		{"id":"%d:places"%region,"kind":"places","title":"Zwischen zwei stillen Orten","text":"%s und %s tragen unterschiedliche Gerüche. Prüfe erst den ersten Ort und gehe dann selbst zum zweiten. Du lernst die Landschaft zwischen ihnen kennen."%[sites[4].title,sites[5].title],"summary":"Zwei bestimmte Naturorte nacheinander frisch prüfen.","skill":"nose","stages":[_site(sites[4],region),_site(sites[5],region)]},
		{"id":"%d:rest"%region,"kind":"rest","title":"Eine Mulde zum Ruhen","text":"Du prüfst %s, bevor du den geschützten Ruheplatz aufsuchst. Niedrige Erde, vertrauter Waldgeruch und ruhige Pfoten geben deinem Körper eine kurze Pause. Die Tage machen dabei keinen Sprung."%sites[2].title,"summary":"Einen Ort prüfen, den wirklichen Schutzplatz erreichen und ruhig liegen.","skill":"stealth","stages":[_site(sites[2],region),{"action":"rest","region":region,"p":shelter.p+Vector2(112,0),"den_center":shelter.p,"radius":185.0,"objective":"Ruhe jetzt mit Aktion am markierten geschützten Ruheplatz."},{"action":"rest_wait","region":region,"p":shelter.p+Vector2(112,0),"den_center":shelter.p,"radius":185.0,"seconds":3.0,"objective":"Bleibe am Schutzplatz drei aktive Sekunden ruhig liegen."}]}
	]
	for definition in result:
		definition.region=region;definition.reward=30
		definition.target_region=region;definition.target_pos=definition.stages[0].p
		definition.steps_count=definition.stages.size()
		var titles: Array[String]=[]
		for goal in definition.stages:titles.append(goal.objective)
		definition.stage_titles=titles
	_definitions[region]=result;_region_order.append(region)
	while _region_order.size()>CACHE_LIMIT:_definitions.erase(_region_order.pop_front())
	return result

static func _site(site: Dictionary,region: int) -> Dictionary:
	return {"action":"site","region":region,"p":site.p,"radius":150.0,"site_id":site.site,"objective":"Prüfe jetzt %s mit Aktion."%site.title}

static func initial() -> Dictionary:
	return {"version":VERSION,"active":{},"completed":[]}

static func valid_id(id: String) -> bool:
	var parts := id.split(":")
	if parts.size()!=2 or parts[0].length()>3 or not parts[0].is_valid_int() or parts[1] not in KINDS:return false
	var region := int(parts[0])
	return region>=0 and region<WolfWorldData.REGIONS.size() and str(region)==parts[0]

static func definition(id: String) -> Dictionary:
	if not valid_id(id):return {}
	for candidate in definitions(int(id.split(":")[0])):
		if candidate.id==id:return candidate
	return {}

static func options(progress: Dictionary,region: int) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for source in definitions(region):
		var item := source.duplicate()
		item.completed=progress.completed.has(item.id)
		item.available=progress.active.is_empty() and not item.completed
		result.append(item)
	return result

static func current_stage(progress: Dictionary) -> Dictionary:
	if progress.active.is_empty():return {}
	var source := definition(str(progress.active.get("id","")))
	if source.is_empty():return {}
	var stage := int(progress.active.get("stage",0))
	return source.stages[stage] if stage>=0 and stage<source.stages.size() else {}

static func status(progress: Dictionary,region: int,pos: Vector2) -> Dictionary:
	var active: Dictionary=progress.active
	if active.is_empty():return {"accepted":false,"started":false,"id":"","kind":"","title":"Naturreisen","text":"Kleine eigene Wege verbinden die Orte deiner Wildnis.","objective":"Wähle eine Naturreise in deinem aktuellen Gebiet.","progress":"Keine aktive Reise","stage":0,"current":0,"required":0,"steps_count":0,"ready":false,"done":false,"region":region,"target_region":-1,"target_pos":Vector2.ZERO,"action":"","track_id":"","site_id":"","species":"","seconds":0.0,"seconds_required":0.0,"watch_started":false,"watch_animal":"","watch_ready":false,"player_ready":false,"completed_count":progress.completed.size(),"stage_titles":[]}
	var source := definition(str(active.id))
	if source.is_empty():return {}
	var stage := clampi(int(active.get("stage",0)),0,source.stages.size())
	var ready: bool=stage==source.stages.size()
	var goal: Dictionary=source.stages[mini(stage,source.stages.size()-1)]
	var in_region: bool=region==int(source.region) and pos.is_finite()
	return {"accepted":true,"started":true,"id":source.id,"kind":source.kind,"title":source.title,"text":source.text,"summary":source.summary,"objective":"Die Naturreise ist erlebt. Erinnere sie im Naturreisenmenü, um sie abzuschließen." if ready else goal.objective,"progress":"%d / %d Schritte"%[stage,source.stages.size()],"stage":stage,"current":stage,"required":source.stages.size(),"steps_count":source.stages.size(),"ready":ready,"done":ready,"region":source.region,"target_region":source.region,"target_pos":goal.p,"action":"" if ready else goal.action,"track_id":goal.get("track_id","") if not ready else "","site_id":goal.get("site_id","") if not ready else "","species":goal.get("species","") if not ready else "","seconds":float(active.get("seconds",0)) if not ready else 0.0,"seconds_required":float(goal.get("seconds",0)) if not ready else 0.0,"watch_started":active.get("watch_started",false) if not ready else false,"watch_animal":str(active.get("watch_animal","")) if not ready else "","watch_ready":in_region and active.get("watch_ready",false) if not ready else false,"player_ready":in_region and active.get("player_ready",false) if not ready else false,"completed_count":progress.completed.size(),"stage_titles":source.stage_titles,"reward":source.reward,"skill":source.skill}

static func begin(progress: Dictionary,id: String,region: int) -> bool:
	if not progress.active.is_empty() or not valid_id(id) or progress.completed.has(id):return false
	var source := definition(id)
	if source.is_empty() or int(source.region)!=region:return false
	progress.active={"id":id,"stage":0,"seconds":0.0,"watch_started":false,"watch_animal":"","player_ready":false,"watch_ready":false}
	return true

static func claim(progress: Dictionary) -> bool:
	if progress.active.is_empty():return false
	var source := definition(str(progress.active.id))
	if source.is_empty() or progress.completed.has(source.id) or int(progress.active.get("stage",0))!=source.stages.size():return false
	progress.completed.append(source.id);progress.active={}
	return true

static func abandon(progress: Dictionary) -> bool:
	if progress.active.is_empty():return false
	progress.active={}
	return true

static func note_action(progress: Dictionary,action: String,detail: String,region: int,pos: Vector2) -> bool:
	var goal := current_stage(progress)
	if goal.is_empty() or action!=str(goal.action) or region!=int(goal.region) or not pos.is_finite() or pos.distance_to(goal.p)>=float(goal.radius):return false
	match action:
		"site":
			if detail!=str(goal.site_id):return false
		"track":
			if detail!=str(goal.track_id):return false
		"rest":
			if pos.distance_to(goal.den_center)>=190:return false
		"drink","mark":pass
		_:return false
	_finish_stage(progress)
	return true

static func note_observation(progress: Dictionary,animal: Dictionary,region: int,pos: Vector2,speed: float,quiet: bool,clear_view: bool) -> bool:
	var goal := current_stage(progress)
	if goal.is_empty() or goal.action!="watch" or not _watch_valid(goal,animal,region,pos,speed,quiet,clear_view):return false
	var key := WolfPackLife.animal_key(animal)
	if not WolfMainStory.valid_watch_identity(key):return false
	if progress.active.get("watch_started",false) and str(progress.active.get("watch_animal",""))!=key:return false
	progress.active.watch_started=true;progress.active.watch_animal=key
	return true

static func tick(progress: Dictionary,dt: float,region: int,pos: Vector2,speed: float,animal: Dictionary,clear_view: bool,quiet: bool,mood: String) -> bool:
	clear_live(progress)
	var goal := current_stage(progress)
	if goal.is_empty() or goal.action not in ["watch","rest_wait"] or not is_finite(dt) or dt<=0 or not is_finite(speed) or not pos.is_finite() or region!=int(goal.region):return false
	if goal.action=="watch":
		progress.active.watch_ready=_watch_valid(goal,animal,region,pos,speed,quiet,clear_view)
		if not progress.active.watch_ready or not progress.active.get("watch_started",false):return false
		if WolfPackLife.animal_key(animal)!=str(progress.active.get("watch_animal","")):progress.active.watch_ready=false;return false
	else:
		progress.active.player_ready=speed>=0 and speed<=1 and mood=="ruhen" and pos.distance_to(goal.p)<float(goal.radius) and pos.distance_to(goal.den_center)<190
		if not progress.active.player_ready:return false
	progress.active.seconds=minf(float(goal.seconds),float(progress.active.get("seconds",0))+clampf(dt,0,0.1))
	if float(progress.active.seconds)+0.0001>=float(goal.seconds):
		_finish_stage(progress)
		return true
	return false

static func clear_live(progress: Dictionary) -> void:
	if progress.active.is_empty():return
	progress.active.player_ready=false;progress.active.watch_ready=false

static func _finish_stage(progress: Dictionary) -> void:
	progress.active.stage=int(progress.active.get("stage",0))+1
	progress.active.seconds=0.0;progress.active.watch_started=false;progress.active.watch_animal=""
	clear_live(progress)

static func _watch_valid(goal: Dictionary,animal: Dictionary,region: int,pos: Vector2,speed: float,quiet: bool,clear_view: bool) -> bool:
	if region!=int(goal.region) or not pos.is_finite() or not is_finite(speed) or speed<0 or speed>1 or not quiet or not clear_view:return false
	if animal.is_empty() or animal.get("kind","")!="deer" or not animal.get("p") is Vector2 or not animal.p.is_finite():return false
	var distance: float=pos.distance_to(animal.p)
	if distance<145 or distance>420 or _number(animal.get("alarm",0),INF)>0 or _number(animal.get("attention",0),INF)>0.65:return false
	if animal.get("behavior","") in ["flee","recover"] or animal.get("mood","")=="fliehen":return false
	return _number(animal.get("speed",0),INF)<=35

static func saved(progress: Dictionary) -> Dictionary:
	var active: Dictionary={}
	if not progress.active.is_empty():
		for key in ["id","stage","seconds","watch_started","watch_animal"]:active[key]=progress.active.get(key)
	return {"version":VERSION,"active":active,"completed":progress.completed.duplicate()}

static func restored(value: Variant) -> Dictionary:
	var result := initial()
	if not value is Dictionary or _number(value.get("version",0),0)!=VERSION:return result
	if value.get("completed") is Array:
		for index in range(mini(value.completed.size(),WolfWorldData.REGIONS.size()*KINDS.size())):
			var id: Variant=value.completed[index]
			if id is String and valid_id(id) and not result.completed.has(id):result.completed.append(id)
	if not value.get("active") is Dictionary or not value.active.get("id") is String or not valid_id(value.active.id) or result.completed.has(value.active.id):return result
	var source := definition(value.active.id)
	var stage := _number(value.active.get("stage",0),0)
	if stage<0 or stage>source.stages.size() or stage!=floorf(stage):stage=0
	result.active={"id":source.id,"stage":int(stage),"seconds":0.0,"watch_started":false,"watch_animal":"","player_ready":false,"watch_ready":false}
	var goal := current_stage(result)
	if goal.is_empty():return result
	result.active.seconds=clampf(_number(value.active.get("seconds",0),0),0,float(goal.get("seconds",0)))
	if goal.action=="watch" and value.active.get("watch_started") is bool and value.active.watch_started and value.active.get("watch_animal") is String and WolfMainStory.valid_watch_identity(value.active.watch_animal):
		result.active.watch_started=true;result.active.watch_animal=value.active.watch_animal
	elif goal.action=="watch":result.active.seconds=0.0
	return result

static func _number(value: Variant,fallback: float) -> float:
	if value is int or value is float:
		var number := float(value)
		return number if is_finite(number) else fallback
	return fallback
