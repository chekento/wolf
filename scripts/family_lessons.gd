class_name WolfFamilyLessons
extends RefCounted

# Interactive guidance tied to measurable in-game actions, not dialogue taps.
const LESSONS := [
	{"id":"m_pack","parent":"Mutter","title":"Die Sprache des Rudels","text":"„Begrüße deine Familie ruhig und achte darauf, wie sie reagiert. Wir geben einander Raum und erkennen vertraute Stimmen und Gerüche.“","task":"Begrüße einen Rudelwolf mit Aktion und kuschle mit einem Familienmitglied.","skill":"pack"},
	{"id":"m_nose","parent":"Mutter","title":"Mit der Nase die Welt lesen","text":"„Senk die Schnauze. Erst schnupperst du in verschiedene Richtungen, dann unterscheidest du eine frische Spur von altem Duft. Eile hilft deiner Nase nicht.“","task":"Schnüffle zweimal und lies eine neue echte Fährte.","skill":"nose"},
	{"id":"m_play","parent":"Mutter","title":"Spielen ohne grob zu werden","text":"„Deine Geschwister zeigen dir einen Spielbogen. Warte auf ihre Antwort, weiche aus und gönne ihnen Pausen. Gemeinsam lernen wir Grenzen.“","task":"Spiele zweimal mit einem Geschwister, mit einer Pause dazwischen.","skill":"pack"},
	{"id":"f_path","parent":"Vater","title":"Orientierung und Heimweg","text":"„Achte auf den Wind, auf Wegkreuzungen und auf den Geruch unserer Höhle. Ein guter Weg führt dich auch sicher zurück.“","task":"Betritt ein neues Kartenfeld und setze dort eine Duftmarke.","skill":"nose"},
	{"id":"f_hunt","parent":"Vater","title":"Jagd beginnt mit Beobachtung","text":"„Wir jagen nicht blind los. Suche frische Wildfährten, halte Abstand, beobachte die Beute und prüfe immer deine Deckung.“","task":"Lies zwei bisher unbekannte Wildfährten.","skill":"stealth"},
	{"id":"f_mission","parent":"Vater","title":"Aufträge und Verantwortung","text":"„Ein Auftrag braucht Geduld: prüfe das Ziel, merke dir den Rückweg und beende die Arbeit wirklich, bevor du eine neue beginnst.“","task":"Schließe eine echte Wildnisbegegnung mit Belohnung ab.","skill":"pack"}
]
static func entry(id: String) -> Dictionary:
	for item in LESSONS:
		if item.id==id:return item
	return {}

static func available(parent: String,completed: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for item in LESSONS:
		if item.parent==parent and not completed.has(item.id):result.append(item)
	return result

static func progress(id: String,baseline: Dictionary,current: Dictionary) -> Dictionary:
	var step := 0
	var goal := 1
	var task := ""
	match id:
		"m_pack":
			goal=2
			step=mini(1,maxi(0,int(current.get("greet",0))-int(baseline.get("greet",0))))
			step+=mini(1,maxi(0,int(current.get("cuddle",0))-int(baseline.get("cuddle",0))))
			task="Rudel begrüßen und kuscheln"
		"m_nose":
			goal=3
			step=mini(2,maxi(0,int(current.get("sniff",0))-int(baseline.get("sniff",0))))
			step+=mini(1,maxi(0,int(current.get("found",0))-int(baseline.get("found",0))))
			task="Zweimal schnüffeln, eine frische Spur lesen"
		"m_play":
			goal=2
			step=mini(2,maxi(0,int(current.get("sibling_play",0))-int(baseline.get("sibling_play",0))))
			task="Zweimal mit Geschwistern spielen"
		"f_path":
			goal=2
			step=mini(1,maxi(0,int(current.get("visited",0))-int(baseline.get("visited",0))))
			step+=mini(1,maxi(0,int(current.get("mark",0))-int(baseline.get("mark",0))))
			task="Neues Kartenfeld und Duftmarke"
		"f_hunt":
			goal=2
			step=mini(2,maxi(0,int(current.get("found",0))-int(baseline.get("found",0))))
			task="Zwei frische Wildfährten lesen"
		"f_mission":
			goal=1
			step=mini(1,maxi(0,int(current.get("encounters",0))-int(baseline.get("encounters",0))))
			task="Eine Begegnung erfolgreich abschließen"
	return {"current":step,"goal":goal,"ready":step>=goal,"task":task}
