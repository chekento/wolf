# Entwicklungsübergabe · Wolf

Stand **0.10.0**, 8. Oktober 2026. Repository `chekento/wolf`. Geprüfte funktionierende Änderungen auf main und eine herunterladbare APK sind vom Nutzer autorisiert. Fünf bestehende Agenten wurden für Mission, unabhängige Controllerprüfung, Rudelbewegung, Aktionsdarstellung und mobile Oberfläche wiederverwendet. Root integrierte, prüfte, exportierte und signierte.

## Basis und Veröffentlichung

Frisch gelesener main **`55ec9e8732280e9b85c9085e0d410f1db1bea997`**, Baum `330a32c7d85f3eb751dcfc71ddd1f09a2f2295ec`. Isolierter Checkout `/workspace/scratch/f0379b84af57/wolf-next-10`, Branch `wolf-010-fixes`. Unveränderte 0.9-Vergleichsbasis unter `wolf-next-09`.

Immer aktuellen main und diese Übergabe zuerst lesen, dann isolierten Checkout erstellen. Funktionierende Änderungen atomar mit erwarteter main-SHA veröffentlichen; bei geändertem main erst Inhalte/Konflikte prüfen. Lokaler Git-Push ist hier nicht authentifiziert. GitHub-API-Blobs, Tree, Commit und UpdateRef mit erwarteter SHA/force=false verwenden. Der Remote-Tree muss dem getesteten lokalen Tree exakt entsprechen. Keine privaten Signierschlüssel oder Exportcredentials in git.

## Gemeldete Fehler und konkrete Korrekturen

Der Nutzer zeigte die erste Mission bei 1/2, eine große doppelte Aufgabenbox und überlappende Meldungen. Aktionen ließen 2D-Tiergrafiken rechts um einen ganzen Atlasrahmen springen. Die inline sichtbaren Screenshots waren ausreichend; fehlende lokale Anhangsdateien nicht erneut über gespeicherte Dateien lesen.

`map_view.gd`: Godot spiegelt negative Zielbreiten bereits am angegebenen Ursprung. Die alte zusätzliche X-Verschiebung versetzte rechtsgerichtete Aktionen um 124 px. Neue `action_sprite_transform`/`action_sprite_rect` spiegeln um den unveränderten Mittelpunkt mit positiven Rechtecken; die Kamera wird danach korrekt zurückgesetzt. Auch `_sprite` hat keine zusätzliche Ursprungverschiebung mehr. Tatsächliche Weltkoordinaten, Atlasdateien und 3D-Modelle unverändert.28 Headless-/36 zusätzliche tatsächlicheGL-Prüfungen für Zentren, Zoom, sechs Aktionen, vier Richtungen, Rückkehr,3D-Bodenanker und Pfotenkontakt.

`main_story.gd`/`state.gd`: NUR Kapitel 0/Stufe 1 ist ein lokales `home_meeting`, `requires_escort=false`. Guidepunkt `(1580,2320)` liegt am realen trockenen südlichen Höhleneingang. Zone 260 um echten Höhlenmittelpunkt `(1580,2180)`; reale erwachsene Mutter weniger als 150 vom Spieler/300 von der Höhle, speed<=1 und freie statische Verbindung; drei aktive ruhige Sekunden. Mutter geht selbst hin. Kein automatisches Escortflag, keine teleportierten Tiere, kein erfundener Fortschritt. Spätere joint/rest_wait-Aufgaben verlangen weiterhin Escort und alte 125/220-Grenzen. `main_story_home_meeting_active` gibt nur den akzeptierten aktuellen Heimatstopp in der echten Zone frei. Status liefert `home_meeting`, `requires_escort`, `player_in_zone`; kanonischer Mittelpunkt steht in `current_stage`, nicht im Status.

`main.gd::_quiet_player_speed`: gemessene Geschwindigkeit 0 bei gedrücktem körperlich blockiertem Stick ist keine Ruhe. Bei Mood `laufen` liefert der gemeinsame Helper mindestens 2 an Story-, Naturreisen- und Wildlife-Warteprüfungen. Aktive Tickzeit weiterhin maximal 0,1 s, Menüs/Hintergrund pausieren. Verdiente Sekunden und Schritte älterer Saves bleiben erhalten; Live-Nähe wird beim Laden/Pause geräumt.

`pack_interactions.gd` neuer begrenzter regionaler Planner: höchstens vier vorhandene Familienwölfe; kurze Begrüßungen, Blickkontakte, friedliche nahe Begegnungen und bestehendes Geschwisterspiel. Heimatstopp hat Vorrang, später Escort physischer Weg. Getrennte körperlich freie Näheziele, feste begrenzte Kandidaten und kurze Zielreservierungen. Nacht-/Tagesroutinen behalten ihre realen Ziele; explizite Notice-/Social-Zweige schauen zum Spieler. Ein im Volltest gefundenes globales falsches Blickziel wurde vor dem Schlusslauf entfernt, unveränderte Ecology-Suite jetzt grün.

`animal_motion.gd`: `advance_pack`, `body_step_free`, `player_step_free`, `body_radius` ergänzen tatsächliche Swept-Schritte um wenige Familien-/Spielerkörper und lokale begrenzte AStar-Umwege. Graphänderungen werden vor Rückkehr wiederhergestellt. Ältere schon überlappende Daten dürfen sich nur wirklich gelaufen monoton trennen. Player-Radius im Controller immer `40.0*state.growth()`; junge Familienwölfe 29/adulte 40 plus 3 Abstand. Bei gehaltenem Stick in Richtung eines nahen Wolfs fordert der Planner für höchstens 1,8 aktive Sekunden einen seitlichen freien Laufpunkt an. Keine direkte Positionskorrektur. `_sync_companion` wählt beim erstmaligen Eintritt ebenfalls körperfreies nahes Gelände statt den Spielerpunkt als Ersatz.

Planner-Context: region, hour, now, elapsed, escort, player_pos, player_facing, player_speed, player_mood, player_radius, signal, meeting, meeting_center, meeting_radius, howling. Die transienten Unterstrichfelder bleiben begrenzt an vier tatsächlichen regionalen Records. Weltgenerator, RNG und gespeicherte Weltkoordinaten werden nicht geändert.

## Mobile Missionsoberfläche

Standard-Missionspanel 86 px, einklappbar. Titel, kurzer Zustand und echte Sekunden bleiben sichtbar; längere Erklärung über **?** im scrollbaren Missionsmenü. Header zeigt kurze Schrittzahl statt doppeltem vollständigem Auftrag. Separate geclippte dreizeilige Meldungsfläche, keine Überschneidung mit Mission/Tasten. Modal blendet Panel+Toast aus; tatsächliche Rückkehr stellt den aktuellen Zustand wieder her. Passive Flächen ignorieren Pointer; nur Detail-/Faltknöpfe akzeptieren Taps. Responsive Tastenabstände, Schriftgrößen und Stickbreite auch 360×640; Kamerawischbereich folgt der Headerhöhe sofort. Der ausgeklappte Missionskasten nutzt seine tatsächliche Mindesthöhe, keine pauschal riesige Box.

70 echte Layout-/Bedienchecks für 540×960,432×768,360×640. Fünf neue tatsächlich gerenderte Bilder unter `docs/hud-mission-*`: folded, expanded, details, return, small. `tests/hud_capture.gd` schaltet die Kamera über echtes `toggle_view`; keine bloß gesetzten 3D-Flags. Standard 22 Spiel-/Menü-/Kartenbilder wurden ebenfalls neu gerendert. Dokumentationsbilder, Tests und Fixtures sind aus Android/Web ausgeschlossen. Bilinguales README bleibt erhalten.

## Erhaltener Spielumfang und Saves

256 zusammenhängende 3200×3200-Gebiete/1536 Naturorte. Generatorgesamtfingerabdruck weiterhin `681fd8f2d02213bd55029cfbfc777b3038bd535b1cd6459c049545340cc4f283`. Schmale organische Wege mit acht Stilen und wegfreiem südlichen Höhlenraum bleiben. Die Hauptgeschichte „Die Düfte der Heimat“ hat acht Kapitel/21 echte Handlungen;18 Rudelerinnerungen,40 Erlebnisse und alte Begegnungen erhalten.

Naturreisen aus 0.9 bleiben separate kanonische Missionsebene: sechs wiederkehrende Typen je Gebiet,1536 regionale Angebote/3328 geordnete Ziele; genau eine aktive Reise, frische echte Handlungen, einmalige 30 XP/2 Skill/1 Bindung-Belohnung. Dies sind regionale Angebote, keine 1536 separat geschriebenen Geschichten. `guided_main_story` bestimmt ausdrückliche Storypriorität; sonst bevorzugt eine aktive Naturreise Zieltext, Live-HUD, Kontextaktion und Rehidentität. Persönliche Wegpunkte bleiben erhalten.

Save-Version 4 und Migration 1–4 erhalten.60 Minuten aktives Spiel pro Tag,30 Tage pro Jahreszeit; ruhen überspringt keine Tage. Originale 0.9-Habitatdetails und vier gegliederte Tierarten unverändert; keine fremden Modellpakete. Frühere Details/Rohprofile stehen in [0.9-Prüfbericht](validation-0.9.0.md). Kein neuer 0.10-FPS-Vergleich behauptet.

## Tatsächliche Prüfungen

**27 Suiten / 3513 bestandene Prüfungen**, vollständiger zentraler Schlusslauf mit sauberem Editorimport, alle Headlesslogs ohne Script-/Enginefehler, Warnungen oder Leaks. Neue Suiten: action_anchors, main_story_first_mission, hud_layout, pack_interactions, first_mission_controller. CI führt alle 27 und beide Exporte plus Android-Signatur/Manifest/16 KiB-Ausrichtung aus. [Prüfbericht](validation-0.10.0.md), [Einzelwerte/APK](validation-0.10.0.json).

Der unveränderte 0.9-Controller reproduzierte das erste Missionsproblem mit echtem Hinlaufen und 15 s Warten. Unter 0.9 nach tatsächlicher Begrüßung gespeicherte Fixture: `tests/fixtures/first_mission_09.json` samt Wildlife-Cache. Der neue Controllerprüflauf setzt weder Positions- noch Storycheckpoints: frischer Spawn ohne Escort und echter 0.9-Spielstand mit realem Escortbutton, tatsächliches Hinlaufen zur bewegten Mutter/Guidepunkt, gemeinsames Anhalten, drei verdiente Sekunden, Kapitelbutton, einmalige 40 XP/3 Packskill, zwei Save/Restarts. Gehaltener zunächst blockierter Stick verdient keine Sekunden. Dies ist kein behaupteter vollständiger menschlicher Durchlauf aller acht Kapitel.

36 tatsächlicheGL-Aktionsankerchecks zusätzlich zu den 27 Headless-Suiten.18 kontrollierte Vorher- und 18 Nachher-Aufnahmen; drei dokumentierte Vergleichsbilder sind ausdrücklich Canvas-Testszene.22 Standard- und fünf neue HUD-Bilder tatsächlich angesehen; vollständigeGL-Logs ausschließlich mit erwarteter Software-VSync-Warnung.

## Runtime und APK

Godot 4.5.1 unter `/workspace/scratch/f0379b84af57/runtime-08/godot/Godot_v4.5.1-stable_linux.x86_64`. Offizielle Templates `runtime-08/data/godot/export_templates/4.5.1.stable`; SDK `runtime-08/android-sdk`; JDK 17 `/usr/lib/jvm/java-17-openjdk-amd64`. XDG_CONFIG_HOME=`runtime-08/config`, Export-XDG_DATA_HOME=`runtime-08/data`. Neue Wrapper unter `runtime-10`: check_wolf.py, capture_ui.py, export_wolf.py, verify_apk.py, prepare_report.py, prepare_handoff.py, stage_manifest.py. Der Test-Runner nutzt neue UUID-Datenordner je Lauf und Suite unter `runtime-10/validation-userdata`.

Xvfb/Libraries unter `runtime-08/display/root`, `/usr/bin/xkbcomp` vorhandener Link. Xvfb und Godot im selben Toolaufruf, eindeutiges TCP-Display, `-listen tcp -nolisten unix -nolisten local -ac`, LIBGL_ALWAYS_SOFTWARE=1, DummyAudio. Immer vollständige stdout/stderr bis tatsächliches Ende speichern und XR-Abbau mitprüfen. Keine schweren parallelenGL-Läufe für Leistungsmessung. Kein angeschlossenes Android-Gerät, kein gestarteter Emulator; ADB-Verbindungsnotizen sind keine Geräteprüfung.

Dauerhaft gespeichert: **Wolf-0.10.0-debug.apk**, 32,384,504 Bytes, SHA 256 `ecdb4755f3f3a921af7291bb1addeb0b8599ccf03ebd41c3cff783c0fe8ac404`, Datei-ID `libfile_8566959706f08191b8f73e9fa8d0e0ad`. Lokal `/workspace/scratch/f0379b84af57/wolf-next-10/builds/Wolf-0.10.0-debug.apk`. ARM 64/minSdk 24/target 35, package `cloud.kosch.wolf`, versionCode 10, keine Internetberechtigung. Signaturen v 2/v 3, Manifest, APK-ZIP-CRC und 16 KiB-ZIP-Ausrichtung geprüft; Web-Release exportiert/CRC geprüft, ZIP lokal und CI.

Vorhandener dauerhaft gesicherter Schlüssel `recovered-08/Wolf-Android-debug.keystore`, Datei-ID `libfile_5a217f1d32088191ae46acaa939f8b24`; bei Umgebungsverlust genau diesen wiederherstellen, Standard-Debugalias/-Passwort. Zertifikat `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c` entspricht lokalen 0.4–0.9. Bis 0.3 anderer verlorener Schlüssel; CI verwendet temporäre Schlüssel. Nicht ohne Save-Sicherung zur Deinstallation raten. [Installation](android-install.md).

Geprüfter 0.9-Rückfall: `libfile_be640555e6548191b155d7bd050bfb48`,32.351.567 Bytes, SHA 256 `9c3799e55b8e95ccc352ebe5afb43b545a86760c3960ea1c26d313dec8d6dda2`, lokal `wolf-next-09/builds/Wolf-0.9.0-debug.apk`.

**Kein tatsächlicher Android-Geräte-/Emulatorstart.** Reales Touchgefühl und Geräteperformance offen. Modelle bleiben stilisiert; vollständiger Lebenszyklus, Partnersuche, eigener Nachwuchs und kooperative Jagd fehlen. Nächste sinnvolle Arbeit: reale Geräteprüfung mit 0.10, Spielgefühl der Körperabstände, weitere abwechslungsreiche friedliche Tierinteraktionen und erzählerische Natur-/Hauptmissionen.
