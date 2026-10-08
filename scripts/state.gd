class_name WolfState
extends RefCounted

const DAY_SECONDS := 3600.0
const SEASON_DAYS := 30
const ENCOUNTER_ACTIONS := ["drink","rest","howl","greet","feed","site","mark"]
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
var sites: Array[String] = []
var story_step := 0
var story_choices: Array[String] = []
var skills := {"nose":0,"stealth":0,"pack":0}
var escort := false
var waypoint_region := -1
var waypoint_pos := Vector2.ZERO
var tracked_quest := ""
var sound_enabled := true
var reduced_motion := false
var weather_enabled := true
var map_reveal := false
var camera_follow := false
var smooth_edges := true
var compact_hud := true
var pawsteps: Array[Dictionary] = []
var action_counts := {"drink":0,"rest":0,"howl":0,"greet":0,"feed":0,"site":0,"mark":0,"observe:Reh":0,"observe:Hase":0,"observe:Fuchs":0}
var active_encounter: Dictionary = {}
var completed_encounters: Array[String] = []
var encounter_serial := 0
var encounter_preview_key := ""
var encounter_preview: Dictionary = {}
var routine_seen: Array[String] = []
var pack_signal: Dictionary = {}
var main_story_progress: Dictionary = WolfMainStory.initial()
var nature_journey_progress: Dictionary = WolfNatureJourneys.initial()



func tick(dt: float, moving: bool, sprint: bool) -> void:
	elapsed += dt
	thirst = maxf(0,thirst-dt*0.018)
	hunger = maxf(0,hunger-dt*0.01)
	energy = clampf(energy + dt*(-0.8 if sprint and moving else -0.025 if moving else 0.16),0,100)
	food_cooldown=maxf(0,food_cooldown-dt)
	var routine: Dictionary=pack_routine()
	if region==0 and not routine_seen.has(routine.label):routine_seen.append(routine.label)

func level() -> int:
	return 1+int(xp/100)

func biome_count(kind: String) -> int:
	var count := 0
	for index in visited:
		if WolfWorldData.REGIONS[index].biome==kind:count+=1
	return count

func quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
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
		{"id":"river","name":"Das Lied des Wassers","hint":"Erkunde Flussauen und Wasserfalltal.","done":biome_count("river")>=2,"progress":"%d/2"%mini(biome_count("river"),2)},
		{"id":"fox","name":"Roter Schatten","hint":"Beobachte einen Fuchs aus dem Wolfsblick.","done":observations.has("Fuchs"),"progress":"1/1" if observations.has("Fuchs") else "0/1"},
		{"id":"ruins","name":"Steine voller Geschichten","hint":"Finde die Moosruinen westlich des Startgebiets.","done":visited.has(10),"progress":"1/1" if visited.has(10) else "0/1"},
		{"id":"coast","name":"Ein neuer Horizont","hint":"Erkunde die Dünenküste im Südwesten.","done":visited.has(12),"progress":"1/1" if visited.has(12) else "0/1"},
		{"id":"secret8","name":"Verborgene Heimat","hint":"Entdecke acht besondere Lichtungen oder Naturorte.","done":discoveries.size()>=8,"progress":"%d/8"%mini(discoveries.size(),8)},
		{"id":"mark","name":"Mein Weg durch die Wildnis","hint":"Markiere deinen Duft in sechs verschiedenen Gebieten.","done":marked.size()>=6,"progress":"%d/6"%mini(marked.size(),6)},
		{"id":"trail40","name":"Fährtenkundige Pfoten","hint":"Lies vierzig unterschiedliche Spuren.","done":found.size()>=40,"progress":"%d/40"%mini(found.size(),40)},
		{"id":"explore16","name":"Die große Wildnis","hint":"Erkunde sechzehn verbundene Gebiete.","done":visited.size()>=16,"progress":"%d/16"%mini(visited.size(),16)},
		{"id":"stones16","name":"Das Gedächtnis der Landschaft","hint":"Präge dir Wegsteine in sechzehn unterschiedlichen Gebieten ein.","done":landmarks.size()>=16,"progress":"%d/16"%mini(landmarks.size(),16)}
	]

	result.append_array([
		{"id":"explore64","name":"Wege durch die große Wildnis","hint":"Erkunde 64 der 256 Gebiete. Deine Übersicht merkt sich den Weg.","done":visited.size()>=64,"progress":"%d/64"%mini(visited.size(),64)},
		{"id":"sites24","name":"Eine Heimat aus Gerüchen","hint":"Lerne 24 verschiedene Naturorte kennen.","done":sites.size()>=24,"progress":"%d/24"%mini(sites.size(),24)},
		{"id":"story3","name":"Die Geschichte deiner Pfoten","hint":"Erlebe drei Kapitel im Menü Rudelgeschichte.","done":story_step>=3,"progress":"%d/3"%mini(story_step,3)},
		{"id":"escort","name":"Gemeinsam unterwegs","hint":"Begrüße die Familie; ab Bindung 48 kann ein Elternwolf dich begleiten.","done":escort,"progress":"1/1" if escort else "0/1"},
		{"id":"nose50","name":"Eine erfahrene Nase","hint":"Lies Fährten und erlebe Rudelgeschichten.","done":skills.nose>=50,"progress":"%d/50"%mini(skills.nose,50)},
		{"id":"days2","name":"Die Wildnis schläft nie","hint":"Lebe zwei Tage in der Wildnis. Menüs pausieren die Zeit.","done":elapsed>=DAY_SECONDS*2,"progress":"%d/2"%mini(int(elapsed/DAY_SECONDS),2)}
	])
	result.append_array([
		{"id":"explore256","name":"Vier Horizonte","hint":"Erkunde alle 256 miteinander verbundenen Gebiete.","done":visited.size()>=WolfWorldData.REGIONS.size(),"progress":"%d/%d"%[visited.size(),WolfWorldData.REGIONS.size()]},
		{"id":"district5","name":"Fünf Landschaften einer Heimat","hint":"Erreiche das Rudelrevier, den hohen Norden, die Südauen, die Westküste und die östlichen Höhen.","done":districts_visited().size()>=5,"progress":"%d/5"%districts_visited().size()},
		{"id":"biomes12","name":"Die Düfte der Landschaft","hint":"Erkunde alle zwölf Landschaftsarten: Wald, Kiefern, Eichen, Wiese, Schnee, Höhen, Fluss, See, Küste, Moor, Ruinen und Dorfrand.","done":biomes_visited().size()>=12,"progress":"%d/12"%biomes_visited().size()},
		{"id":"sites72","name":"Viele kleine Erinnerungen","hint":"Entdecke 72 unterschiedliche Naturorte.","done":sites.size()>=72,"progress":"%d/72"%mini(sites.size(),72)},
		{"id":"sites256","name":"Das Gedächtnis deiner Nase","hint":"Lerne 256 Naturorte in der großen Wildnis kennen.","done":sites.size()>=256,"progress":"%d/256"%mini(sites.size(),256)},
		{"id":"encounter1","name":"Ein eigener Weg","hint":"Nimm eine Wildnisbegegnung an und erfülle ihre Aufgabe.","done":completed_encounters.size()>=1,"progress":"%d/1"%mini(completed_encounters.size(),1)},
		{"id":"encounters8","name":"Die Wildnis erzählt weiter","hint":"Erlebe acht vollständige Wildnisbegegnungen.","done":completed_encounters.size()>=8,"progress":"%d/8"%mini(completed_encounters.size(),8)},
		{"id":"encounters24","name":"Vertraut mit der Wildnis","hint":"Erlebe 24 vollständige Begegnungen. Alte Aktionen erfüllen keine neue Aufgabe.","done":completed_encounters.size()>=24,"progress":"%d/24"%mini(completed_encounters.size(),24)},
		{"id":"routine","name":"Der Rhythmus des Rudels","hint":"Besuche die Familie zu fünf Tagesphasen. Die Zeit vergeht nur beim Spielen.","done":routine_seen.size()>=5,"progress":"%d/5"%routine_seen.size()},
		{"id":"pack10","name":"Vertraute Nähe","hint":"Begrüße deine Familie zehnmal mit ruhigen Abständen.","done":int(action_counts.greet)>=10,"progress":"%d/10"%mini(int(action_counts.greet),10)},
		{"id":"care","name":"Wasser, Nahrung und Ruhe","hint":"Trinke, friss und ruhe jeweils dreimal an sicheren Plätzen.","done":int(action_counts.drink)>=3 and int(action_counts.feed)>=3 and int(action_counts.rest)>=3,"progress":"%d/9"%[mini(int(action_counts.drink),3)+mini(int(action_counts.feed),3)+mini(int(action_counts.rest),3)]},
		{"id":"story18","name":"Eine wachsende Rudelgeschichte","hint":"Erlebe alle achtzehn Kapitel; deine tatsächlichen Wege öffnen neue Geschichten.","done":story_step>=18,"progress":"%d/18"%mini(story_step,18)},
		{"id":"walk50000","name":"Wege unter deinen Pfoten","hint":"Lege 50.000 Weltschritte zurück. Nur selbst gegangene Strecken zählen.","done":distance_walked>=50000,"progress":"%d/50.000"%mini(int(distance_walked),50000)},
		{"id":"mark32","name":"Vertraute Rückwege","hint":"Markiere deinen Geruch in 32 unterschiedlichen Gebieten.","done":marked.size()>=32,"progress":"%d/32"%mini(marked.size(),32)}
	])
	return result

func day() -> int:
	return 1+int(elapsed/DAY_SECONDS)

func season_name() -> String:
	return ["Frühjahr","Sommer","Herbst","Winter"][int(elapsed/(DAY_SECONDS*SEASON_DAYS))%4]

func season_progress() -> float:
	return fposmod(elapsed/(DAY_SECONDS*SEASON_DAYS),1.0)

func districts_visited() -> Array[String]:
	var result: Array[String]=[]
	for index in visited:
		var district: String=WolfWorldData.REGIONS[index].district
		if not result.has(district):result.append(district)
	return result

func biomes_visited() -> Array[String]:
	var result: Array[String]=[]
	for index in visited:
		var biome: String=WolfWorldData.REGIONS[index].biome
		if not result.has(biome):result.append(biome)
	return result

func pack_routine(role: String="Mutter") -> Dictionary:
	return WolfPackLife.routine(hour(),role)

func main_story_status() -> Dictionary:
	return WolfMainStory.status(main_story_progress,region,pos,escort)

func main_story_home_meeting_active() -> bool:
	return WolfMainStory.home_meeting_active(main_story_progress,region,pos)

func begin_main_story() -> bool:
	if not WolfMainStory.begin(main_story_progress):return false
	record("Hauptgeschichte beginnt · Der Kreis deiner Pfoten. Du lernst mit der Mutter Wasser, Deckung und den Weg zurück kennen.")
	return true

func advance_main_story() -> bool:
	var before := int(main_story_progress.get("chapter",0))
	if not WolfMainStory.advance(main_story_progress):return false
	var scene: Dictionary=WolfMainStory.chapters()[before]
	xp+=40
	bond=minf(100,bond+2)
	skills[scene.skill]=mini(100,int(skills[scene.skill])+3)
	record("Hauptgeschichte · "+scene.title+" · "+scene.ending)
	return true

func note_main_story_action(action: String,detail: String="",animal: Dictionary={}) -> bool:
	var goal := WolfMainStory.current_stage(main_story_progress)
	var changed := WolfMainStory.note_action(main_story_progress,action,detail,region,pos,animal)
	_record_main_story_progress(goal,changed)
	return changed

func note_main_story_observation(animal: Dictionary,player_speed: float,quiet: bool,clear_view: bool=true) -> bool:
	return WolfMainStory.note_observation(main_story_progress,animal,region,pos,player_speed,quiet,clear_view)

func tick_main_story(dt: float,parent: Dictionary={},parent_path_clear: bool=false,player_speed: float=0,watch_animal: Dictionary={},watch_clear: bool=false,quiet: bool=false,player_mood: String="") -> bool:
	var goal := WolfMainStory.current_stage(main_story_progress)
	var changed := WolfMainStory.tick(main_story_progress,dt,region,pos,escort,parent,parent_path_clear,player_speed,watch_animal,watch_clear,quiet,player_mood)
	_record_main_story_progress(goal,changed)
	return changed

func clear_main_story_presence() -> void:
	WolfMainStory.clear_live(main_story_progress)

func _record_main_story_progress(goal: Dictionary,changed: bool) -> void:
	if changed and not goal.is_empty():record("Hauptgeschichte · Ein eigener Schritt · "+str(goal.objective))

func nature_journeys_options() -> Array[Dictionary]:
	return WolfNatureJourneys.options(nature_journey_progress,region)

func nature_journey_status() -> Dictionary:
	return WolfNatureJourneys.status(nature_journey_progress,region,pos)

func begin_nature_journey(id: String) -> bool:
	if not WolfNatureJourneys.begin(nature_journey_progress,id,region):return false
	var journey := nature_journey_status()
	record("Naturreise beginnt · "+str(journey.title)+" · "+str(journey.text))
	return true

func claim_nature_journey() -> bool:
	var journey := nature_journey_status()
	if not WolfNatureJourneys.claim(nature_journey_progress):return false
	xp+=int(journey.reward)
	skills[journey.skill]=mini(100,int(skills[journey.skill])+2)
	bond=minf(100,bond+1)
	record("Naturreise erlebt · "+str(journey.title)+" · Du behältst diesen eigenen Weg im Gedächtnis.")
	return true

func abandon_nature_journey() -> bool:
	if not WolfNatureJourneys.abandon(nature_journey_progress):return false
	record("Naturreise unterbrochen · Du kannst später einen neuen eigenen Weg beginnen.")
	return true

func note_nature_journey_action(action: String,detail: String="") -> bool:
	var goal := WolfNatureJourneys.current_stage(nature_journey_progress)
	var changed := WolfNatureJourneys.note_action(nature_journey_progress,action,detail,region,pos)
	_record_nature_journey_progress(goal,changed)
	return changed

func note_nature_journey_observation(animal: Dictionary,player_speed: float,quiet: bool,clear_view: bool=true) -> bool:
	return WolfNatureJourneys.note_observation(nature_journey_progress,animal,region,pos,player_speed,quiet,clear_view)

func tick_nature_journey(dt: float,player_speed: float=0,watch_animal: Dictionary={},watch_clear: bool=false,quiet: bool=false,player_mood: String="") -> bool:
	var goal := WolfNatureJourneys.current_stage(nature_journey_progress)
	var changed := WolfNatureJourneys.tick(nature_journey_progress,dt,region,pos,player_speed,watch_animal,watch_clear,quiet,player_mood)
	_record_nature_journey_progress(goal,changed)
	return changed

func clear_nature_journey_presence() -> void:
	WolfNatureJourneys.clear_live(nature_journey_progress)

func _record_nature_journey_progress(goal: Dictionary,changed: bool) -> void:
	if changed and not goal.is_empty():record("Naturreise · Ein eigener Schritt · "+str(goal.objective))

func note_action(action: String,detail: String="") -> void:
	var key := action+":"+detail if action=="observe" else action
	if not action_counts.has(key):return
	action_counts[key]=mini(100000000,int(action_counts[key])+1)
	note_main_story_action(action,detail)
	note_nature_journey_action(action,detail)
	if action in ["greet","rest","howl"]:
		pack_signal={"action":action,"region":region,"pos":pos,"at":elapsed,"serial":int(action_counts[key])}
	if active_encounter.is_empty():return
	if active_encounter.task=="water_rest" and region==int(active_encounter.region):
		if action=="drink":active_encounter.drank_after_start=true
		if action=="rest" and active_encounter.get("drank_after_start",false):active_encounter.rested_after_drink=true
	if active_encounter.task=="family" and region==0:
		if action=="greet":active_encounter.greeted_family=true
		if action=="howl" and pos.distance_to(Vector2(1600,2240))<460:active_encounter.family_howl=true
	if region!=int(active_encounter.region):return
	if active_encounter.task=="care_route":
		if action=="drink" and pos.distance_to(active_encounter.water_pos)<170:active_encounter.care_drink=true
		if action=="feed" and active_encounter.get("care_drink",false) and pos.distance_to(active_encounter.food_pos)<90:active_encounter.care_feed=true
		if action=="rest" and active_encounter.get("care_feed",false) and pos.distance_to(active_encounter.rest_pos-Vector2(112,0))<190:active_encounter.care_rest=true
	elif active_encounter.task=="edge_pair" and action=="observe":
		if detail==active_encounter.detail:active_encounter.pair_first=true
		if detail==active_encounter.second_detail:active_encounter.pair_second=true
	elif active_encounter.task=="site_mark":
		if action=="site" and detail==active_encounter.site_id and pos.distance_to(active_encounter.target_pos)<150:active_encounter.site_checked=true
		if action=="mark" and active_encounter.get("site_checked",false) and pos.distance_to(active_encounter.target_pos)<150:active_encounter.site_marked=true

func clear_encounter_presence() -> void:
	# Presence is a live measurement; the earned visit and observation time
	# remain valid when a view, region or foreground session changes.
	clear_main_story_presence()
	clear_nature_journey_presence()
	if active_encounter.is_empty():return
	if active_encounter.task=="wildlife_cycle":active_encounter.current_activity=""
	if active_encounter.task=="pack_walk":active_encounter.player_ready=false;active_encounter.companion_ready=false

func note_wildlife_observation(species: String,animal: Dictionary,player_pos: Vector2,player_speed: float,quiet: bool) -> void:
	if active_encounter.is_empty() or active_encounter.task not in ["quiet_watch","wildlife_cycle"]:return
	if not _valid_watch_candidate(species,animal,player_pos,player_speed,quiet):return
	var identifier := WolfPackLife.animal_key(animal)
	if identifier.is_empty():return
	if str(active_encounter.get("watch_animal",""))!=identifier:
		active_encounter.watch_seconds=0.0
		active_encounter.cycle_first=false;active_encounter.cycle_second=false
		active_encounter.first_activity="";active_encounter.activity_seconds=0.0
		active_encounter.current_activity="";active_encounter.counted_activity=""
	active_encounter.watch_animal=identifier
	active_encounter.watch_started=true

func tick_wildlife_observation(dt: float,species: String,animal: Dictionary,player_pos: Vector2,player_speed: float,quiet: bool) -> void:
	if active_encounter.is_empty() or active_encounter.task not in ["quiet_watch","wildlife_cycle"]:return
	if active_encounter.task=="wildlife_cycle":active_encounter.current_activity=""
	if not active_encounter.get("watch_started",false) or not is_finite(dt):return
	if not _valid_watch_candidate(species,animal,player_pos,player_speed,quiet):return
	if WolfPackLife.animal_key(animal)!=str(active_encounter.get("watch_animal","")):return
	if active_encounter.task=="quiet_watch":
		active_encounter.watch_seconds=minf(12.0,float(active_encounter.get("watch_seconds",0))+clampf(dt,0,0.1))
		return
	var activity: String=animal.get("behavior","")
	var poses := {"forage":["grasen","schnüffeln"],"drink":["trinken"],"shelter":["ruhen","lauschen"]}
	if not poses.has(activity) or animal.get("mood","") not in poses[activity] or float(animal.get("speed",1))>1:return
	if not animal.get("target_pos") is Vector2 or animal.p.distance_to(animal.target_pos)>=14:return
	active_encounter.current_activity=activity
	if active_encounter.get("cycle_second",false):return
	if active_encounter.get("cycle_first",false) and activity==str(active_encounter.first_activity):return
	if str(active_encounter.get("counted_activity",""))!=activity:active_encounter.activity_seconds=0.0
	active_encounter.counted_activity=activity
	active_encounter.activity_seconds=minf(3.0,float(active_encounter.get("activity_seconds",0))+clampf(dt,0,0.1))
	if float(active_encounter.activity_seconds)>=2.9999:
		if not active_encounter.get("cycle_first",false):
			active_encounter.cycle_first=true
			active_encounter.first_activity=activity
			active_encounter.activity_seconds=0.0
		else:active_encounter.cycle_second=true

func tick_pack_walk(dt: float,animal: Dictionary,player_speed: float,clear_path: bool=true) -> void:
	if active_encounter.is_empty() or active_encounter.task!="pack_walk":return
	active_encounter.player_ready=false;active_encounter.companion_ready=false
	if not is_finite(dt) or not is_finite(player_speed) or not escort or region!=int(active_encounter.region):return
	if animal.is_empty() or animal.get("kind","")!="wolf" or animal.get("young",false) or not animal.get("p") is Vector2:return
	if not animal.get("companion",false) and not (region==0 and animal.get("role","")=="Mutter"):return
	var target: Vector2=active_encounter.second_pos if active_encounter.get("pack_first",false) else active_encounter.first_pos
	active_encounter.player_ready=pos.distance_to(target)<125
	active_encounter.companion_ready=clear_path and animal.p.distance_to(target)<200 and animal.p.distance_to(pos)<150
	if not active_encounter.player_ready or not active_encounter.companion_ready or player_speed>1:return
	active_encounter.joint_seconds=minf(3.0,float(active_encounter.get("joint_seconds",0))+clampf(dt,0,0.1))
	if float(active_encounter.joint_seconds)>=2.9999:
		if not active_encounter.get("pack_first",false):
			active_encounter.pack_first=true;active_encounter.joint_seconds=0.0
			clear_encounter_presence()
		else:active_encounter.pack_second=true

func _valid_watch_candidate(species: String,animal: Dictionary,player_pos: Vector2,player_speed: float,quiet: bool) -> bool:
	if region!=int(active_encounter.region) or species!=str(active_encounter.get("detail","")) or animal.is_empty():return false
	if not animal.get("p") is Vector2 or not animal.get("home") is Vector2 or not is_finite(player_speed) or not player_pos.is_finite():return false
	if not animal.p.is_finite() or WolfWorldData.species(str(animal.get("kind","")))!=species:return false
	var distance: float=player_pos.distance_to(animal.p)
	return quiet and player_speed<=1.0 and distance>=145 and distance<=420 and animal.get("mood","")!="fliehen" and float(animal.get("alarm",0))<=0

func _regional_count(items: Array[String],index: int) -> int:
	var count := 0
	for item in items:
		if item.begins_with(str(index)+":"):count+=1
	return count

func _preview_encounter() -> Dictionary:
	var key := "%d:%d:%d:%d:%d:%d:%d:%d:%d"%[region,day(),encounter_serial,found.size(),sites.size(),visited.size(),int(elapsed/10),int(food_cooldown>0),int(escort)]
	if key==encounter_preview_key and not encounter_preview.is_empty():return encounter_preview.duplicate(true)
	var result: Dictionary=WolfPackLife.encounter(region,day(),encounter_serial,hour())
	if result.task=="care_route" and food_cooldown>0:result=_journey_encounter(result)
	if result.task=="pack_walk" and not escort:
		result.task="family";result.goal=2;result.target_region=0;result.target_pos=Vector2(1490,2110)
		result.title="Vertraute Pfoten vor dem gemeinsamen Weg"
		result.text="Vor einer gemeinsamen Runde suchst du den vertrauten Kontakt zur Familie. Ein kurzer Gruß und ein Ruf nahe der Höhle geben deinem Weg einen sicheren Anfang."
		result.hint="Begrüße die Familie und heule nahe der Rudelhöhle. Im Rudelmenü kannst du danach die Begleitung aktivieren."
	if result.task=="visit":
		var target := -1
		for neighbor in WolfWorldData.REGIONS[region].links.values():
			if not visited.has(int(neighbor)):target=int(neighbor);break
		if target>=0:result.target_region=target
		else:result=_journey_encounter(result)
	if result.task=="tracks":
		var remaining := maxi(0,27-_regional_count(found,region))
		if remaining<3:result=_journey_encounter(result)
		else:
			var data := WolfWorldData.generate(region)
			for track in data.tracks:
				if not found.has(track.id):result.target_pos=track.p;break
	if result.task=="sites":
		var remaining := maxi(0,WolfWorldData.SITES_PER_REGION-_regional_count(sites,region))
		if remaining<2:result=_journey_encounter(result)
		else:
			for site in WolfWorldData.nature_sites(region):
				if not sites.has(site.site):result.target_pos=site.p;break
	if result.task=="water_rest":result.target_pos=WolfWorldData.water_bank(region)
	if result.task in ["care_route","site_mark","pack_walk"]:result=_prepare_local_encounter(result)
	# A serial, never a hash of current progress, defines the one-time reward.
	result.id="%d:%d:%d"%[day(),region,encounter_serial]
	encounter_preview_key=key
	encounter_preview=result.duplicate(true)
	return result

func _prepare_local_encounter(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	var origin: int=int(result.region)
	var serial: int=int(str(result.id).split(":")[2])
	if result.task=="pack_walk":
		var places := WolfWorldData.nature_sites(origin)
		result.first_pos=places[posmod(serial,WolfWorldData.SITES_PER_REGION)].p
		result.second_pos=places[posmod(serial+1,WolfWorldData.SITES_PER_REGION)].p
		result.target_pos=result.first_pos
	elif result.task=="site_mark":
		var site: Dictionary=WolfWorldData.nature_sites(origin)[posmod(serial,WolfWorldData.SITES_PER_REGION)]
		result.site_id=site.site
		result.target_pos=site.p
	else:
		var data := WolfWorldData.generate(origin)
		var foods: Array=data.objects.filter(func(object: Dictionary):return object.kind=="food")
		var dens: Array=data.objects.filter(func(object: Dictionary):return object.kind=="den")
		result.water_pos=WolfWorldData.water_bank(origin)
		result.food_pos=foods[posmod(serial,foods.size())].p
		var best := INF
		for den in dens:
			var distance: float=den.p.distance_to(result.food_pos)
			if distance<best:best=distance;result.rest_pos=den.p+Vector2(112,0)
		result.target_pos=result.water_pos
	return result

func _journey_encounter(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	result.task="journey"
	result.title="Ein weiterer sicherer Wechsel"
	result.text="Die näheren Orte kennst du bereits. Du prüfst nun den Wind und gehst einen weiteren Abschnitt deines Reviers. Jeder selbst gegangene Weg hilft dir, die Landschaft wiederzuerkennen."
	result.hint="Gehe weitere 1.200 Weltschritte entlang deiner Wege."
	result.goal=1200
	result.skill="nose"
	result.target_region=region
	result.target_pos=Vector2(1600,1600)
	return result

func begin_encounter() -> bool:
	if not active_encounter.is_empty():return false
	active_encounter=_preview_encounter()
	active_encounter.baseline={"found":_regional_count(found,region),"sites":_regional_count(sites,region),"walk":distance_walked,"actions":action_counts.duplicate(true)}
	active_encounter.started=elapsed
	record("Wildnisbegegnung · "+active_encounter.title+" · "+active_encounter.hint)
	return true

func encounter_status() -> Dictionary:
	var result: Dictionary=_preview_encounter() if active_encounter.is_empty() else active_encounter.duplicate(true)
	result.accepted=not active_encounter.is_empty()
	result.current=_encounter_current(active_encounter) if result.accepted else 0
	result.done=bool(result.accepted) and int(result.current)>=int(result.goal)
	result.progress="%d/%d"%[mini(int(result.current),int(result.goal)),int(result.goal)]
	if result.accepted and result.task=="water_rest":
		if active_encounter.get("drank_after_start",false):
			result.target_pos=Vector2(2450,970) if int(result.region)!=0 else Vector2(1480,2050)
	if result.accepted and result.task=="family" and active_encounter.get("greeted_family",false):
		result.target_region=0
		result.target_pos=Vector2(1580,2025)
	if result.accepted and result.task=="care_route":
		result.target_pos=result.rest_pos if result.get("care_feed",false) else result.food_pos if result.get("care_drink",false) else result.water_pos
		if result.get("care_drink",false) and not result.get("care_feed",false) and food_cooldown>0:result.hint="Der Nahrungsplatz bleibt dein Ziel. In %d aktiven Sekunden kannst du wieder fressen; erkunde währenddessen ruhig die Umgebung."%ceili(food_cooldown)
	if result.accepted and result.task=="edge_pair" and result.get("pair_first",false):result.detail=result.second_detail
	if result.task=="pack_walk":
		result.pack_first=bool(result.get("pack_first",false));result.pack_second=bool(result.get("pack_second",false))
		result.joint_seconds=float(result.get("joint_seconds",0));result.player_ready=bool(result.get("player_ready",false));result.companion_ready=bool(result.get("companion_ready",false))
		result.target_pos=result.second_pos if result.pack_first else result.first_pos
		if region!=int(result.region) or not escort or pos.distance_to(result.target_pos)>=125:
			result.player_ready=false;result.companion_ready=false
		if result.accepted and not escort:result.hint="Aktiviere die Begleitung im Rudelmenü, dann setzt ihr den gemeinsamen Weg an diesem Duftziel fort."
	if result.task in ["quiet_watch","wildlife_cycle"]:
		result.watch_started=bool(result.get("watch_started",false));result.watch_animal=str(result.get("watch_animal",""))
	if result.task=="wildlife_cycle":
		result.cycle_first=bool(result.get("cycle_first",false));result.cycle_second=bool(result.get("cycle_second",false))
		result.first_activity=str(result.get("first_activity",""));result.current_activity=str(result.get("current_activity",""));result.activity_seconds=float(result.get("activity_seconds",0))
		if region!=int(result.region) or not result.watch_started:result.current_activity=""
	return result

func _encounter_current(encounter: Dictionary) -> int:
	if encounter.is_empty() or not encounter.get("baseline") is Dictionary:return 0
	var baseline: Dictionary=encounter.baseline
	var actions: Dictionary=baseline.get("actions",{})
	match str(encounter.task):
		"tracks":return maxi(0,_regional_count(found,int(encounter.region))-int(baseline.found))
		"sites":return maxi(0,_regional_count(sites,int(encounter.region))-int(baseline.sites))
		"journey":return maxi(0,int(distance_walked-float(baseline.walk)))
		"visit":return 1 if visited.has(int(encounter.target_region)) else 0
		"observe":
			var key := "observe:"+str(encounter.get("detail","Reh"))
			return maxi(0,int(action_counts.get(key,0))-int(actions.get(key,0)))
		"water_rest":return int(encounter.get("drank_after_start",false))+int(encounter.get("rested_after_drink",false))
		"family":return int(encounter.get("greeted_family",false))+int(encounter.get("family_howl",false))
		"care_route":return int(encounter.get("care_drink",false))+int(encounter.get("care_feed",false))+int(encounter.get("care_rest",false))
		"edge_pair":return int(encounter.get("pair_first",false))+int(encounter.get("pair_second",false))
		"quiet_watch":return int(float(encounter.get("watch_seconds",0))+0.0001)
		"site_mark":return int(encounter.get("site_checked",false))+int(encounter.get("site_marked",false))
		"pack_walk":return int(encounter.get("pack_first",false))+int(encounter.get("pack_second",false))
		"wildlife_cycle":return int(encounter.get("cycle_first",false))+int(encounter.get("cycle_second",false))
	return 0

func complete_encounter() -> bool:
	if active_encounter.is_empty():return false
	var status: Dictionary=encounter_status()
	if not status.done or completed_encounters.has(str(status.id)):return false
	completed_encounters.append(str(status.id))
	xp+=int(status.reward)
	var skill: String=str(status.skill)
	skills[skill]=mini(100,int(skills[skill])+3)
	if skill=="pack":bond=minf(100,bond+2)
	record("Wildnisbegegnung abgeschlossen · "+status.title+" · Du hast den Weg selbst erlebt.")
	encounter_serial+=1
	active_encounter={}
	return true

func abandon_encounter() -> void:
	if active_encounter.is_empty():return
	encounter_serial+=1
	active_encounter={}

func hour() -> float:
	return fposmod(7.5+elapsed/DAY_SECONDS*24,24)

func time_name() -> String:
	var h := hour()
	return "Morgengrauen" if h<8 and h>=5 else "Tag" if h<17 and h>=8 else "Abend" if h<21 and h>=17 else "Nacht"

func sunlight() -> float:
	return clampf(sin((hour()-6)/24*TAU)*0.5+0.5,0.12,1.0)

func age_weeks() -> int:
	return 16+int(elapsed/(DAY_SECONDS*7))

func growth() -> float:
	return clampf(0.72+elapsed/(DAY_SECONDS*180)*0.28,0.72,1.0)

func weather() -> String:
	if not weather_enabled:return "klar"
	var biome: String=WolfWorldData.REGIONS[region].biome
	if biome=="snow" or (season_name()=="Winter" and biome not in ["coast","marsh","village"] and int(elapsed/540)%4!=0):return "Schnee"
	if int(elapsed/540)%4==2:return "Regen"
	if biome=="marsh" or (hour()<8 and hour()>4):return "Nebel"
	return "klar"

func story_scenes() -> Array[Dictionary]:
	return [
		{"title":"1 · Vor der Höhle","text":"Die Luft riecht nach Harz und feuchter Erde. Hinter dir schiebt die Mutter ihre Nase in dein Nackenfell. Ein Geschwister drängt zwischen ihre Pfoten. Du lauscht: Wasser plätschert jenseits der Kiefern. Dein erster Weg beginnt nahe bei der Familie.","ready":true,"gate":"","choices":[["Den Boden beschnüffeln","nose","Deine Nase nimmt den vertrauten Höhlenduft auf."],["Bei der Mutter bleiben","pack","Ein sanfter Stupser gibt dir Sicherheit."]]},
		{"title":"2 · Das kühle Ufer","text":"Wasserperlen hängen an deiner Schnauze. Zwischen den Steinen liegt ein fremder Geruch. Deine Ohren drehen sich zum Rascheln im Gras. Der erwachsene Wolf hält Abstand und lässt dich selbst erkunden.","ready":drank,"gate":"Trinke zuerst vom Ufer eines Teichs oder Flusses.","choices":[["Am Ufer neue Düfte prüfen","nose","Du unterscheidest nasse Erde von frischen Trittsiegeln."],["Leise dem Rascheln lauschen","stealth","Du wartest, bis das Gras wieder ruhig wird."]]},
		{"title":"3 · Die Fährte","text":"Ein Trittsiegel, dann noch eines. Der Duft wird stärker, wo die Halme gebogen sind. Du hebst den Kopf. Ein Hase verharrt zwischen den Stämmen. Erst lauschen, dann einen vorsichtigen Schritt setzen.","ready":found.size()>=3,"gate":"Schnüffle und lies drei Fährten mit Aktion.","choices":[["Die Spur mit der Nase verfolgen","nose","Du merkst dir die Richtung und Frische der Spur."],["Windrichtung und Abstand prüfen","stealth","Du gehst langsam und bleibst unter den Kronen."]]},
		{"title":"4 · Vertraute Stimmen","text":"Dein Vater antwortet mit einem tiefen Ruf. Die Mutter streift an dir vorbei; deine Geschwister folgen ihrem Geruch. Jeder kleine Kontakt hält das Rudel zusammen. Du musst noch nicht allein weit hinaus.","ready":pack_contacts>0 and howled,"gate":"Begrüße einen Rudelwolf und heule an der Höhle.","choices":[["Dem Elternwolf folgen","pack","Du nimmst die sichere Spur deiner Familie auf."],["Mit dem Geschwister spielen","pack","Ein Spielbogen, eine kurze Verfolgung: ihr lernt eure Bewegungen kennen."]]},
		{"title":"5 · Die offene Wiese","text":"Der Wald wird lichter. Wind bewegt das hohe Gras. Dein Fell berührt die Halme, während du an einer geschützten Mulde stehen bleibst. Ein Reh hebt den Kopf. Auf offenem Boden trägt der Wind deinen Geruch weit.","ready":visited.has(3),"gate":"Folge dem nördlichen Weg von der Rudelhöhle zur Bergwiese.","choices":[["Unterhalb des Winds bleiben","stealth","Du nutzt den Rand der Wiese als Deckung."],["Die neue Landschaft beschnüffeln","nose","Gras, Erde und Wildgerüche werden Teil deiner Erinnerung."]]},
		{"title":"6 · Ein Reh im Wolfsblick","text":"Die Ohren des Rehs bewegen sich. Es sieht nicht nur nach vorn. Du hältst still, bis seine Aufmerksamkeit zurück zum Gras wandert. Nähe allein macht keine Jagd; Geduld und das Rudel gehören dazu.","ready":observations.has("Reh"),"gate":"Beobachte ein Reh mit Aktion aus der 3D-Sicht bei genügend Abstand.","choices":[["In der Deckung warten","stealth","Du erkennst, wann das Reh wieder aufmerksam wird."],["Zum Elternwolf zurückkehren","pack","Du suchst Sicherheit und Orientierung beim Rudel."]]},
		{"title":"7 · Gerüche der Heimat","text":"Ein alter Schlafplatz, eine geschützte Wurzel und ein stilles Ufer. Manche Orte riechen nach Ruhe, andere nach Tieren, die vor dir hier waren. Deine Welt wächst mit jedem Weg, den du selbst gehst.","ready":sites.size()>=3,"gate":"Entdecke drei Naturorte; die Gebietskarte hilft dir dabei.","choices":[["Die Düfte genau einprägen","nose","Du erkennst vertraute Orte später leichter wieder."],["Einen geschützten Platz wählen","stealth","Du lernst, wo du ungesehen ruhen kannst."]]},
		{"title":"8 · Unter dem Abendhimmel","text":"Das Licht zwischen den Kiefern wird warm. Ferne Rufe kommen aus dem Tal. Du hebst die Nase in den Wind. Die Nähe deiner Familie fühlt sich vertraut an, doch die Wildnis reicht weiter, als dein Blick sie erfassen kann.","ready":visited.size()>=8 and bond>=50,"gate":"Erkunde acht Gebiete und stärke deine Rudelbindung auf 50.","choices":[["Mit dem Rudel zum Rückweg ansetzen","pack","Eure Düfte führen euch in Richtung der Höhle."],["Eine letzte Spur lesen","nose","Du schaust und riechst, bevor du weitergehst."]]},
		{"title":"9 · Die ruhende Familie","text":"Die Mutter liegt nahe der Höhle. Dein Geschwister rollt sich in ihre Nähe. Dein Atem wird langsam, die Ohren entspannen sich. Heute hast du neue Gerüche gelernt. Dein Körper wächst in kleinen Schritten, während die Tage vergehen.","ready":rested and region==0,"gate":"Kehre zur Rudelhöhle zurück und ruhe in ihrer geschützten Nähe.","choices":[["Neben der Familie ruhen","pack","Vertraute Wärme und Gerüche begleiten deinen Schlaf."],["Vor dem Ruhen noch lauschen","stealth","Du nimmst die ruhigen Geräusche deiner Heimat wahr."]]},
		{"title":"10 · Eine eigene Entscheidung","text":"Du hast einen Weg nicht nur gesehen, sondern selbst erlebt. Eine frische Spur, ein stilles Ufer oder eine vertraute Antwort ist nun Teil deiner Erinnerung. Deine Nase und deine Ohren werden mit jedem kleinen Erlebnis sicherer.","ready":completed_encounters.size()>=1,"gate":"Nimm eine Wildnisbegegnung an und erfülle ihre tatsächliche Aufgabe.","choices":[["Den neuen Geruch einprägen","nose","Du merkst dir, was du auf deinem eigenen Weg gelernt hast."],["Die Nähe der Familie suchen","pack","Du teilst die vertraute Umgebung mit dem Rudel."]]},
		{"title":"11 · Der geschützte Platz","text":"Eine Mulde hält den Wind ab. Trockene Blätter tragen den schwachen Duft anderer Tiere. Du prüfst den Boden, bevor du dich niederlässt. Nicht jeder ruhige Ort ist sicher; die Richtung des Winds und ein freier Rückweg gehören dazu.","ready":sites.size()>=6 and int(action_counts.rest)>=2,"gate":"Entdecke sechs Naturorte und ruhe zweimal an geschützten Plätzen.","choices":[["Boden und Wind genau prüfen","stealth","Du wählst deine Deckung mit mehr Geduld."],["Die Gerüche der Mulde vergleichen","nose","Du unterscheidest alte Spuren von frischem Wildgeruch."]]},
		{"title":"12 · Neben der Mutter","text":"Der erwachsene Wolf geht mit ruhigen Schritten vor dir. Manchmal bleibt er stehen, hebt die Nase und wartet. Du musst nicht dicht auf seinen Fersen bleiben. Ein vertrauter Geruch und ein kurzer Blick reichen, um wieder Richtung zu finden.","ready":escort and pack_contacts>=2,"gate":"Begrüße die Familie zweimal und erkunde mit der Mutter als Begleitung.","choices":[["Mit Abstand ihrem Wechsel folgen","pack","Du lernst, wie das Rudel seine Wege zusammenhält."],["Ihre Pausen beobachten","stealth","Du hältst inne, bevor du einen offenen Abschnitt betrittst."]]},
		{"title":"13 · Drei Arten von Aufmerksamkeit","text":"Ein Reh hebt den Kopf, ein Hase hält sich dicht am Boden, und ein Fuchs lauscht mit gedrehten Ohren. Sie bemerken ihre Umgebung auf unterschiedliche Weise. Ruhige Pfoten und genügend Abstand lassen dir Zeit, ihr Verhalten zu erkennen.","ready":observations.has("Reh") and observations.has("Hase") and observations.has("Fuchs"),"gate":"Beobachte Reh, Hase und Fuchs aus genügend Abstand im Wolfsblick.","choices":[["Ihre Aufmerksamkeit vergleichen","stealth","Du erkennst kleine Zeichen, bevor ein Tier flieht."],["Die Düfte den Tieren zuordnen","nose","Bewegung und Geruch ergeben für dich ein deutlicheres Bild."]]},
		{"title":"14 · Jenseits vertrauter Kronen","text":"Die Nadeln werden von breiten Blättern abgelöst; später trägt der Wind feuchte Erde aus einem Tal. Deine Heimat besteht aus vielen kleinen Landschaften. Du hältst die sicheren Übergänge im Gedächtnis und prüfst neue Wege mit Geduld.","ready":visited.size()>=12 and biomes_visited().size()>=5,"gate":"Erkunde zwölf Gebiete und fünf unterschiedliche Landschaftsarten.","choices":[["Die Übergänge beschnüffeln","nose","Du erkennst, wo ein vertrauter Weg in eine andere Landschaft führt."],["Am Rand der Deckung bleiben","stealth","Du passt deinen Abstand an offenere Flächen an."]]},
		{"title":"15 · Ein Rückweg aus Gerüchen","text":"An einer alten Stelle trifft dein eigener Geruch auf den des Rudels. Duftmarken sind kein Schild; sie sind Teil der Verständigung zwischen Wölfen. Du prüfst die Umgebung und merkst dir den Weg zurück zu vertrauter Nähe.","ready":marked.size()>=6 and completed_encounters.size()>=3,"gate":"Setze Duftmarken in sechs Gebieten und erfülle drei Wildnisbegegnungen.","choices":[["Vertraute Rudelgerüche prüfen","pack","Du erkennst die Verbindung zwischen Nähe und gemeinsam genutzten Wegen."],["Die Richtung des Rückwegs einprägen","nose","Du hältst Geruch und Landschaft zusammen in deiner Erinnerung."]]},
		{"title":"16 · Wasser, Schnee und stilles Gras","text":"Ein Bach trägt Gerüche fort. Schnee bewahrt scharfe Abdrücke, bis der Wind sie verwischt. Im langen Gras zeigt ein gebogener Halm nur kurz, dass jemand hier war. Jede Landschaft verändert, was deine Nase und deine Augen finden können.","ready":sites.size()>=24 and biome_count("river")>=2 and biome_count("snow")>=1,"gate":"Lerne 24 Naturorte, zwei Flussgebiete und ein Schneegebiet kennen.","choices":[["Fährten an den Boden anpassen","nose","Du beachtest, wie Wasser, Schnee und Gras den Geruch verändern."],["Die sichere Deckung jeder Landschaft suchen","stealth","Du prüfst zuerst den festen Boden und einen freien Rückweg."]]},
		{"title":"17 · Die weite Wildnis","text":"Ferne Höhen und neue Auen liegen hinter deinen ersten Wegen. Du bist noch ein junger Wolf. Erfahrung wächst in kleinen Begegnungen; der Körper folgt langsamer, Tag für Tag. Vertraute Gerüche tragen dich auch dort, wo der Wald anders klingt.","ready":visited.size()>=32 and int(skills.nose)>=60,"gate":"Erkunde 32 Gebiete und entwickle deine Nase auf 60.","choices":[["Einen neuen Wechsel ruhig prüfen","nose","Du gehst mit der Geduld deiner bisherigen Erfahrungen."],["Die Verbindung zum Rudel halten","pack","Trotz neuer Wege suchst du immer wieder vertraute Nähe."]]},
		{"title":"18 · Die Heimat bleibt lebendig","text":"Du kehrst an die Höhle zurück. Die Familie ruht, lauscht und prüft den Wind wie an deinem ersten Tag. Doch deine Erinnerung enthält jetzt viele eigene Wege. Morgen werden neue Gerüche kommen. Du wächst weiter, ohne dass die Zeit einen Sprung macht.","ready":region==0 and pack_contacts>=8 and rested and completed_encounters.size()>=8,"gate":"Erlebe acht Begegnungen, begrüße deine Familie achtmal und kehre zum Ruhen an die Rudelhöhle zurück.","choices":[["Nahe bei der Familie ruhen","pack","Vertraute Körperwärme und Gerüche begleiten deinen nächsten ruhigen Moment."],["Vor dem Ruhen dem Wald lauschen","stealth","Du hörst die Umgebung und lässt deine Pfoten still werden."]]}

	]

func choose_story(choice: int) -> bool:
	var scenes := story_scenes()
	if story_step>=scenes.size():return false
	var scene: Dictionary=scenes[story_step]
	if not scene.ready or choice<0 or choice>=scene.choices.size():return false
	var selected: Array=scene.choices[choice]
	skills[selected[1]]=mini(100,int(skills[selected[1]])+7)
	bond=minf(100,bond+2)
	story_choices.append(selected[0])
	record("Rudelgeschichte · "+scene.title+" · "+selected[2])
	story_step+=1
	return true

func record(message: String) -> void:
	journal.push_front(message)
	if journal.size()>300: journal.resize(300)

func save_to(path: String = "") -> bool:
	if path.is_empty():path=save_path
	# A killed Android process must not erase the previous valid save halfway
	# through an autosave. Commit only a fully flushed temporary JSON file.
	var pending_path := path+".pending"
	var file := FileAccess.open(pending_path,FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify({"version":4,"region":region,"pos":[pos.x,pos.y],"facing":[facing.x,facing.y],"hunger":hunger,"thirst":thirst,"energy":energy,"bond":bond,"elapsed":elapsed,"found":found,"visited":visited,"landmarks":landmarks,"observations":observations,"journal":journal,"drank":drank,"rested":rested,"howled":howled,"completed":completed,"food_cooldown":food_cooldown,"discoveries":discoveries,"pack_contacts":pack_contacts,"xp":xp,"distance_walked":distance_walked,"marked":marked,"sites":sites,"story_step":story_step,"story_choices":story_choices,"skills":skills,"escort":escort,"waypoint_region":waypoint_region,"waypoint_pos":[waypoint_pos.x,waypoint_pos.y],"tracked_quest":tracked_quest,"sound_enabled":sound_enabled,"reduced_motion":reduced_motion,"weather_enabled":weather_enabled,"map_reveal":map_reveal,"camera_follow":camera_follow,"smooth_edges":smooth_edges,"compact_hud":compact_hud,"action_counts":action_counts,"active_encounter":_save_encounter(),"completed_encounters":completed_encounters,"encounter_serial":encounter_serial,"routine_seen":routine_seen,"main_story":WolfMainStory.saved(main_story_progress),"nature_journeys":WolfNatureJourneys.saved(nature_journey_progress)}))
	file.flush()
	var write_ok := file.get_error()==OK
	file.close()
	if not write_ok:
		DirAccess.remove_absolute(pending_path)
		return false
	if DirAccess.rename_absolute(pending_path,path)!=OK:
		DirAccess.remove_absolute(pending_path)
		return false
	return true

func load_from(path: String = "") -> bool:
	if path.is_empty():path=save_path
	if not FileAccess.file_exists(path):return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:return false
	var version := int(_safe_number(data.get("version"),0))
	if version not in [1,2,3,4]:return false
	if not _valid_point_array(data.get("pos")):return false
	region=clampi(int(_safe_number(data.get("region"),0)),0,WolfWorldData.REGIONS.size()-1)
	pos=Vector2(clampf(float(data.pos[0]),20,3180),clampf(float(data.pos[1]),20,3180))
	facing=Vector2.UP
	var f = data.get("facing",[0,-1])
	if _valid_point_array(f):
		var direction := Vector2(float(f[0]),float(f[1]))
		if direction.length_squared()>0.001:facing=direction.normalized()
	for key in ["hunger","thirst","energy","bond"]:set(key,clampf(_safe_number(data.get(key),80),0,100))
	elapsed=maxf(0,_safe_number(data.get("elapsed"),0))
	food_cooldown=maxf(0,_safe_number(data.get("food_cooldown"),0))
	for key in ["found","observations","journal","completed","sites","story_choices","completed_encounters","routine_seen"]:
		var arr: Array[String]=[]
		if data.get(key) is Array:
			for value in data[key]:
				if not value is String or not _valid_saved_string(key,value):continue
				if key in ["journal","story_choices"] or not arr.has(value):arr.append(value)
		if key=="journal" and arr.size()>300:arr.resize(300)
		if key=="story_choices" and arr.size()>story_scenes().size():arr.resize(story_scenes().size())
		set(key,arr)
	for key in ["visited","landmarks","discoveries","marked"]:
		var arr: Array[int]=[]
		if data.get(key) is Array:
			for value in data[key]:
				var index := int(_safe_number(value,-1))
				if index>=0 and index<WolfWorldData.REGIONS.size() and not arr.has(index):arr.append(index)
		set(key,arr)
	if version==1:pos=(pos*2.0).clamp(Vector2(20,20),Vector2(3180,3180))
	xp=maxi(0,int(_safe_number(data.get("xp"),completed.size()*25)))
	pack_contacts=maxi(0,int(_safe_number(data.get("pack_contacts"),0)))
	distance_walked=maxf(0,_safe_number(data.get("distance_walked"),0))
	if not visited.has(region):visited.append(region)
	story_step=clampi(int(_safe_number(data.get("story_step"),0)),0,story_scenes().size())
	var saved_skills: Dictionary=data.get("skills") if data.get("skills") is Dictionary else {}
	for skill in skills:skills[skill]=clampi(int(_safe_number(saved_skills.get(skill),0)),0,100)
	escort=bool(data.get("escort",false))
	waypoint_region=clampi(int(_safe_number(data.get("waypoint_region"),-1)),-1,WolfWorldData.REGIONS.size()-1)
	waypoint_pos=Vector2.ZERO
	var waypoint=data.get("waypoint_pos",[0,0])
	if _valid_point_array(waypoint):waypoint_pos=Vector2(float(waypoint[0]),float(waypoint[1])).clamp(Vector2.ZERO,WolfWorldData.SIZE)
	else:waypoint_region=-1
	tracked_quest=str(data.get("tracked_quest",""))
	for preference in ["sound_enabled","reduced_motion","weather_enabled"]:set(preference,bool(data.get(preference,true if preference!="reduced_motion" else false)))
	map_reveal=bool(data.get("map_reveal",false))
	camera_follow=data.camera_follow if data.get("camera_follow") is bool else false
	smooth_edges=data.smooth_edges if data.get("smooth_edges") is bool else true
	compact_hud=data.compact_hud if data.get("compact_hud") is bool else true
	drank=bool(data.get("drank",false))
	rested=bool(data.get("rested",false))
	howled=bool(data.get("howled",false))
	var saved_actions: Dictionary=data.get("action_counts") if data.get("action_counts") is Dictionary else {}
	for key in action_counts:action_counts[key]=clampi(int(_safe_number(saved_actions.get(key),0)),0,100000000)
	encounter_serial=maxi(completed_encounters.size(),int(_safe_number(data.get("encounter_serial"),completed_encounters.size())))
	for identifier in completed_encounters:encounter_serial=maxi(encounter_serial,int(identifier.split(":")[2])+1)
	active_encounter=_load_encounter(data.get("active_encounter",{}))
	if not active_encounter.is_empty():encounter_serial=maxi(encounter_serial,int(str(active_encounter.id).split(":")[2]))
	encounter_preview_key=""
	encounter_preview={}
	pack_signal={}
	main_story_progress=WolfMainStory.restored(data.get("main_story",{}))
	nature_journey_progress=WolfNatureJourneys.restored(data.get("nature_journeys",{}))
	return true


func _save_encounter() -> Dictionary:
	if active_encounter.is_empty():return {}
	var result := active_encounter.duplicate(true)
	if result.task=="wildlife_cycle":result.current_activity=""
	if result.task=="pack_walk":result.player_ready=false;result.companion_ready=false
	for field in ["target_pos","water_pos","food_pos","rest_pos","first_pos","second_pos"]:
		if result.get(field) is Vector2:
			var point: Vector2=result[field]
			result[field]=[point.x,point.y]
	return result

func _load_encounter(value: Variant) -> Dictionary:
	if not value is Dictionary or value.is_empty():return {}
	var required := ["id","title","text","task","hint","skill","goal","reward","region","target_region","target_pos","baseline"]
	for key in required:
		if not value.has(key):return {}
	for key in ["id","title","text","task","hint","skill"]:
		if not value[key] is String or value[key].length()>6000:return {}
	if not _valid_saved_string("completed_encounters",value.id):return {}
	var tasks := {"tracks":[3,"nose"],"sites":[2,"nose"],"journey":[1200,"nose"],"visit":[1,"nose"],"observe":[1,"stealth"],"water_rest":[2,"pack"],"family":[2,"pack"],"care_route":[3,"pack"],"edge_pair":[2,"stealth"],"quiet_watch":[12,"stealth"],"site_mark":[2,"nose"],"pack_walk":[2,"pack"],"wildlife_cycle":[2,"stealth"]}
	if not tasks.has(value.task):return {}
	var origin := int(_safe_number(value.region,-1))
	var target := int(_safe_number(value.target_region,-1))
	if origin<0 or origin>=WolfWorldData.REGIONS.size() or target<0 or target>=WolfWorldData.REGIONS.size():return {}
	if int(value.id.split(":")[1])!=origin:return {}
	if not _valid_point_array(value.target_pos) or not value.baseline is Dictionary:return {}
	for key in ["found","sites","walk","actions"]:
		if not value.baseline.has(key):return {}
	if not value.baseline.actions is Dictionary:return {}
	if value.task=="visit" and not WolfWorldData.REGIONS[origin].links.values().has(target):return {}
	if value.task in ["observe","edge_pair","quiet_watch","wildlife_cycle"] and value.get("detail","") not in ["Reh","Hase","Fuchs"]:return {}
	if value.task=="edge_pair" and (value.get("second_detail","") not in ["Reh","Hase","Fuchs"] or value.second_detail==value.detail):return {}
	if value.task=="care_route":
		for field in ["water_pos","food_pos","rest_pos"]:
			if not _valid_point_array(value.get(field)):return {}
	if value.task=="pack_walk":
		for field in ["first_pos","second_pos"]:
			if not _valid_point_array(value.get(field)):return {}
	if value.task=="site_mark" and (not value.get("site_id") is String or not _valid_saved_string("sites",value.site_id) or not value.site_id.begins_with(str(origin)+":")):return {}
	var result: Dictionary=value.duplicate(true)
	result.region=origin
	result.target_region=0 if value.task=="family" else target if value.task=="visit" else origin
	result.target_pos=Vector2(float(value.target_pos[0]),float(value.target_pos[1])).clamp(Vector2(20,20),Vector2(3180,3180))
	if value.task in ["care_route","site_mark","pack_walk"]:
		# Rebuild canonical real places rather than trusting a stale or edited
		# coordinate to make the saved experience impossible.
		result=_prepare_local_encounter(result)
	result.goal=int(tasks[value.task][0])
	result.skill=str(tasks[value.task][1])
	result.reward=18
	var baseline: Dictionary=result.baseline
	baseline.found=clampi(int(_safe_number(baseline.found,0)),0,_regional_count(found,origin))
	baseline.sites=clampi(int(_safe_number(baseline.sites,0)),0,_regional_count(sites,origin))
	baseline.walk=clampf(_safe_number(baseline.walk,0),0,distance_walked)
	if value.task=="tracks" and int(baseline.found)>24:return {}
	if value.task=="sites" and int(baseline.sites)>WolfWorldData.SITES_PER_REGION-2:return {}
	var baseline_actions := {}
	for action in action_counts:baseline_actions[action]=clampi(int(_safe_number(baseline.actions.get(action),0)),0,int(action_counts[action]))
	baseline.actions=baseline_actions
	for flag in ["drank_after_start","rested_after_drink","greeted_family","family_howl","care_drink","care_feed","care_rest","pair_first","pair_second","site_checked","site_marked","watch_started","pack_first","pack_second","cycle_first","cycle_second"]:result[flag]=value.get(flag) if value.get(flag) is bool else false
	if not result.drank_after_start:result.rested_after_drink=false
	if not result.care_drink:result.care_feed=false
	if not result.care_feed:result.care_rest=false
	if not result.site_checked:result.site_marked=false
	result.watch_animal=str(value.get("watch_animal","")) if value.get("watch_animal") is String and value.watch_animal.length()<120 else ""
	if not _valid_watch_identity(result.watch_animal):result.watch_animal=""
	result.watch_seconds=clampf(_safe_number(value.get("watch_seconds"),0),0,12) if result.watch_started and not result.watch_animal.is_empty() else 0.0
	if result.watch_animal.is_empty():result.watch_started=false
	result.joint_seconds=clampf(_safe_number(value.get("joint_seconds"),0),0,3)
	result.player_ready=false;result.companion_ready=false
	if not result.pack_first:result.pack_second=false
	for field in ["first_activity","counted_activity"]:result[field]=str(value.get(field,"")) if value.get(field) is String and value[field] in ["forage","drink","shelter"] else ""
	result.current_activity=""
	if not result.watch_started or result.first_activity.is_empty():result.cycle_first=false
	if not result.cycle_first:result.cycle_second=false
	result.activity_seconds=clampf(_safe_number(value.get("activity_seconds"),0),0,3) if result.watch_started and not result.counted_activity.is_empty() else 0.0
	if completed_encounters.has(result.id):return {}
	return result

func _valid_watch_identity(identifier: String) -> bool:
	var parts := identifier.split(":")
	if parts.size()!=4 or parts[0] not in ["deer","rabbit","fox"]:return false
	for index in range(1,4):
		if not parts[index].is_valid_float() or not is_finite(float(parts[index])):return false
	return float(parts[1])>=20 and float(parts[1])<=3180 and float(parts[2])>=20 and float(parts[2])<=3180

func _safe_number(value: Variant,fallback: float) -> float:
	if value is int or value is float:
		var number := float(value)
		return number if is_finite(number) else fallback
	return fallback

func _valid_point_array(value: Variant) -> bool:
	if not value is Array or value.size()!=2:return false
	for component in value:
		if not (component is int or component is float) or not is_finite(float(component)):return false
	return true


func _valid_saved_string(key: String,value: String) -> bool:
	if key=="observations":return value in ["Reh","Hase","Fuchs"]
	if key in ["found","sites"]:
		var parts := value.split(":")
		if parts.size()!=2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():return false
		return int(parts[0])>=0 and int(parts[0])<WolfWorldData.REGIONS.size() and int(parts[1])>=0 and int(parts[1])<(27 if key=="found" else WolfWorldData.SITES_PER_REGION)
	if key=="completed_encounters":
		var parts := value.split(":")
		if parts.size()!=3:return false
		for part in parts:
			if not part.is_valid_int():return false
		return int(parts[0])>=1 and int(parts[1])>=0 and int(parts[1])<WolfWorldData.REGIONS.size() and int(parts[2])>=0
	if key=="routine_seen":return value in ["Morgendliche Geruchsrunde","Erkunden und Bewegungen üben","Ruhe in der Deckung","Abendliche Wege","Nacht nahe der Höhle"]
	return value.length()<=6000
