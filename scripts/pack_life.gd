class_name WolfPackLife
extends RefCounted

# Short, repeatable experiences grounded in the current landscape. A chosen
# encounter records its baseline in WolfState, so an old action cannot fulfil it.
static func encounter(region: int,day_index: int,serial: int) -> Dictionary:
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
