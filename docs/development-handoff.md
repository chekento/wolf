# Entwicklungsübergabe · Wolf

Stand **0.7.0**, 8. Oktober 2026. Repository `chekento/wolf`; Veröffentlichung getesteter Änderungen auf main ist autorisiert. Genau zwei vorhandene Agenten arbeiteten an Welt/Gameplay und Grafik/Animation. Root übernahm Integration, Menüs/Karte, alle Prüfungen und APK. Keine zusätzlichen Agenten.

## Stand und Grundlage

Frischer main war `2e70c5808507f9c47a3e1bbf7124a0ba9835f830`, Baum `2f47a386f0118151ffdf7c1a3b3701ba3e173122`. Isolierter Checkout `/workspace/scratch/7d54411ab077/wolf-next-07`, Branch `wolf-07-development`; unveränderte Vergleichsbasis `wolf-baseline-06`. Weiterarbeit stets mit neu gefetchtem main in einem isolierten Checkout beginnen. Getesteten Stand atomar mit erwarteter main-SHA aktualisieren; bei konkurrierenden Änderungen Inhalt und Konflikte zuerst prüfen.

0.4 vergrößerte die Welt auf **256 verbundene Gebiete** mit 1536 Naturorten, 18 Storykapiteln und 40 Erlebnissen. 0.5 ergänzte sichere tatsächliche Tierwege, Tagesroutinen, kompaktes HUD, Einstieg und Kamera-/Touchkontrolle. 0.6 ergänzte echte Futter-/Deckungs-/Trinkziele, Aufmerksamkeit, vier Begegnungen, sichere Kartenrouten und Gelände-Pfotenkontakt.

0.7 verdichtet diese Welt durch verlässliche Zielankünfte mit artspezifischer Verweildauer, lose Rehgruppen, auslaufenden Gruppenalarm und echte Geschwister-Spiel-/Ruhephasen. Zwei neue Begegnungen verlangen zwei gemeinsame Ankünfte mit dem Elternwolf beziehungsweise zwei verschiedene Tätigkeiten desselben Tiers. Der große Atlas bewahrt Gebiet, Ausschnitt, Zoom, Ebenen und Ziel beim Wechsel zur Ortsliste. Live-Anzeigen erklären tatsächliche Beobachtungs- und Elternnähebedingungen. Unregelmäßige Kronen, geneigte Äste, Gräser/Farne, Humus und Fellflächen ergänzen die stilisierte Originalgrafik. NPC-Gangphasen passen zur tatsächlichen Laufdistanz; 2D-Grasen senkt die Schnauze korrekt.

Weltobjekte, Seeds, alte Gebiets-IDs und lokale Koordinaten bleiben erhalten. Saves bleiben **Version 4**, inklusive älterer aktiver Begegnungen. Alter/Jahreszeiten wachsen weiterhin nur während aktiven Spiels; Menüs und Hintergrund pausieren. Ein Tag entspricht 3600 aktiven Sekunden, eine Alterswoche sieben Tagen, eine Jahreszeit 30 Tagen. Offline und friedliche Rudelgeschichten erhalten.

## Architektur und Grenzen

- `pack_life.gd.wildlife_activity` wechselt nach echter Ankunft und Verweildauer. Globale 35-Sekunden-Zielwechsel sind entfernt. `animal_motion.gd.group_forage_target` nutzt ausschließlich geprüfte trockene Verbindungen; alle 1280 Rehanker geprüft, 377 gemeinsam genutzte Futterziele. Alarm wird nur aus frischen direkten Bedrohungen weitergegeben und zirkuliert nicht endlos.
- `state.gd`: `pack_walk` zählt je drei aktive Sekunden mit echter Elternnähe und freiem Bodenpfad; `wildlife_cycle` zählt je drei Sekunden am tatsächlichen Tierziel bei unterschiedlichen Tätigkeiten. `WolfPackLife.animal_key` erhält die Individuenidentität. Fortschritt und Identität werden gespeichert; `current_activity`, `player_ready` und `companion_ready` sind Live-Felder, werden leer/false gespeichert und geladen. `clear_encounter_presence` bei Regionen, Ansicht/Kamera und Hintergrund erhält erarbeiteten Fortschritt.
- `main.gd.show_map(expanded,snapshot)`: großer Atlas ohne Scrollcontainer, sichtbare Rückkehr und Ziele. Ausschnitt wird erst nach Containerlayout relativ zur tatsächlichen Karten-Skalierung übertragen. `atlas_view_state` übergibt Zoom/Ebenen/Region/Caption. Naturortlisten bleiben in der normalen Ansicht; unbekannte Orte bleiben geschützt.
- `main.gd` Live-HUD: Beobachtung verwendet freie Sicht und dieselbe angenommene Tieridentität; ein näher vorbeilaufendes Tier ersetzt sie nicht. Fortschrittsleisten lesen ausschließlich State-Zeiten. Panels ignorieren Pointereingaben; Stick und Landschaftswischen bleiben unabhängig.
- `animal_model.gd` behält 21 Gelenkmeshes pro Modell und Gelände-Pfotenkontakt. NPC-Gait ist Gameplay-Strecke/18, Spieler-Gait Strecke/22; Renderer gleicht dies korrekt aus. Fell-/Gesichtsflächen teilen vorhandene Gelenkmeshes.
- `map_view.gd` bäckt statische drei Baum-Schattenflächen und Farnbodenflora in vorhandene 400-Einheiten-Chunks. Kamerabewegung baut sie nicht neu. `forest_mesh.gd` nutzt geteilte Kronen-/Gras-/Farnmeshes mit nativer Distanzgeometrie. Sehr nahe Flora wird unter die Kamera abgesenkt.
- Regionale Bewegung bleibt Swept-/Wasser-geprüft, mit begrenztem bedarfsgesteuertem 80×80-AStar. Kein Aufholteleport. Sitzungscache hält höchstens 16 volle Welten; kompakte Tierpositionen bleiben separat.
- Audio weiterhin draußen starten, in Menüs/Hintergrund stoppen. Keine kurzlebigen Pause-/Resume-Wechsel einführen. `_release_audio` beim Teardown nutzen. Text-Mindestbreiten kleiner Buttons erhalten; pauschales `clip_text=true` hatte ältere Footertexte versteckt.

## Prüfungen und Runtime

Godot **4.5.1** liegt unter `runtime-07/godot/Godot_v4.5.1-stable_linux.x86_64`, Android SDK unter `runtime-07/android-sdk`, JDK17 unter `/usr/lib/jvm/java-17-openjdk-amd64`. Exportvorlagen `runtime-07/godot/templates/4.5.1.stable`; offizielle Vorlagen wurden mit HTTP-Bereichen entpackt und ZIP-CRC geprüft. Editor-SDK-/Keykonfiguration liegt außerhalb von git.

**Zwölf Suiten, 2750 Prüfungen bestanden**, vollständige Logs ohne Fehler/Warnung/Leak. Ein expliziter Datentyp im neuen Atlas-Test wurde vor dem sauberen Schlusslauf korrigiert. [Prüfbericht](validation-0.7.0.md), [maschinelle Daten](validation-0.7.0.json). Immer Logs lesen: Godot kann Scriptfehler trotz Exit0 melden. Die CI prüft zwölf Suiten, Export, APK-Signatur, Manifest und 16-KiB-ZIP-Ausrichtung.

Neue Menüs, große Karten und reale Beobachtungsanzeige tatsächlich unter Linux angesehen. 16 UI-Spielaufnahmen sowie 23 Grafikdetails; einzige GL-Warnung ist fehlende Software-VSync-Umschaltung. [Fester Grafikvergleich](render-profile-0.7.0.json) mit 20 Warmup-/80 Messframes und identischem 540×960-Mesa-llvmpipe: 2D-Wald Median22,26→19,10ms, Drawcalls408,6→200,2; Wald-Folge211,86→217,44ms. Waldinstanzen5359→5394, gesamte Batches190→191. Keine Android-Bildratenmessung.

Xvfb: `runtime-07/display/root/usr/bin/Xvfb`, Bibliotheken `runtime-07/display/root/usr/lib/x86_64-linux-gnu`, Fonts `runtime-07/display/root/usr/share/fonts/X11/misc`. Xvfb und Godot im selben Toolaufruf starten, eindeutiges TCP-Display mit `-listen tcp -nolisten unix -nolisten local -ac`; `DISPLAY=127.0.0.1:NUM`, `LIBGL_ALWAYS_SOFTWARE=1`, Audio Dummy. `/usr/bin/xkbcomp` zeigt auf die extrahierte Version. Profile exklusiv ohne schwere parallele Tests/Exporte messen.

## APK und Signierung

Dauerhaft gesichert: **Wolf-0.7.0-debug.apk**, lokal `wolf-next-07/builds/Wolf-0.7.0-debug.apk`, **32.285.379 Bytes**, SHA256 `389028d826585e08218b0db6d9da6d0fd179c818a56e1b39d55be4ecd5c3466d`. Gespeicherte Datei-ID `libfile_3310e9b33ce88191bccf946ea949b3c3`. Web-Paket `Wolf-0.7.0-web.zip` ebenfalls dauerhaft gesichert.

Vorhandener **Wolf-Android-debug.keystore** wurde wiederhergestellt, kein neuer Schlüssel erzeugt. Lokal `/workspace/scratch/7d54411ab077/recovered-07/Wolf-Android-debug.keystore`; dauerhaft gespeicherte Datei `libfile_5a217f1d32088191ae46acaa939f8b24`. Bei Umgebungsverlust genau diese Datei wiederherstellen. Standard-Debug-Alias/-Passwort, keine privaten Schlüssel in git. Ein zunächst abgewiesener Byteabruf funktionierte mit dem unveränderten aktuellen Transferhelper und dem ehrlich bezeichneten HTTP-Client `Codex-Library-Transfer/1.0`; Rückgaben und Dateimetadaten vollständig erhalten.

Zertifikat-SHA256 **08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c** entspricht den lokalen0.4/0.5/0.6-APKs. Signaturschemata v2/v3, ZIP-CRC, Manifest/ABI und `zipalign -c -P16 4` sind bestanden. Android ARM64, minSdk24, target35, Package `cloud.kosch.wolf`, keine Internetberechtigung.

0.6-Rückfall ist wiederhergestellt unter `recovered-07/Wolf-0.6.0-debug.apk`, Größe32.268.995, SHA256 `a726a697d37ca92603a83ee8f626ea4019f2a7befaadbc3b99d7d73a7cf4ff33`. Ältere lokale APKs bis0.3 hatten einen anderen verlorenen Schlüssel. Actions-APKs erhalten temporäre Schlüssel und ersetzen die lokale Signaturkontinuität nicht. [Installations-/Save-Sicherungshinweise](android-install.md) beachten.

## Offene Arbeit

Kein tatsächlicher Android-Geräte-/Emulatorstart; Touchgefühl und Geräteperformance bleiben unbestätigt. 2D ist Standard, 3D frei umschaltbar. Originalgrafik ist stilisiert und kantige Nahflora teilweise sichtbar. Der Stand ist ein spielbarer Prototyp, ohne vollständige Partnersuche, eigenen Nachwuchs oder kooperative Jagd. Weitere sinnvolle Arbeit: begehbare Landschaftsvielfalt, eigenständige Tierdetails/Animationen und tatsächliche Geräteprofilierung. Saves, langsames Altern und friedliches Rudelleben erhalten.
