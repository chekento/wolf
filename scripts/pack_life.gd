class_name WolfPackLife
extends RefCounted

# Short, repeatable experiences grounded in the current landscape. A chosen
# encounter records its baseline in WolfState, so an old action cannot fulfil it.
static func encounter(region: int,day_index: int,serial: int,hour: float=7.5) -> Dictionary:
	var biome: String=WolfWorldData.REGIONS[region].biome
	var entries: Array[Dictionary]=[
		{"title":"Eine neue Fährte","text":"Am Weg liegen frische Trittsiegel. Du senkst die Nase; der Duft ist deutlicher als die älteren Gerüche unter den Blättern. Folge den einzelnen Spuren und prüfe, wohin sie führen.","task":"tracks","goal":3,"hint":"Lies drei bisher unbekannte Spuren in diesem Gebiet.","skill":"nose","target_pos":Vector2(1640,1810)},
		{"title":"Leise am Waldrand","text":"Zwischen den Halmen hebt ein Reh die Ohren. Du hältst inne. Der Wind trägt seinen Geruch zu dir, während es die Umgebung prüft. Mit Abstand kannst du beobachten, ohne es zu bedrängen.","task":"observe","detail":"Reh","goal":1,"hint":"Beobachte jetzt ein Reh aus dem Wolfsblick. Bleibe mindestens sieben Pfotenschritte entfernt.","skill":"stealth","target_pos":Vector2(1760,1490)},
		{"title":"Wasser und Wind","text":"Deine Nase findet feuchte Erde. Am festen Ufer ist das Wasser erreichbar, und in der Deckung dahinter liegt ein geschützter Ruheplatz. Erst den Wind prüfen, dann trinken und Kraft sammeln.","task":"water_rest","goal":2,"hint":"Trinke vom Ufer und ruhe danach an einem geschützten Ruheplatz.","skill":"pack","target_pos":Vector2(2520,2140)},
		{"title":"Ein sicherer Wechsel","text":"Ein schmaler Weg führt zwischen den Stämmen weiter. Er riecht nach mehreren Tieren, die ihn vor dir benutzt haben. Du gehst langsam und merkst dir die Richtung, damit der Rückweg vertraut bleibt.","task":"journey","goal":1200,"hint":"Gehe weitere 1.200 Weltschritte. Die Zeit läuft ohne Sprünge weiter.","skill":"nose","target_pos":Vector2(1600,1600)},
		{"title":"Zwei Orte, zwei Düfte","text":"Eine trockene Mulde und ein alter Stamm erzählen dir Unterschiedliches. Du prüfst den Boden, Deckung und den Wind. Ein Ort wird erst Teil deiner Heimat, wenn du ihn selbst kennengelernt hast.","task":"sites","goal":2,"hint":"Entdecke zwei weitere Naturorte in diesem Gebiet.","skill":"nose","target_pos":Vector2(640,2500)},
		{"title":"Die vertraute Antwort","text":"Du erinnerst dich an den Geruch deiner Familie. Zurück an der Höhle erkennst du die vertrauten Pfoten. Ein freundlicher Stupser und ein gemeinsamer Ruf halten das Rudel zusammen.","task":"family","goal":2,"hint":"Begrüße einen Rudelwolf und heule nahe der Rudelhöhle.","skill":"pack","target_region":0,"target_pos":Vector2(1490,2110)},
		{"title":"Hinter dem nächsten Weg","text":"Vom Rand des Gebiets kommt ein neuer Duft. Du lauschst und prüfst die offene Strecke. Ein neuer Abschnitt der Wildnis wartet dort, wo der Weg unter den nächsten Bäumen verschwindet.","task":"visit","goal":1,"hint":"Erreiche ein bisher unerforschtes benachbartes Gebiet.","skill":"nose","target_pos":Vector2(1600,1600)},
		{"title":"Ein roter Schatten","text":"Ein Fuchs hält kurz zwischen den Stämmen inne. Seine Ohren drehen sich, dann verschwindet er wieder in der Deckung. Bleibe ruhig und beobachte sein Verhalten aus genügend Abstand.","task":"observe","detail":"Fuchs","goal":1,"hint":"Beobachte jetzt einen Fuchs aus dem Wolfsblick; nähere dich leise.","skill":"stealth","target_pos":Vector2(1950,1170)},
		{"title":"Ein Hase lauscht","text":"Ein Hase sitzt geduckt im Gras. Selbst während er Nahrung sucht, lauscht er in mehrere Richtungen. Du hältst Abstand und lässt ihm die freie Flucht in seine Deckung.","task":"observe","detail":"Hase","goal":1,"hint":"Beobachte jetzt einen Hasen aus dem Wolfsblick und bleibe leise.","skill":"stealth","target_pos":Vector2(1760,1350)}
	]
	var waterside := biome in ["river","lake","marsh","coast"]
	var dusk := hour>=17 or hour<7
	entries.append_array([
		{"title":"Drei sichere Plätze","text":"Wasser, ein zurückgelassener Nahrungsrest und trockene Deckung liegen auf verschiedenen Wegen. Du lernst sie in Ruhe kennen und kehrst danach geschützt zur Ruhe zurück.","task":"care_route","goal":3,"hint":"Trinke am gezeigten Ufer, friss danach am gewählten Nahrungsplatz und ruhe anschließend am gezeigten Ruheplatz.","skill":"pack","target_pos":WolfWorldData.water_bank(region)},
		{"title":"Zwei Gäste am Ufer" if waterside else "Zwei Gäste am Waldsaum","text":"Verschiedene Tiere nutzen dieselbe Landschaft zu unterschiedlichen Zeiten. Du prüfst ihre Haltung aus genügend Abstand und lässt ihre Rückwege frei.","task":"edge_pair","detail":"Fuchs" if dusk else "Reh","second_detail":"Hase","goal":2,"hint":"Beobachte jetzt einen Fuchs und einen Hasen in diesem Gebiet." if dusk else "Beobachte jetzt ein Reh und einen Hasen in diesem Gebiet.","skill":"stealth","target_pos":Vector2(1760,1490)},
		{"title":"Geduld im Abendwind" if dusk else "Ein ruhiger Blick","text":"Ein Wildtier hebt die Ohren und wendet sich wieder seinen eigenen Wegen zu. Du bleibst mit Abstand stehen, statt ihm nachzulaufen, und beobachtest seine ruhigen Bewegungen.","task":"quiet_watch","detail":"Fuchs" if dusk else "Reh","goal":12,"hint":"Wähle Beobachten für einen ruhigen Fuchs. Halte ihn danach 12 aktive Sekunden mit Abstand im Wolfsblick; bleibe ruhig." if dusk else "Wähle Beobachten für ein ruhiges Reh. Halte es danach 12 aktive Sekunden mit Abstand im Wolfsblick; bleibe ruhig.","skill":"stealth","target_pos":Vector2(1760,1490)},
		{"title":"Ein vertrauter Rückweg","text":"Ein geschützter Naturort hat seinen eigenen Geruch. Du prüfst ihn erneut und hinterlässt dort deine Duftmarke. So wird aus einem einzelnen Besuch ein vertrauter Rückweg.","task":"site_mark","goal":2,"hint":"Prüfe den gezeigten Naturort mit Aktion und markiere danach dort deinen eigenen Duft.","skill":"nose","target_pos":Vector2(640,2500)},
		{"title":"Zwei Wege mit vertrauten Pfoten","text":"Ein Elternwolf begleitet dich zu zwei kleinen Orten im Revier. Ihr geht wirklich gemeinsam hin, haltet kurz inne und prüft die Gerüche. Der erwachsene Wolf lässt dir genug Raum für eigene Schritte.","task":"pack_walk","goal":2,"hint":"Gehe mit aktivierter Begleitung nacheinander zu den zwei Duftzielen. Halte an jedem Ort drei aktive Sekunden ruhig, bis auch der Elternwolf bei dir ist.","skill":"pack","target_pos":Vector2(640,2500)},
		{"title":"Ein Tier, verschiedene Wege","text":"Ein Wildtier frisst, prüft das Ufer oder zieht sich in die Deckung zurück. Du lässt es seine eigenen Wege gehen und beobachtest dasselbe Tier bei zwei verschiedenen ruhigen Tätigkeiten.","task":"wildlife_cycle","detail":"Fuchs" if dusk else "Reh","goal":2,"hint":"Beginne mit Beobachten. Halte dasselbe Tier bei zwei verschiedenen Tätigkeiten je drei aktive Sekunden ruhig im Blick: Nahrung, Trinken oder Ruhe in Deckung.","skill":"stealth","target_pos":Vector2(1760,1490)}
	])
	var thematic := {
		"snow":{"title":"Spuren unter Schneekiefern","text":"Der Wind hat feinen Schnee über ältere Fährten getragen. Die frischeren Abdrücke sind noch scharf. Du prüfst die Kanten mit Nase und Blick und bleibst auf festem Boden."},
		"alpine":{"title":"Der Weg am hohen Hang","text":"Zwischen den Felsen führen Trittsiegel zu einer geschützten Grasmulde. Du gehst langsam. Die offene Höhe verlangt mehr Aufmerksamkeit als der Wald."},
		"river":{"title":"Trittsiegel am Fluss","text":"Nasser Sand hält feine Spuren fest. Manche Gerüche enden am Wasser, andere ziehen am trockenen Ufer weiter. Du bleibst oberhalb der tieferen Strömung."},
		"lake":{"title":"Spuren am stillen Ufer","text":"Kleine Wellen berühren den Sand. Im weichen Ufer liegen unterschiedliche Trittsiegel. Du prüfst sie vom sicheren Land aus."},
		"coast":{"title":"Salz und fremde Fährten","text":"Der Meerwind überlagert viele Düfte. Im trockenen Sand bleiben dennoch frische Abdrücke erkennbar. Du folgst ihnen oberhalb der Wellen."},
		"marsh":{"title":"Ein Wechsel im Schilf","text":"Rascheln kommt aus mehreren Richtungen. Die feste Erde zwischen den Binsen zeigt einen sicheren Wechsel. Du prüfst die Spuren, bevor du einen weiteren Schritt setzt."},
		"meadow":{"title":"Fährten durch hohes Gras","text":"Gebogene Halme zeigen, wo ein Tier die Wiese durchquert hat. Im Wind verschwindet der Duft schnell. Du hältst die Nase dicht am Boden."},
		"ruins":{"title":"Düfte zwischen alten Steinen","text":"Ein schmaler Durchlass führt zwischen Moos und Wurzeln hindurch. Kleine Tiere nutzen dieselbe Deckung. Du prüfst den Boden und lauschst."},
		"oak":{"title":"Trittsiegel im Laub","text":"Unter dem raschelnden Laub liegt feuchte Erde. Ein frischer Duft unterscheidet sich vom alten Geruch der Eichen. Du suchst die einzelnen Abdrücke."},
		"pine":{"title":"Zwischen Harz und Wildgeruch","text":"Harz liegt kräftig in der Luft. Nah am Nadelboden findest du eine feinere, frische Fährte. Du folgst ihr mit ruhigen Schritten."},
		"village":{"title":"Spuren am sicheren Waldsaum","text":"Du bleibst unter den Bäumen. Ein Wildtierwechsel führt entlang der Hecke und zurück in den Wald. Ferne Menschengerüche prüfst du aus sicherer Entfernung."}
	}
	if thematic.has(biome):entries[0].merge(thematic[biome],true)
	# Rotate steadily after a finished encounter, with regional/day variation.
	var offset := posmod(region*5+day_index*3,entries.size())
	var selected: Dictionary=entries[posmod(offset+serial,entries.size())].duplicate(true)
	selected.id="%d:%d:%d"%[day_index,region,serial]
	selected.region=region
	selected.target_region=int(selected.get("target_region",region))
	selected.reward=18
	return selected

static func routine(hour: float,role: String) -> Dictionary:
	var young := role=="Geschwister"
	var offset := Vector2(90,75) if role=="Vater" else Vector2(-75,40) if young else Vector2.ZERO
	if hour>=5 and hour<8:
		return {"label":"Morgendliche Geruchsrunde","mood":"lauschen" if young else "wandern","target":Vector2(1450,1890)+offset,"speed":24.0,"hint":"Die erwachsenen Wölfe prüfen die Umgebung; die Jungen bleiben in der Nähe."}
	if hour>=8 and hour<12:
		return {"label":"Erkunden und Bewegungen üben","mood":"spielen" if young else "wandern","target":Vector2(1490,2200)+offset if young else Vector2(1700,2060)+offset,"speed":38.0 if young else 28.0,"hint":"Kurze Spiele helfen den jungen Wölfen, ihren Körper und die Grenzen des Rudels kennenzulernen."}
	if hour>=12 and hour<16:
		return {"label":"Ruhe in der Deckung","mood":"ruhen","target":Vector2(1480,2280)+offset,"speed":14.0,"hint":"In der warmen Tageszeit ruht die Familie an geschützten Plätzen."}
	if hour>=16 and hour<21:
		return {"label":"Abendliche Wege","mood":"lauschen" if young else "wandern","target":Vector2(1700,1950)+offset,"speed":28.0,"hint":"Die Ohren und Nasen des Rudels nehmen die kühlere Abendluft auf."}
	return {"label":"Nacht nahe der Höhle","mood":"ruhen","target":Vector2(1510,2340)+offset,"speed":12.0,"hint":"Das Rudel bleibt in geschützter Nähe; auch ruhende Wölfe reagieren auf ungewohnte Geräusche."}

static func wildlife_routine(kind: String,hour: float,cycle: int) -> Dictionary:
	# Foxes mainly investigate at dusk and night; hares favor morning and
	# evening. Deer alternate feeding and sheltered rest throughout the day.
	var active := true
	if kind=="fox":active=hour>=17 or hour<7
	elif kind=="rabbit":active=(hour>=5 and hour<10) or (hour>=16 and hour<23)
	var rest := not active or (kind=="deer" and cycle==0)
	return {"rest":rest,"pause":active and not rest and cycle==1,"mood":"schnüffeln" if kind=="fox" and cycle==1 else "grasen" if cycle==1 else "wandern","speed":24.0 if kind=="fox" else 20.0}

static func wildlife_profile(kind: String) -> Dictionary:
	# Distances are game world units. Species differ in early attention and
	# escape distance, rather than all reacting to one identical radius.
	match kind:
		"rabbit":return {"notice":285.0,"quiet_flee":78.0,"loud_flee":175.0,"escape_speed":145.0,"recover":5.0}
		"fox":return {"notice":330.0,"quiet_flee":65.0,"loud_flee":135.0,"escape_speed":112.0,"recover":4.0}
	return {"notice":390.0,"quiet_flee":88.0,"loud_flee":195.0,"escape_speed":128.0,"recover":6.0}

static func wildlife_activity(animal: Dictionary,hour: float,dt: float) -> Dictionary:
	var ecology: Dictionary=animal._ecology
	var kind: String=animal.kind
	var phase: float=animal.get("phase",0)
	var sleeping: bool=(kind=="fox" and hour>=7 and hour<17) or (kind=="rabbit" and not ((hour>=5 and hour<10) or (hour>=16 and hour<23)))
	if sleeping:
		animal._activity_sleeping=true
		animal._activity_waited=0.0
		return _activity_pose(animal,ecology.shelter,"shelter",true)
	if animal.get("_activity_sleeping",false):
		animal._activity_step=0
		animal._activity_waited=0.0
		animal._activity_sleeping=false
	var stage := int(animal.get("_activity_step",posmod(floori(phase),4)))
	var target: Vector2=ecology.get("group_forage",ecology.forage) if stage==0 else ecology.shelter if stage==1 else ecology.other_forage if stage==2 else ecology.water if ecology.has_water else ecology.shelter
	var behavior := "shelter" if stage==1 or (stage==3 and not ecology.has_water) else "drink" if stage==3 else "forage"
	var calmed: bool=float(animal.get("alarm",0))<=0 and animal.get("behavior","") in ["","forage","drink","shelter","social"]
	var waited := float(animal.get("_activity_waited",0))
	if calmed and animal.p.distance_to(target)<12:waited+=clampf(dt,0,0.1)
	var durations: Array=[18.0,12.0,14.0,8.0] if kind=="deer" else [10.0,14.0,12.0,7.0] if kind=="rabbit" else [14.0,10.0,16.0,8.0]
	if waited>=float(durations[stage])+fposmod(phase*2,4):
		animal._activity_step=(stage+1)%4
		animal._activity_waited=0.0
		return wildlife_activity(animal,hour,0)
	animal._activity_step=stage
	animal._activity_waited=waited
	return _activity_pose(animal,target,behavior,false)

static func _activity_pose(animal: Dictionary,target: Vector2,behavior: String,sleeping: bool) -> Dictionary:
	var arrived: bool=animal.p.distance_to(target)<12
	return {"target":target,"behavior":behavior,"speed":0.0 if arrived else 24.0 if animal.kind=="fox" else 28.0,"mood":"wandern" if not arrived else "trinken" if behavior=="drink" else "ruhen" if behavior=="shelter" else "schnüffeln" if animal.kind=="fox" else "grasen","sleeping":sleeping}

static func sibling_play(animal: Dictionary,partner: Dictionary,base: Vector2,now: float) -> Dictionary:
	if animal.p.distance_to(base)>175:return {"target":base,"speed":38.0,"mood":"wandern","behavior":"routine"}
	var turn := posmod(int(now/8),6)
	var first: bool=partner.is_empty() or float(animal.phase)<float(partner.phase)
	var running: bool=(first and turn in [1,4]) or (not first and turn in [2,5])
	var offset := Vector2(-72,-38) if first else Vector2(76,34)
	var target := base+offset if not running else base+Vector2(85,-60) if first else base+Vector2(-70,70)
	if turn in [1,2] and not running and not partner.is_empty() and animal.p.distance_to(partner.p)>85:target=partner.p+offset.normalized()*60
	return {"target":target,"speed":42.0 if running else 32.0,"mood":"spielen" if turn in [0,1,2,4,5] else "lauschen","behavior":"play" if turn!=3 else "routine"}

static func animal_key(animal: Dictionary) -> String:
	if animal.is_empty() or not animal.get("home") is Vector2:return ""
	var home: Vector2=animal.home
	return "%s:%.1f:%.1f:%.2f"%[animal.get("kind",""),home.x,home.y,float(animal.get("phase",0))]
