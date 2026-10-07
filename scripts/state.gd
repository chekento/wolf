class_name WolfState
extends RefCounted

const DAY_SECONDS := 3600.0
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
var pawsteps: Array[Dictionary] = []


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
		{"id":"river","name":"Das Lied des Wassers","hint":"Erkunde Flussauen und Wasserfalltal.","done":biome_count("river")>=2,"progress":"%d/2"%biome_count("river")},
		{"id":"fox","name":"Roter Schatten","hint":"Beobachte einen Fuchs aus dem Wolfsblick.","done":observations.has("Fuchs"),"progress":"1/1" if observations.has("Fuchs") else "0/1"},
		{"id":"ruins","name":"Steine voller Geschichten","hint":"Finde die Moosruinen westlich des Startgebiets.","done":visited.has(10),"progress":"1/1" if visited.has(10) else "0/1"},
		{"id":"coast","name":"Ein neuer Horizont","hint":"Erkunde die Dünenküste im Südwesten.","done":visited.has(12),"progress":"1/1" if visited.has(12) else "0/1"},
		{"id":"secret8","name":"Verborgene Heimat","hint":"Entdecke acht besondere Lichtungen oder Naturorte.","done":discoveries.size()>=8,"progress":"%d/8"%mini(discoveries.size(),8)},
		{"id":"mark","name":"Mein Weg durch die Wildnis","hint":"Markiere deinen Duft in sechs verschiedenen Gebieten.","done":marked.size()>=6,"progress":"%d/6"%mini(marked.size(),6)},
		{"id":"trail40","name":"Fährtenkundige Pfoten","hint":"Lies vierzig unterschiedliche Spuren.","done":found.size()>=40,"progress":"%d/40"%mini(found.size(),40)},
		{"id":"explore16","name":"Die große Wildnis","hint":"Erkunde sechzehn verbundene Gebiete.","done":visited.size()>=16,"progress":"%d/16"%mini(visited.size(),16)},
		{"id":"stones16","name":"Das Gedächtnis der Landschaft","hint":"Präge dir in jedem Gebiet einen Wegstein ein.","done":landmarks.size()>=16,"progress":"%d/16"%mini(landmarks.size(),16)}
	]

	result.append_array([
		{"id":"explore64","name":"Wildnis ohne Ende","hint":"Erkunde alle 64 Gebiete. Deine Übersicht merkt sich den Weg.","done":visited.size()>=64,"progress":"%d/64"%visited.size()},
		{"id":"sites24","name":"Eine Heimat aus Gerüchen","hint":"Lerne 24 verschiedene Naturorte kennen.","done":sites.size()>=24,"progress":"%d/24"%mini(sites.size(),24)},
		{"id":"story3","name":"Die Geschichte deiner Pfoten","hint":"Erlebe drei Kapitel im Menü Rudelgeschichte.","done":story_step>=3,"progress":"%d/3"%mini(story_step,3)},
		{"id":"escort","name":"Gemeinsam unterwegs","hint":"Begrüße die Familie; ab Bindung 48 kann ein Elternwolf dich begleiten.","done":escort,"progress":"1/1" if escort else "0/1"},
		{"id":"nose50","name":"Eine erfahrene Nase","hint":"Lies Fährten und erlebe Rudelgeschichten.","done":skills.nose>=50,"progress":"%d/50"%mini(skills.nose,50)},
		{"id":"days2","name":"Die Wildnis schläft nie","hint":"Lebe zwei Tage in der Wildnis. Menüs pausieren die Zeit.","done":elapsed>=DAY_SECONDS*2,"progress":"%d/2"%mini(int(elapsed/DAY_SECONDS),2)}
	])
	return result

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
	if biome=="snow":return "Schnee"
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
		{"title":"9 · Die ruhende Familie","text":"Die Mutter liegt nahe der Höhle. Dein Geschwister rollt sich in ihre Nähe. Dein Atem wird langsam, die Ohren entspannen sich. Heute hast du neue Gerüche gelernt. Dein Körper wächst in kleinen Schritten, während die Tage vergehen.","ready":rested and region==0,"gate":"Kehre zur Rudelhöhle zurück und ruhe in ihrer geschützten Nähe.","choices":[["Neben der Familie ruhen","pack","Vertraute Wärme und Gerüche begleiten deinen Schlaf."],["Vor dem Ruhen noch lauschen","stealth","Du nimmst die ruhigen Geräusche deiner Heimat wahr."]]}
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
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify({"version":3,"region":region,"pos":[pos.x,pos.y],"facing":[facing.x,facing.y],"hunger":hunger,"thirst":thirst,"energy":energy,"bond":bond,"elapsed":elapsed,"found":found,"visited":visited,"landmarks":landmarks,"observations":observations,"journal":journal,"drank":drank,"rested":rested,"howled":howled,"completed":completed,"food_cooldown":food_cooldown,"discoveries":discoveries,"pack_contacts":pack_contacts,"xp":xp,"distance_walked":distance_walked,"marked":marked,"sites":sites,"story_step":story_step,"story_choices":story_choices,"skills":skills,"escort":escort,"waypoint_region":waypoint_region,"waypoint_pos":[waypoint_pos.x,waypoint_pos.y],"tracked_quest":tracked_quest,"sound_enabled":sound_enabled,"reduced_motion":reduced_motion,"weather_enabled":weather_enabled,"map_reveal":map_reveal}))
	return true

func load_from(path: String = "") -> bool:
	if path.is_empty():path=save_path
	if not FileAccess.file_exists(path):return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or int(data.get("version",0)) not in [1,2,3]:return false
	if not data.get("pos") is Array or data.pos.size()!=2:return false
	region=clampi(int(data.get("region",0)),0,WolfWorldData.REGIONS.size()-1)
	pos=Vector2(clampf(float(data.pos[0]),20,3180),clampf(float(data.pos[1]),20,3180))
	var f = data.get("facing",[0,-1])
	if f is Array and f.size()==2:facing=Vector2(float(f[0]),float(f[1])).normalized()
	for key in ["hunger","thirst","energy","bond"]: set(key,clampf(float(data.get(key,80)),0,100))
	elapsed=maxf(0,float(data.get("elapsed",0)))
	food_cooldown=maxf(0,float(data.get("food_cooldown",0)))
	for key in ["found","observations","journal","completed","sites","story_choices"]:
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
	story_step=clampi(int(data.get("story_step",0)),0,story_scenes().size())
	if data.get("skills") is Dictionary:
		for skill in skills:skills[skill]=clampi(int(data.skills.get(skill,0)),0,100)
	escort=bool(data.get("escort",false))
	waypoint_region=clampi(int(data.get("waypoint_region",-1)),-1,WolfWorldData.REGIONS.size()-1)
	var waypoint=data.get("waypoint_pos",[0,0])
	if waypoint is Array and waypoint.size()==2:waypoint_pos=Vector2(float(waypoint[0]),float(waypoint[1])).clamp(Vector2.ZERO,WolfWorldData.SIZE)
	tracked_quest=str(data.get("tracked_quest",""))
	for preference in ["sound_enabled","reduced_motion","weather_enabled"]:set(preference,bool(data.get(preference,true if preference!="reduced_motion" else false)))
	map_reveal=bool(data.get("map_reveal",false))
	drank=bool(data.get("drank",false))
	rested=bool(data.get("rested",false))
	howled=bool(data.get("howled",false))
	return true
