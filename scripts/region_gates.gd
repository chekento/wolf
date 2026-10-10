class_name WolfRegionGates
extends RefCounted

# Nine coherent macro-areas on the 16x16 atlas. One crossing per border,
# rather than every square connecting to every adjacent square.
const ITEMS := {
	0:{"id":"eiszeichen","name":"Eiszeichen","title":"Frostspur","hint":"Eine genaue Geruchskette öffnet die Eiswildnis.","tracks":6,"walk":1400},
	1:{"id":"frostfeder","name":"Frostfeder","title":"Schneepass","hint":"Lies die Windspuren des nördlichen Passes.","tracks":4,"walk":850},
	2:{"id":"gipfelzeichen","name":"Gipfelzeichen","title":"Adlergrat","hint":"Felszeichen weisen den Weg an die höchsten Gipfel.","tracks":9,"walk":2200},
	3:{"id":"kuestenmuschel","name":"Küstenmuschel","title":"Wald und Brandung","hint":"Im Westen zählt eine scharfe Nase.","tracks":4,"walk":900},
	5:{"id":"dorfpass","name":"Dorfpass","title":"Hinter den Menschen","hint":"Nur wer unbemerkt das Dorf durchquert, findet den östlichen Durchlass.","tracks":0,"walk":0},
	6:{"id":"moorzeichen","name":"Moorzeichen","title":"Südwestmoor","hint":"Ein vertrauter Duft weist durch das Schilf.","tracks":7,"walk":1750},
	7:{"id":"auenstein","name":"Auenstein","title":"Südliche Auen","hint":"Die Wege führen über weite, ruhige Pfadkreuzungen.","tracks":5,"walk":1200},
	8:{"id":"sonnenmarke","name":"Sonnenmarke","title":"Sonnenhang","hint":"Die hohe Südkante verlangt sicheres Spurenlesen.","tracks":10,"walk":2700}
}
# Deterministic three-step scent-sequence trials. Each incorrect answer
# returns to the first question; preparation requires actual wilderness play.
const QUESTIONS := [
	{"q":"Welche Spur bleibt auf festem Schnee am längsten erkennbar?","answers":["Warme Pfoten","Ein tiefer Trittabdruck","Ein Schatten"],"correct":1},
	{"q":"Du riechst Fuchs am Bach. Was verrät die Richtung?","answers":["Nur die Farbe des Fells","Das fernste Geräusch","Frische und Windrichtung"],"correct":2},
	{"q":"Was hilft bei einer steilen Felskante?","answers":["Dem sicheren Wildwechsel folgen","Schneller blind springen","Dem offenen Abgrund folgen"],"correct":0},
	{"q":"Auf weichem Moorboden suchst du...","answers":["Die tiefste Wasserstelle","Tragfähige Grasinseln","Blankes Wasser"],"correct":1},
	{"q":"Ein fremdes Tier schaut herüber. Du solltest...","answers":["Laut rufen","Direkt lossprinten","Langsam und in Deckung bleiben"],"correct":2},
	{"q":"Vor einem Pass prüfst du zuerst...","answers":["Wind und Boden","Deine Schwanzspitze","Die Wolkenfarbe allein"],"correct":0}
]

static func zone_at(coord: Vector2i) -> int:
	var col := 0 if coord.x<5 else 1 if coord.x<11 else 2
	var row := 0 if coord.y<5 else 1 if coord.y<11 else 2
	return row*3+col

static func zone(region: int) -> int:
	return zone_at(WolfWorldData.REGIONS[region].coord)

static func border_open(a: Vector2i,b: Vector2i) -> bool:
	if abs(a.x-b.x)+abs(a.y-b.y)!=1:return false
	# A narrow village passage is the sole route to the eastern province.
	for cell in [a,b]:
		if cell in [Vector2i(8,9),Vector2i(9,9),Vector2i(10,9)]:
			if a.y!=b.y:return false
	# Remove north and south village bypasses into the backcountry.
	if zone_at(a)==zone_at(b):return true
	if a.y==b.y:
		# Horizontal inter-zone portals. The central-to-east one starts
		# behind the village at (10,9).
		if maxi(a.x,b.x)==11:return a.y==9 if a.y>=5 and a.y<=10 else a.y in [2,13]
		return a.y in [2,8,13]
	return a.x in [2,7,13]

static func requires(region: int) -> String:
	var sector := zone(region)
	return "" if sector==4 else str(ITEMS[sector].id)

static func accessible(items: Array[String],region: int,visited: Array[int]=[]) -> bool:
	if region<0 or region>=WolfWorldData.REGIONS.size():return false
	return visited.has(region) or requires(region).is_empty() or items.has(requires(region))

static func trial_ready(entry: Dictionary,found_count: int,distance: float) -> bool:
	return found_count>=int(entry.tracks) and distance>=float(entry.walk)

static func question(sector: int,stage: int) -> Dictionary:
	return QUESTIONS[posmod(sector*2+stage*3,QUESTIONS.size())]

static func pass_name(region: int) -> String:
	var z := zone(region)
	return str(ITEMS[z].name) if ITEMS.has(z) else ""
