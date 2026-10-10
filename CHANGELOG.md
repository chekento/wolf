# Changelog

## 0.13.0 · Freischaltbare Reviere, Menschen und Nahrungssuche

- Die 256 Gebiete bleiben mit stabilen IDs erhalten, gehören jedoch zu neun zusammenhängenden großen Landschaftssektoren. Provinzgrenzen haben jeweils nur einen gezielten Pass; das Menschendorf ist eine echte Ein-/Ausgangspassage.
- Sieben Items erhält man über wirklich gefundene Fährten und die gelaufene Strecke sowie drei aufeinanderfolgende mittelschwere Duftfragen. Ein Fehler setzt die Prüfung zurück. Der achte Pass wird durch unentdecktes Durchqueren des Dorfes verdient.
- Bewegte Menschengestalten in der 2D- und 3D-Landschaft, echte Blickrichtungen und 2D-Sichtkegel, Verdeckung durch Gebäude und Bäume, Sichtweiten-Vorteil beim Schleichen. Bei Entdeckung wird der Wolf an den westlichen Dorfeingang zurückgesetzt.
- Nahrung außerhalb des Tutorials ist verborgen, muss nahe einer Futterquelle erschnüffelt und anschließend per Aktion aufgenommen werden. Die bekannte erste Mahlzeit bei der Rudelhöhle bleibt erhalten.
- Zusätzliche Gletscherfurchen, Schneeverwehungen, alpine Felsterrassen und Dorfgebäude.
- Atlas kennzeichnet gesperrte Sektoren und das erforderliche Item. Ein neues Revierpass-Menü erläutert Voraussetzungen und startet die Duftprüfungen.
- Kompatible Spielstände im bestehenden Format 4: Bereits besuchte Orte bleiben begehbar, neue Gebiete benötigen ihre Items. Automatisierte Passage-, Save-, Stealth- und Nahrungsprüfungen.


## 0.12.2 · Lesbare Statuswerte, scrollbare Texte, aufklappbare Aktionen

- Begrüßungsbild und sämtliche Informationskarten geben vertikale Wischgesten an den Scrollcontainer weiter; Scrollen funktioniert jetzt auch direkt auf Textflächen und Hintergrundkarten.
- Kompakter Header zeigt jederzeit **Hunger, Durst, Kraft und Rudel** inklusive Zahlen und vier kleinen farbigen Fortschrittsbalken. Große Statusleisten und Minikarte bleiben aufklappbar.
- Vier sofortige Spielaktionen: Schnüffeln, kontextabhängige Aktion, Heulen und Ruhen. Geschichtemenü und Rudelmenü liegen nun in der unteren kleinen Navigationsleiste neben 2D/3D, Trab, Leise und Karte.
- Der Aktionsbereich startet platzsparend mit einer Viererreihe; über **Mehr Aktionen** wird daraus eine größere 2×2-Tastenansicht. Klappzustand ist unabhängig vom Statusmenü; Joystick und sekundäre Leiste bleiben sichtbar.
- Responsive Tests auf 540×960, 432×768 und 360×640, Scroll-Regression und Multitouch bleiben erhalten.
- Dieselben gespeicherten Gebiete, Storyfortschritte, Tierverhalten und Spielstände wie zuvor.


## 0.12.1 · Echtes Multitouch auf Android

- Zwei unabhängige Finger steuern gleichzeitig Bewegungs-Joystick und 3D-Kamera; weitere Finger können HUD-Aktionen und Sprint/Leise bedienen.
- Finger-ID-Zuordnung schützt vor übernommener Steuerung, mehrfach ausgelösten Aktionen, ungewollten Klicks nach Drag und verwaisten Gesten.
- Menüs behalten die reguläre Touch-Bedienung inklusive Scrollen; bei Rückkehr, Android-Hintergrundbetrieb und Ansichtswechsel werden aktive Gameplay-Berührungen sauber freigegeben.
- Automatisierte Multitouch-Regressionstests für simultane Eingaben und fehlertolerante Freigabe. Vorhandene Spielstände bleiben kompatibel.


## 0.12.0 · Schlanke Statusleiste und vollständige Spielaktionen

- Standardmäßig nur eine schmale Statusleiste mit Gebietsname, vier Kurzbedürfnissen, Aufklapp- und Menüknopf. Das Wolfsporträt, die große Minikarte, ausführliche Bedürfnisse, Begegnung und Aufgaben erscheinen erst beim Aufklappen.
- Auf kleinen Displays darf die obere Leiste ebenfalls aufgeklappt werden; das aktive Missionspanel macht dort vorübergehend Platz und kehrt beim Einklappen zurück. Kamera-Gesten beginnen stets direkt unter dem aktuellen Header.
- Zwei mal drei untere Aktionsknöpfe: Schnüffeln, dynamische Kontextaktion, Heulen, Ruhen, Rudel und Geschichte. Direkte Rudel- und Erholungsaktionen erfordern keinen Umweg über das Hauptmenü.
- Responsive kürzere Beschriftungen (Nase/Story/2D/3D) bei engen Bildschirmbreiten, kleinere Button-Innenabstände und dynamischer Touch-Stick-Radius statt eines auf kleinen Geräten abgeschnittenen 140-Pixel-Joysticks.
- Zusätzliche Layoutregressionen für 540×960, 432×768 und 360×640, ein-/ausgeklappten Status, getrennte Missionshinweise, 10 Bedienelemente und direkte Aktionsaufrufe.
- Die 0.11-Spielwelt, Missionen, Spielstände und Tier-Körperbewegungen bleiben erhalten. GitHub Actions signiert Debug-Builds weiterhin mit einem temporären Schlüssel: einen bisherigen lokal signierten Spielstand vor einer anderen Installation sichern.


## 0.11.0 · Gemeinsames Rudelspiel (Testbuild)

- Neue optionale Spielaufforderung im Familienmenü, wenn ein echter Rudelwolf in Reichweite steht.
- Geschwister und Eltern in der Nähe gehen eigenständig zu freien Plätzen um den Jungwolf und zeigen eine bestehende körperliche Spielpose; weder Spieler noch Tiere werden an einen Zielpunkt versetzt.
- Zeitlich begrenzte Aufforderungen, ehrliche Tierbewegung und Abbruch, wenn der Jungwolf wegläuft. Gemeinsamer Missionshalt und aktive Begleitung haben Vorrang.
- Zwei zusätzliche gespeicherte Spielerlebnisse für drei und zwölf echte Spielaufforderungen; freundliche Rudelbindung als kleine Belohnung.\n- Controllerprüfungen für tatsächliches Annähern, körperfreie Plätze, Wiederholungsschutz, Abbruch und Missionspriorität.
- Hauptgeschichte, regionale Naturreisen, alte Spielstände, Offline-Betrieb und Alterung bleiben unverändert.
- **Hinweis:** GitHub-Actions-Debugbuilds werden mit eigenem temporärem Signierschlüssel gebaut und sind deshalb nicht direkt als Update der lokal signierten 0.10.0 installierbar. Bis eine signaturkompatible 0.11-APK verfügbar ist, die bestehende Installation für den Spielstand behalten.

## 0.10.0 · Aktionsanker, Höhlenmission und Rudelnähe

- Wolfaktionsgrafiken werden um denselben Bodenanker gespiegelt; keine Verschiebung um eine ganze Atlasbreite.
- Der erste Heimatstopp zählt tatsächliche ruhige Nähe zur Mutter vor dem erreichbaren Höhleneingang. Eine versteckte Escort-Option blockiert diesen lokalen Schritt nicht mehr. Spätere gemeinsame Reisen benötigen weiterhin Begleitung.
- Kleiner einklappbarer Missionshinweis mit getrennten Toasts und erreichbaren vollständigen Details; keine überlappenden HUD-Texte.
- Begrenzte friedliche Rudelinteraktionen und Körperabstand bei tatsächlichen Navigationsschritten; keine Teleportierung von Tieren.
- Rudelwölfe gehen bei körperlich blockierter Bewegung kurz zur Seite. Gehaltener Stick zählt nicht als ruhige Missionszeit; neue Gebietsankünfte lassen beide Körper frei.
- Bestehende Spielstände, bereits verdiente Missionsschritte, Offline-Spiel und allmähliches Altern bleiben erhalten.

## 0.9.0 — 2026-10-08

- Sechs Arten eigener Naturreisen in jedem Gebiet, insgesamt 1536 regionale Angebote: Naturort und Duft, Trinkufer, konkrete Hasenfährte, ruhige Rehbeobachtung, zwei stille Naturorte und tatsächliche Rast am Schutzplatz.
- Eine bewusst angenommene Reise mit frischen geordneten Handlungen, eigenem gespeicherten Fortschritt und einmaliger Abschlussbelohnung; Hauptgeschichte und bisherige Begegnungen bleiben unabhängig erhalten.
- Eigener Naturreisenbereich, sichtbare Annahme-/Fortsetzung-/Abschlussknöpfe, echte Beobachtungs-/Rastzeiten und regionale illustrierte Menüs.
- Feinere originale Tierköpfe, Schnauzen, Ohren und Geweihformen sowie artspezifische Ruhe-, Gras- und Trinkhaltungen bei erhaltenem Pfotenkontakt.
- Kleine biomeigene Laub-, Pilz-, Totholz-, Kräuter-, Kiesel- und Moosgruppen bereichern den Boden; alte Weltobjekte und begehbare Flächen bleiben erhalten.

## 0.8.0 — 2026-10-08

- Neue Hauptgeschichte „Die Düfte der Heimat“ mit acht Kapiteln und 21 tatsächlichen Handlungsschritten: Mutter begrüßen, gemeinsame Ankunft, Trinkufer, konkrete Fährten, Naturorte und Duftmarken, ruhige Rehbeobachtung und Heimkehr mit gemeinsamer Rast.
- Eigener gespeicherter Reisefortschritt mit einmaligen Kapitelbelohnungen; die bisherigen 18 Rudelerinnerungen und Save-Version4 bleiben erhalten.
- Schmale organische Wildwechsel mit verbundenen Gabelungen und acht Bodenstilen. Keine sichtbaren Wege vor der Heimathöhle; alte Weltobjekte und Koordinaten bleiben erhalten.
- Weichere Gangartwechsel, stabile Stützpfoten, abgeschlossene Landung beim Anhalten und sanftere Kopf-, Ohren- und Schwanzbewegungen.
- Hauptgeschichtenmenü mit sichtbaren Handlungstasten, tatsächlichen Fortschrittsanzeigen und Duftzielführung; wichtige Missionshandlungen bleiben neben der begleitenden Mutter erreichbar.

## 0.7.0 — 2026-10-08

- Artspezifische Zielankünfte und Verweildauer, lockere Rehgruppen und auslaufender Gruppenalarm, Geschwisterspiel und Ruhephasen.
- Zwei zusätzliche Begegnungen für echte gemeinsame Ankunft und unterschiedliche Tätigkeiten desselben Tiers.
- Erhaltene Atlasansicht, Live-Anzeigen und reichere originale Landschafts- und Felldetails.
- Zwölf bestandene Suiten mit 2750 Prüfungen und signierter Android-Build.

## 0.6.0 — 2026-10-08

- Wirkliche artspezifische Deckungs-, Futter- und Trinkziele in allen 256 Gebieten; Aufmerksamkeit und Flucht reagieren auf Abstand, Sicht, Bewegung und Rudelruf. Tiere kehren über begehbare Wege in die Deckung zurück und beruhigen sich vor ihrer nächsten Routine.
- Vier zusätzliche Begegnungsarten mit echten, gespeicherten Handlungsschritten: Versorgung in Reihenfolge, zwei Tierarten, zwölf aktive Sekunden ruhige Beobachtung und Naturort mit eigener Duftmarke.
- Sichere lokale Kartenwege um Hindernisse und über Brücken, passende Kompassrichtung und Pfotenschritte. Neue Kartenebenen für Naturorte, bekannte Spuren und Wege; Gebietsausgänge und anklickbare Naturortliste.
- Am Fingerpunkt verankertes Aufziehen, nahtloses Weiterziehen nach Loslassen eines Fingers und konsistente Gebiets-/Suchauswahl.
- Illustriertes Menü für Wasser, Nahrung, Schutz und Heimkehr; sichtbare Annahme-/Belohnungstasten bei Begegnungen und direkte Umschaltung zum Wolfsblick für Tieraufgaben.
- Die Naturortprüfung hat bei einer angenommenen Ortsaufgabe Vorrang vor einer zu weit entfernten Höhle. Duftmarken lassen sich am tatsächlichen Ort erneuern, ohne doppelte Ortsbelohnung.
- Zusätzliche Prüfungen für Kartenbedienung, ökologische Tierziele, echte Begegnungsaktionen und Save4-Validierung. Langsames Altern, alte Gebiets-IDs und offline Spiel bleiben erhalten.
- Android-Build mit demselben dauerhaft gesicherten lokalen Schlüssel wie 0.4.0 und 0.5.0.

## 0.5.0 — 2026-10-08

- Elternwölfe folgen tatsächlich begehbaren Wegen um Felsen und über bestehende Flussbrücken. Auch nahe, verdeckte Jungwölfe werden erreicht; keine Versetzung zum Aufholen.
- Die Familie kehrt vor dem Ruhen an den geschützten Nachtplatz zurück. Fuchs, Hase und Reh haben unterschiedliche Aktivitätsphasen.
- Kompakte, gespeicherte Kopfleiste mit weiter sichtbaren Bedürfnissen, Begegnungen und Kamera; aufklappbare Minikarte und ausführliche Werte.
- Sofort sichtbarer Einstiegsknopf und Wegführung zum echten Trinkufer. Angenommene Begegnungen führen nach Fährten-, Naturort-, Wasser- und Rudelfortschritt zum nächsten Schritt.
- Gleichzeitiges Bewegen und Umsehen mit zwei Fingern; keine doppelte Kamerabewegung durch synthetisierte Mausereignisse und keine festhängenden Berührungen nach Ansichtwechseln.
- Die nahe Wasseraktion hat Vorrang vor einer entfernten Tierbeobachtung. Geschützte Begegnungsruhe bleibt neben Familienmitgliedern erreichbar.
- Statische Bodenmalerei, Blumen und Gräser der Draufsicht werden räumlich zusammengefasst; 3D-Vegetation teilt Farbbatches mit individueller Instanzfarbe. Entfernte Baum- und Felsmodelle verwenden leichtere native Mesh-LOD.
- Natürlichere Boden- und Tierpalette, ruhigere Bodenflecken und biomeigene Naturortformen: Muscheln, Pilze, Schilf, Treibholz, Zapfen und Steinstapel.
- Naturklang startet erst draußen; Menüs und App-Hintergrund stoppen die Wiedergaben zuverlässig. Die Toneinstellung bleibt beim Zurückkehren wirksam.
- Fünfte Prüfsuite für tatsächliche Tierwege, Hindernisse, Brücken, Nachtkehr und alte Spielstände; reale Ton-/Menü-/Hintergrundwechsel und vollständige Audio-Freigabe sind zusätzlich geprüft.
- Android-Build mit demselben dauerhaft gesicherten lokalen Schlüssel wie 0.4.0.

## 0.4.0 — 2026-10-08

- 256 gegenseitig verbundene Gebiete im 16×16-Verbund; vierfache Fläche gegenüber 0.3.0. Alte IDs, Seeds und lokale Spielpositionen bleiben erhalten.
- 1536 Naturorte, zusätzliche Nahrung und Ruheplätze; tatsächlich erreichbare Trinkufer und freigeräumte Ressourcenzugänge.
- 18 natürliche Storykapitel, 40 Erlebnisse und wiederholbare Wildnisbegegnungen mit neuen Handlungen, Fortschritt, Wegführung und einmaliger Belohnung.
- Fünf Rudel-Tagesroutinen, vier allmählich wechselnde Jahreszeiten und langsames Körperwachstum.
- Detailliertere originale 3D-Tiermodelle mit Fell, beweglichen Gelenken, Blinzeln und weicheren Posen; optionaler eigener Wolf in hindernisgeprüfter Folgekamera.
- Mehr Gräser, Farne, Schilf, Blumen, liegendes Holz und Naturortmodelle; Himmel, saisonale Farben und mehrschichtige Wettereffekte.
- Illustrierte Menüs, detaillierter Wildnisatlas und lokale Karten, Gebietssuche, Kompass, Maßstab und anklickbare Naturorte.
- Begrenzter Weltcache und dauerhaft gespeicherte kompakte Tierpositionen; räumlicher Kollisionsindex und Bewegung mit sicheren Teilschritten.
- Atomare Spielstand-Ersetzung, Migration alter Save-Formate, Validierung beschädigter Aufgaben und echte Aktionszähler.
- Hintergrundpause, Android-Zurück-Navigation, erreichbare Story-Wasserziele und Ruhen neben Rudelmitgliedern.
- Vier Prüfskripte für Welt, Gameplay, Grafik und echte Menü-/Controllerabläufe; neue Spielaufnahmen und signierter Android-Build.
- Neuer dauerhaft gesicherter lokaler Debug-Schlüssel, da der frühere nicht mehr verfügbar war. Ein direktes Android-Update über die alte Signatur ist damit nicht möglich; siehe Installationshinweise.

## 0.3.0 — 2026-10-08

- 64 gegenseitig verbundene Gebiete im 8×8-Verbund; vierfache Fläche gegenüber 0.2.0 und 64-fache Fläche gegenüber 0.1.0. Bestehende Gebiets-IDs bleiben erhalten.
- 192 Naturorte, lesbare Reh-, Hasen- und Fuchsspuren und Fährten bis zu den Aufenthaltsorten der Tiere.
- Neun zusammenhängende Rudelgeschichten mit natürlichen Entscheidungen, Fähigkeiten und Voraussetzungen aus dem tatsächlichen Spiel.
- Elternwolf als Begleitung über Gebietsgrenzen, Ruhe-, Spiel-, Lauschen- und Fluchtverhalten.
- Eigene Comic-Laufsequenzen für Wolf, Reh, Hase und Fuchs; zusätzliche Wolfposen für Schnüffeln, Heulen, Ruhen und Spielen.
- Neu modellierte 3D-Tiere mit beweglichen Beinen, Knien, Kopf, Ohren und Schwanz; Lauf-, Ruhe- und Heulanimationen.
- Neue Baum- und Felsmeshes, Oberflächen, sanfte Hügel, durchgehende Pfade, Schatten, Licht nach Tageszeit und Wetter in beiden Ansichten.
- Langsames Alter und Körperwachstum; ein Spieltag entspricht 60 Minuten aktiver Spielzeit. Kein Zeitsprung durch Ruhen.
- Verschiebbarer und vergrößerbarer Wildnisatlas, Gebietsdetailkarte, Naturortnamen, Duftziele, Gebietsroute und Kompass.
- Neue Menüs, Karten für Erlebnisse und Tagebuch, Familienansicht, Tierwissen, Einstellungen und einklappbare Kopfleiste.
- Einstellbarer Naturklang, Wetter, Kartenübersicht, ruhige Animationen und Draufsichtzoom.
- Spielstandformat 3 übernimmt die Fortschritte aus 0.1.0 und 0.2.0; 3D-Welten werden in der Draufsicht erst bei Bedarf aufgebaut.
- Erweiterte Prüfungen für alle 64 Übergänge, Wasserzugänge, Begleitung, Story-Freigaben, langsames Altern, Animationen, Karteninput und Speichern.

## 0.2.0 — 2026-10-07

- 16 verbundene Gebiete im 4×4-Verbund, je 3200×3200 Einheiten; 16-fache Gesamtfläche.
- Neue Comic-Sprites für Landschaft und Tiere, vier Wolfansichten und Porträt.
- Schnee, Küste, Wasserfall, Ruinen, See und Dorfrand.
- Minikarte und vergrößerbare Gebietsübersicht.
- 20 Erlebnisse, Erfahrung und Ränge, Duftmarken und leises Gehen.
- Rudelbegrüßung und folgende erwachsene Wölfe bei ausreichender Bindung.
- Migration bestehender Spielstände; echte 3D-Sicht nutzt dieselben Weltdaten.
- Android-Version und automatischer Build auf 0.2.0 aktualisiert.

## 0.1.0 — 2026-10-07

- Neues Godot-4.5.1-Projekt für Android und Web.
- Vier gegenseitig verbundene Karten, frei in zwei Achsen begehbar.
- Umschaltbare echte 3D-Sicht an der aktuellen Wolfposition.
- Gemeinsame Daten für Landschaft, Tiere und Spuren.
- Fährtensuche, Tierbeobachtung, Nahrung, Wasser, Ruhen und Rudelruf.
- Sieben erste Erlebnisse und ein lokales Naturtagebuch.
- Hochkant-Touchsteuerung, scrollbare Menüs und lokale Spielstände.
- Gameplay-Smoke-Tests und reproduzierbare Exportkonfiguration.
