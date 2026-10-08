class_name WolfMainStory
extends RefCounted

# Campaign checkpoints contain earned progress, never moved animals, elapsed
# world time, canonical goal coordinates, or live proximity/visibility flags.
const VERSION := 1
static var _chapters: Array[Dictionary] = []
static var _chapter_titles: Array[String] = []

static func chapters() -> Array[Dictionary]:
	if not _chapters.is_empty():return _chapters
	var home: Array[Dictionary]=WolfWorldData.nature_sites(0)
	var meadow: Array[Dictionary]=WolfWorldData.nature_sites(3)
	var river: Array[Dictionary]=WolfWorldData.nature_sites(2)
	var pine: Array[Dictionary]=WolfWorldData.nature_sites(1)
	var meadow_world: Dictionary=WolfWorldData.generate(3)
	var den := Vector2(1692,2180)
	_chapters=[
		{"id":"circle","title":"1 · Ein Geruch, der bleibt","summary":"Von vertrauter Nähe zum ersten gemeinsamen Aufbruch.","text":"Du bist noch ein junger Wolf. Feuchte Erde, warmes Fell und Kiefernharz mischen sich vor der Höhle. Die Mutter prüft den Wind. Heute kannst du lernen, wie Wasser, Deckung und vertraute Gerüche deine Heimat zusammenhalten.","ending":"Ein Stupser, dann ruhige Pfoten neben der Mutter. Die Höhle bleibt der Mittelpunkt deiner ersten Wege.","skill":"pack","stages":[
			{"action":"greet","region":0,"p":Vector2(1430,2260),"radius":400.0,"objective":"Begrüße die Mutter in deiner Heimat mit Aktion."},
			{"action":"joint","region":0,"p":Vector2(1580,2320),"radius":260.0,"seconds":3.0,"home_meeting":true,"requires_escort":false,"meeting_center":Vector2(1580,2180),"objective":"Bleib nahe dem Höhleneingang ruhig stehen. Die Mutter kommt zu dir; lauscht drei aktive Sekunden gemeinsam."}
		]},
		{"id":"water","title":"2 · Das Wasser unter Wurzeln","summary":"Ein erreichbares Ufer wird Teil deines vertrauten Kreises.","text":"Ein feuchter Geruch zieht zwischen den Stämmen hindurch. Deine Mutter folgt mit Abstand. An der trockenen Uferkante erkennst du: Wasser gehört zum Alltag, aber feste Pfoten und ein sicherer Rückweg gehören dazu.","ending":"Der Durst ist gestillt. Du behältst nicht nur den Wassergeschmack, sondern auch den trockenen Zugang im Gedächtnis.","skill":"nose","stages":[
			{"action":"joint","region":0,"p":WolfWorldData.water_bank(0),"radius":125.0,"seconds":3.0,"objective":"Erreiche das trockene Ufer am Heimatteich. Warte drei Sekunden, bis die Mutter neben dir steht."},
			{"action":"drink","region":0,"p":WolfWorldData.water_bank(0),"radius":170.0,"objective":"Trinke jetzt mit Aktion am eben erreichten Ufer."}
		]},
		{"id":"memory","title":"3 · Eine Heimat aus Gerüchen","summary":"Wurzeln und ein alter Schlafplatz verbinden Wasser und Rückweg.","text":"Nicht überall liegt ein sichtbarer Wechsel. Zwischen Wurzeln und Farnen bleiben Gerüche länger als ein Abdruck. Du prüfst zwei geschützte Orte und hinterlässt am alten Schlafplatz einen eigenen Duft. So wird aus einer fremden Strecke ein vertrauter Rückweg.","ending":"Wurzelversteck und alter Schlafplatz sind keine Punkte auf einer fremden Karte mehr. Du hast sie selbst geprüft und verbunden.","skill":"nose","stages":[
			_site(home[0],0,"Prüfe das Wurzelversteck mit Aktion."),
			_site(home[2],0,"Prüfe danach den alten Schlafplatz mit Aktion."),
			{"action":"mark","region":0,"p":home[2].p,"radius":150.0,"objective":"Wähle am alten Schlafplatz mit Aktion Duft setzen."}
		]},
		{"id":"wind","title":"4 · Der offene Wind","summary":"Mit der Mutter an den Wiesenrand und einer frischen Fährte folgen.","text":"Nördlich deiner Höhle werden die Kronen lichter. An der Bergwiese trägt der Wind Gerüche weit. Bleibe erst mit der Mutter an einer geschützten Blumeninsel stehen. Dann vergleiche zwei Trittsiegel derselben Hasenfährte, statt jedem Rascheln nachzulaufen.","ending":"Zwei frische Trittsiegel zeigen dieselbe Richtung. Du gehst bewusster und hältst die Verbindung zur Mutter.","skill":"nose","stages":[
			{"action":"joint","region":3,"p":meadow[0].p,"radius":125.0,"seconds":3.0,"objective":"Erreiche die Wildblumeninsel auf der Bergwiese. Lausche dort drei Sekunden gemeinsam mit der Mutter."},
			{"action":"track","region":3,"p":meadow_world.tracks[9].p,"radius":100.0,"track_id":"3:9","objective":"Schnüffle und lies mit Aktion das erste markierte Trittsiegel der Hasenfährte."},
			{"action":"track","region":3,"p":meadow_world.tracks[11].p,"radius":100.0,"track_id":"3:11","objective":"Folge dieser Fährte zum nächsten markierten Trittsiegel. Prüfe es erneut mit Aktion."}
		]},
		{"id":"patience","title":"5 · Leise im Gras","summary":"Aufmerksamkeit verstehen, ohne ein Tier aufzuscheuchen.","text":"Zwischen den Halmen bewegt ein Reh die Ohren. Du brauchst weder einen Sprint noch eine Jagd. Ein ruhiger Blick mit genügend Abstand zeigt dir, wie es seine Umgebung prüft. Der Rehwechsel trägt später einen Teil desselben Geruchs.","ending":"Du hast ein ruhiges Reh und seinen Wechsel selbst erlebt. Geduld hilft dir, die Landschaft zu lesen.","skill":"stealth","stages":[
			{"action":"watch","region":3,"p":Vector2(1800,1580),"radius":420.0,"seconds":4.0,"species":"Reh","objective":"Beobachte mit Aktion ein ruhiges Reh im 3D-Wolfsblick. Halte dasselbe Tier vier Sekunden mit Abstand und freier Sicht im Blick."},
			_site(meadow[3],3,"Prüfe danach den Rehwechsel auf der Bergwiese mit Aktion.")
		]},
		{"id":"banks","title":"6 · Der Bach trennt den Duft","summary":"Die Mutter begleitet dich an beide Seiten des Flusses.","text":"Östlich der Bergwiese trägt der Bach Gerüche fort. Du bleibst am trockenen Ufer und wartest auf die Mutter. Nach dem Trinken suchst du über eine vorhandene Brücke die Kieselbank auf der anderen Seite. Wasser lässt manche Fährte verblassen; feste Orte bleiben eine Orientierung.","ending":"Du kennst jetzt Ufer und Kieselbank. Eine Brücke und zwei selbst erlebte Orte verbinden die getrennten Düfte.","skill":"nose","stages":[
			{"action":"joint","region":2,"p":WolfWorldData.water_bank(2),"radius":125.0,"seconds":3.0,"objective":"Erreiche die Flussauen und warte am trockenen Ufer drei Sekunden gemeinsam mit der Mutter."},
			{"action":"drink","region":2,"p":WolfWorldData.water_bank(2),"radius":170.0,"objective":"Trinke jetzt vom trockenen Flussufer mit Aktion."},
			_site(river[0],2,"Nutze eine Brücke und prüfe die Kieselbank am anderen Ufer mit Aktion.")
		]},
		{"id":"return","title":"7 · Der Rückweg riecht vertraut","summary":"Über den Kiefernwald gemeinsam zur Familie zurückfinden.","text":"Wassergeruch weicht Harz und trockenem Nadelboden. Im Kiefernwald prüfst du einen harzigen Stamm und setzt einen eigenen Duft. Dann führst du deinen Weg zur Höhle zurück. Du wartest auch dort auf die Mutter; Ankommen bedeutet für ein Rudel gemeinsame Nähe.","ending":"Die Höhle liegt wieder vor dir. Du hast den Kreis aus Wasser, Wiese und Wald aus eigener Bewegung geschlossen.","skill":"pack","stages":[
			_site(pine[0],1,"Prüfe den harzigen Stamm im Kiefernwald mit Aktion."),
			{"action":"mark","region":1,"p":pine[0].p,"radius":150.0,"objective":"Wähle am harzigen Stamm mit Aktion Duft setzen."},
			{"action":"joint","region":0,"p":den,"radius":125.0,"seconds":3.0,"objective":"Kehre zur Rudelhöhle zurück. Warte dort drei Sekunden gemeinsam mit der Mutter."}
		]},
		{"id":"home","title":"8 · Der Kreis bleibt offen","summary":"Ein vertrauter Ruf, echte Ruhe und eine Heimat für neue Wege.","text":"An der Höhle treffen die Düfte deiner Familie auf die Erinnerungen deines Wegs. Ein kurzer Ruf hält die Verbindung. Danach legst du dich im Schutz der Höhle nieder. Dein Körper bleibt jung; Erfahrung wächst schneller als die Tage. Morgen dürfen neue Wege dazukommen.","ending":"Du ruhst bei der Mutter. Der erste eigene Kreis ist geschlossen, aber die Wildnis bleibt offen. Deine übrigen Rudelgeschichten und Begegnungen gehen weiter.","skill":"pack","stages":[
			{"action":"howl","region":0,"p":den,"radius":250.0,"objective":"Heule jetzt nahe der Rudelhöhle und lausche auf die vertraute Antwort."},
			{"action":"rest","region":0,"p":den,"radius":185.0,"objective":"Ruhe jetzt mit Aktion oder dem Rastknopf im Schutz der Rudelhöhle."},
			{"action":"rest_wait","region":0,"p":den,"radius":185.0,"seconds":4.0,"objective":"Bleibe vier aktive Sekunden ruhig liegen, mit der Mutter in deiner Nähe."}
		]}
	]
	for scene in _chapters:
		_chapter_titles.append(scene.title)
		var titles: Array[String]=[]
		var actions: Array[String]=[]
		for stage in scene.stages:titles.append(stage.objective);actions.append(stage.action)
		scene.stage_titles=titles;scene.stage_actions=actions
	return _chapters

static func _site(site: Dictionary,region: int,objective: String) -> Dictionary:
	return {"action":"site","region":region,"p":site.p,"radius":150.0,"site_id":site.site,"objective":objective}

static func initial() -> Dictionary:
	return {"version":VERSION,"started":false,"chapter":0,"stage":0,"completed_chapters":[],"seconds":0.0,"watch_started":false,"watch_animal":"","player_ready":false,"companion_ready":false,"watch_ready":false}

static func begin(progress: Dictionary) -> bool:
	if progress.get("started",false):return false
	progress.clear();progress.merge(initial());progress.started=true
	return true

static func current_stage(progress: Dictionary) -> Dictionary:
	if not progress.get("started",false):return {}
	var chapter := int(progress.get("chapter",0))
	if chapter<0 or chapter>=chapters().size():return {}
	var stages: Array=chapters()[chapter].stages
	var stage := int(progress.get("stage",0))
	return stages[stage] if stage>=0 and stage<stages.size() else {}

static func status(progress: Dictionary,region: int,pos: Vector2,escort: bool) -> Dictionary:
	var all: Array[Dictionary]=chapters()
	var chapter := clampi(int(progress.get("chapter",0)),0,all.size())
	var started: bool=progress.get("started",false)
	var done := started and chapter==all.size()
	var scene: Dictionary=all[mini(chapter,all.size()-1)]
	var stages: Array=scene.stages
	var stage := clampi(int(progress.get("stage",0)),0,stages.size()) if started and not done else 0
	var ready := started and not done and stage==stages.size()
	var goal: Dictionary=stages[mini(stage,stages.size()-1)]
	var live_region: bool=region==int(goal.region) and pos.is_finite()
	var player_in_zone: bool=live_region and _player_at_goal(goal,pos)
	var requires_escort: bool=goal.get("requires_escort",true)
	var home_meeting: bool=started and not ready and not done and goal.get("home_meeting",false)
	var player_ready: bool=player_in_zone and progress.get("player_ready",false)
	var companion_ready: bool=player_ready and (escort or not requires_escort) and progress.get("companion_ready",false)
	var seconds_required := float(goal.get("seconds",0))
	return {"started":started,"chapter":chapter,"stage":stage,"title":"Der Kreis deiner Pfoten" if done else scene.title,"text":scene.ending if ready or done else scene.text,"chapter_summary":scene.summary,"objective":"Der erste Kreis ist geschlossen. Erkunde die Wildnis und erlebe weitere Rudelgeschichten." if done else "Dieses Kapitel ist erlebt. Öffne die Hauptgeschichte, um weiterzugehen." if ready else goal.objective,"progress":"8 / 8 Kapitel" if done else "%d / %d Schritte"%[stage,stages.size()],"current":stages.size() if done else stage,"required":stages.size(),"ready":ready,"done":done,"target_region":int(goal.region),"target_pos":goal.p,"action":"" if ready or done else goal.action,"chapters_count":all.size(),"chapter_titles":_chapter_titles,"stage_titles":scene.stage_titles,"stage_actions":scene.stage_actions,"track_id":goal.get("track_id","") if not ready and not done else "","site_id":goal.get("site_id","") if not ready and not done else "","species":goal.get("species","") if not ready and not done else "","seconds":minf(seconds_required,float(progress.get("seconds",0))) if started and not ready and not done else 0.0,"seconds_required":seconds_required if started and not ready and not done else 0.0,"home_meeting":home_meeting,"requires_escort":requires_escort if started and not ready and not done else false,"player_in_zone":player_in_zone if started and not ready and not done else false,"player_ready":player_ready if started and not ready and not done else false,"companion_ready":companion_ready if started and not ready and not done else false,"watch_ready":live_region and progress.get("watch_ready",false) if started and not ready and not done else false,"watch_started":progress.get("watch_started",false) if started and not ready and not done else false,"watch_animal":str(progress.get("watch_animal","")) if started and not ready and not done else ""}

static func advance(progress: Dictionary) -> bool:
	if not progress.get("started",false):return false
	var chapter := int(progress.get("chapter",0))
	if chapter<0 or chapter>=chapters().size():return false
	if int(progress.get("stage",0))!=chapters()[chapter].stages.size():return false
	var identifier: String=chapters()[chapter].id
	if not progress.completed_chapters.has(identifier):progress.completed_chapters.append(identifier)
	progress.chapter=chapter+1;progress.stage=0
	_reset_stage(progress)
	return true

static func note_action(progress: Dictionary,action: String,detail: String,region: int,pos: Vector2,animal: Dictionary={}) -> bool:
	var goal := current_stage(progress)
	if goal.is_empty() or action!=str(goal.action) or region!=int(goal.region) or not pos.is_finite():return false
	# The mother follows a genuine daily routine, so the first greeting is
	# tied to the actual animal, not to yesterday's fixed position by the den.
	if action!="greet" and pos.distance_to(goal.p)>=float(goal.radius):return false
	match action:
		"greet":
			if not _parent(animal,region) or pos.distance_to(animal.p)>=135:return false
		"site":
			if detail!=str(goal.site_id):return false
		"track":
			if detail!=str(goal.track_id):return false
		"drink","mark","howl","rest":pass
		_:return false
	_finish_stage(progress)
	return true

static func note_observation(progress: Dictionary,animal: Dictionary,region: int,pos: Vector2,player_speed: float,quiet: bool,clear_view: bool) -> bool:
	var goal := current_stage(progress)
	if goal.is_empty() or goal.action!="watch" or not _watch_valid(goal,animal,region,pos,player_speed,quiet,clear_view):return false
	var identifier := WolfPackLife.animal_key(animal)
	if not valid_watch_identity(identifier):return false
	if progress.get("watch_started",false) and str(progress.get("watch_animal",""))!=identifier:return false
	progress.watch_started=true;progress.watch_animal=identifier
	return true

static func tick(progress: Dictionary,dt: float,region: int,pos: Vector2,escort: bool,parent: Dictionary,parent_path_clear: bool,player_speed: float,watch_animal: Dictionary,watch_clear: bool,quiet: bool,player_mood: String) -> bool:
	clear_live(progress)
	var goal := current_stage(progress)
	if goal.is_empty() or not is_finite(dt) or not is_finite(player_speed) or not pos.is_finite() or dt<=0:return false
	if goal.action not in ["joint","watch","rest_wait"] or region!=int(goal.region):return false
	var amount := clampf(dt,0,0.1)
	if goal.action=="watch":
		progress.watch_ready=_watch_valid(goal,watch_animal,region,pos,player_speed,quiet,watch_clear)
		if not progress.watch_ready or not progress.get("watch_started",false):return false
		if WolfPackLife.animal_key(watch_animal)!=str(progress.get("watch_animal","")):progress.watch_ready=false;return false
	else:
		progress.player_ready=_player_at_goal(goal,pos) and player_speed>=0 and player_speed<=1
		if goal.action=="rest_wait" and player_mood!="ruhen":progress.player_ready=false
		var escort_allowed: bool=escort or not goal.get("requires_escort",true)
		var parent_at_goal: bool=_parent(parent,region) and (parent.p.distance_to(goal.meeting_center)<300 if goal.get("home_meeting",false) else parent.p.distance_to(goal.p)<220)
		progress.companion_ready=escort_allowed and parent_path_clear and parent_at_goal and parent.p.distance_to(pos)<150 and _number(parent.get("speed",0),INF)<=1
		if not progress.player_ready or not progress.companion_ready:return false
	progress.seconds=minf(float(goal.seconds),float(progress.get("seconds",0))+amount)
	if float(progress.seconds)+0.0001>=float(goal.seconds):
		_finish_stage(progress)
		return true
	return false

static func clear_live(progress: Dictionary) -> void:
	progress.player_ready=false;progress.companion_ready=false;progress.watch_ready=false

static func home_meeting_active(progress: Dictionary,region: int,pos: Vector2) -> bool:
	var goal := current_stage(progress)
	return not goal.is_empty() and goal.get("home_meeting",false) and region==0 and pos.is_finite() and _player_at_goal(goal,pos)

static func _player_at_goal(goal: Dictionary,pos: Vector2) -> bool:
	if not pos.is_finite():return false
	var center: Vector2=goal.meeting_center if goal.get("home_meeting",false) else goal.p
	return pos.distance_to(center)<float(goal.radius)

static func _reset_stage(progress: Dictionary) -> void:
	progress.seconds=0.0;progress.watch_started=false;progress.watch_animal=""
	clear_live(progress)

static func _finish_stage(progress: Dictionary) -> void:
	progress.stage=int(progress.get("stage",0))+1
	_reset_stage(progress)

static func _parent(animal: Dictionary,region: int) -> bool:
	if animal.is_empty() or animal.get("kind","")!="wolf" or animal.get("young",false) or animal.get("role","")!="Mutter":return false
	if not animal.get("p") is Vector2 or not animal.p.is_finite():return false
	return region==0 or animal.get("companion",false)

static func _watch_valid(goal: Dictionary,animal: Dictionary,region: int,pos: Vector2,player_speed: float,quiet: bool,clear_view: bool) -> bool:
	if region!=int(goal.region) or not pos.is_finite() or not is_finite(player_speed) or player_speed>1 or player_speed<0 or not quiet or not clear_view:return false
	if animal.is_empty() or animal.get("kind","")!="deer" or not animal.get("p") is Vector2 or not animal.p.is_finite():return false
	var distance: float=pos.distance_to(animal.p)
	if distance<145 or distance>420:return false
	if _number(animal.get("alarm",0),INF)>0 or _number(animal.get("attention",0),INF)>0.65:return false
	if animal.get("behavior","") in ["flee","recover"] or animal.get("mood","")=="fliehen":return false
	return _number(animal.get("speed",0),INF)<=35

static func saved(progress: Dictionary) -> Dictionary:
	return {"version":VERSION,"started":bool(progress.get("started",false)),"chapter":int(progress.get("chapter",0)),"stage":int(progress.get("stage",0)),"completed_chapters":progress.get("completed_chapters",[]).duplicate(),"seconds":float(progress.get("seconds",0)),"watch_started":bool(progress.get("watch_started",false)),"watch_animal":str(progress.get("watch_animal",""))}

static func restored(value: Variant) -> Dictionary:
	var result := initial()
	if not value is Dictionary or _number(value.get("version",0),0)!=VERSION or value.get("started") is not bool or not value.started:return result
	result.started=true
	var all := chapters()
	if value.get("completed_chapters") is Array:
		for index in range(mini(value.completed_chapters.size(),all.size())):
			if value.completed_chapters[index] is not String or value.completed_chapters[index]!=all[index].id:break
			result.completed_chapters.append(all[index].id)
	result.chapter=result.completed_chapters.size()
	if result.chapter==all.size():return result
	# Contiguous earned chapter IDs are authoritative. Damaged checkpoints
	# reset the current objective; they cannot move a goal or award a chapter.
	if _number(value.get("chapter",-1),-1)!=int(result.chapter):return result
	var stage_number := _number(value.get("stage",0),0)
	var stage_count: int=all[int(result.chapter)].stages.size()
	if stage_number<0 or stage_number>stage_count or stage_number!=floorf(stage_number):return result
	result.stage=int(stage_number)
	var goal := current_stage(result)
	if goal.is_empty():return result
	result.seconds=clampf(_number(value.get("seconds",0),0),0,float(goal.get("seconds",0)))
	if goal.action=="watch" and value.get("watch_started") is bool and value.watch_started and value.get("watch_animal") is String and valid_watch_identity(value.watch_animal):
		result.watch_started=true;result.watch_animal=value.watch_animal
	elif goal.action=="watch":result.seconds=0.0
	return result

static func valid_watch_identity(identifier: String) -> bool:
	var parts := identifier.split(":")
	if parts.size()!=4 or parts[0]!="deer":return false
	for index in range(1,4):
		if not parts[index].is_valid_float() or not is_finite(float(parts[index])):return false
	return float(parts[1])>=20 and float(parts[1])<=3180 and float(parts[2])>=20 and float(parts[2])<=3180 and absf(float(parts[3]))<=1000

static func _number(value: Variant,fallback: float) -> float:
	if value is int or value is float:
		var number := float(value)
		return number if is_finite(number) else fallback
	return fallback
