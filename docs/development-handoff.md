# Entwicklungsübergabe · Wolf

Stand **0.6.0**, 8. Oktober 2026. Repository `chekento/wolf`; Veröffentlichung getesteter Änderungen auf main ist vom Nutzer autorisiert. Genau zwei vorhandene Entwicklungsagenten waren autorisiert: Welt/Gameplay und Grafik/Animation. Hauptagent übernahm Integration, UI, Tests und APK; keine weiteren Agenten.

## Arbeitsstand

0.4 vergrößerte 64 auf 256 Gebiete mit 1536 Naturorten, 18 Storykapiteln, 40 Erlebnissen, wiederholbaren echten Begegnungsaufgaben und allmählichen Jahreszeiten. Alle alten Gebiets-IDs, Seeds und lokalen Koordinaten bleiben gültig; Saves bleiben v4.

0.5 ergänzt tatsächliche Tierwege um Felsen und über Brücken ohne Aufholteleport, Heimkehr vor Nacht-Ruhe, artspezifische Aktivität, gespeicherten kompakten HUD-Modus, sichtbaren Einstiegsstart und fortlaufende Begegnungsziele. Zwei-Finger-Bewegung/Blick, emulierte Mausduplikate, Kamerapointer und nahe Kontextaktionen sind geprüft. Grafik erhält gebackene 2D-Bodenflora, 3D-Instanzfarben, native Distanzgeometrie, natürlichere Palette und biomeigene Naturorte. Menüs und Hintergrund stoppen Audio; draußen startet der Naturklang neu.

0.6 ergänzt in allen 256 Gebieten tatsächliche Deckungs-, Futter- und trockene Uferziele, artspezifische Aufmerksamkeit/Flucht und vier neue mehrstufige Begegnungen. Sichere Kartenwege umgehen Hindernisse und nutzen reale Brücken. Die Karte hat Ebenen, Ausgänge, Naturortlisten und am Finger verankertes Aufziehen. 3D-Tiere setzen vier eigenständige Pfoten auf die Geländeform; Kopf, Ohren und Rute reagieren auf Blickziel, Flucht und Begrüßung. Saves bleiben v4, alte IDs und Seeds unverändert.

Die Grundlage dieses Durchgangs war der frisch gefetchte main-Commit `a0c0e961d9172f53e85c6ffca45e6ee95dfd20b3`, Baum `c0c30df4d9d9fcfd359bb5d70f99ace78abf90b5`. Weiterarbeit immer mit **frischem main** in isoliertem Checkout beginnen. Bei Veröffentlichung erwartete main-SHA prüfen und atomar per Compare-and-swap aktualisieren; bei konkurrierender Änderung zuerst Inhalt/Konflikte prüfen.

Aktueller lokaler Checkout: `/workspace/scratch/7d54411ab077/wolf-ready-06`, isolierter Branch `wolf-06-delivery`. Er basiert auf dem zuvor veröffentlichten main `1589a7ec252ff77641d12ce0dcfb0e15617f4b5e`. `wolf-ready-05` ist der geprüfte 0.5-Rückfallstand. Nichts aus älteren Zwischenkopien darüberkopieren.

## Relevante Architektur

- `world_data.gd`: 16×16-Verbund, alte IDs/Seeds, sechs erreichbare Naturorte je Gebiet; `water_bank(region)` ist ein tatsächlich trinkbarer Zielpunkt.
- `state.gd`/`pack_life.gd`: atomare Saves, echte Aktionszähler, Begegnungsbaselines/Seriennummern, natürliche Story-Gates und Aktivitätszeiten. Menüs/Hintergrund pausieren; Tag = 3600 aktive Sekunden, Alterswoche = sieben Tage, Jahreszeit = 30 Tage. `compact_hud` ist eine optionale Save4-Vorliebe; alte Saves erhalten true.
- `animal_motion.gd`: geteilter regionaler Swept-Kollisions-/Wasserprüfer, nahe freie Ziele, lokales Ausweichen und bedarfsgesteuertes 80×80-AStar-Netz mit vollständig geprüften Kanten. Direkte Wege bauen keinen Graph. Einmaliger leerer Testaufbau etwa 206 ms, keine Android-Messung. Kein Aufholteleport und keine unbeschränkte Bewegung bei langen Frames.
- `main.gd`: reale Aktionen und Kontextreihenfolge; fortlaufende Begegnungsführung wird durch manuelle Kartenziele aufgehoben. Kompakte Kopfleiste mit stets erreichbaren Bedürfnissen/Begegnungen; `_fit_header` passt nach Containerlayout an. Kleine Buttons müssen ihre Text-Mindestbreite behalten: pauschales `clip_text=true` machte Menü-/Footer-Tasten leer und wurde vor Auslieferung in echten Bildern korrigiert.
- `main.gd` Audio: `_build_ambient()` erzeugt den Stream; `_sync_audio()` startet erst draußen und stoppt in Menüs/Hintergrund. `modal` ruft `close_overlay(false)` auf und startet keine kurzlebige Zwischenwiedergabe. `_release_audio()` stoppt und gibt Streams frei; `_exit_tree()` nutzt es ebenfalls. Nicht wieder auf schnelle Stream-Pause-/Resume-Wechsel umstellen.
- `session_cache.gd`: maximal 16 volle Welten; kompakte Tierpositionen separat in `wolf_save_v1.json.wildlife.json`; atomare Cache-Saves. Navigationsobjekte bleiben nur im begrenzten Weltcache.
- `world_view.gd`/`forest_mesh.gd`/`animal_model.gd`: Instanzfarben pro räumlichem Mesh-Batch, native Distanzindizes aus den Originalvertices, weiche Posen und geteilte Modelle, Augen-/hindernisgeprüfte Folgesicht. Terrain/Wege/Wasser werfen keine eigenen Schatten; Tiere/Bäume weiterhin. Ruhige nahe Boden-Laubmarken faden mit Bildschirmableitungen.
- `map_view.gd`: 400-Einheiten-Chunks für statische Bodenmalerei/Blumen; nach Gebiet/Jahreszeit neu erzeugt, bei Kamerabewegung wiederverwendet. Individuelle Tierbewegungen und schöne illustrierte Bäume bleiben sichtbar.
- `menu_art.gd`/`cartography.gd`: eigene Illustration, Höhenlinien/Kompass/Maßstab, echte Naturort-Klickziele, Suche und Erkundungsnebel.

## Runtime und Prüfungen

Godot 4.5.1: `/workspace/scratch/7d54411ab077/tool-cache/godot/Godot_v4.5.1-stable_linux.x86_64`. Android SDK: `tool-cache/android-sdk`; JDK17: `/usr/lib/jvm/java-17-openjdk-amd64`; Vorlagen: `tool-cache/godot/templates/4.5.1.stable`. Offizielle Downloads und Aufbau im Workflow; bei Umgebungsausfall wiederherstellen.

Import und alle **neun** Tests aus README bestanden: **2652 Prüfungen**, volle Logs ohne Parser-/Enginefehler, Warnungen, Fehlprüfungen oder Leaks. [Prüfbericht](validation-0.6.0.md), [maschinelle Prüfdaten](validation-0.6.0.json). Tests verwenden eigene Spielstanddateien. Bei Godot immer Logs prüfen: Scriptfehler können trotz Exit0 auftreten.

0.4-Actions scheiterte nach grünen Grafikchecks an einer intermittierenden Audio-Freigabewarnung. 0.5 prüft weiterhin streng und trennt reine Grafikchecks ohne Audio von echten UI-/Audioabläufen. Fünf zusätzliche vollständige UI-Läufe mit Playback und schnellen Menüwechseln waren sauber; Fehlerfilter nicht abschwächen.

Xvfb aus Debian-Paketen liegt in `tool-cache/display`. Braucht `LD_LIBRARY_PATH=.../display/usr/lib/x86_64-linux-gnu`, `xkbcomp` unter `/usr/bin/xkbcomp`. Xvfb und Godot im selben Shell-Aufruf über TCP-Display starten, neue Displaynummer wählen, `-listen tcp -nolisten unix -nolisten local -ac`. Alte Nummern können Sperrdateien hinterlassen. Godot mit `DISPLAY=127.0.0.1:NUM LIBGL_ALWAYS_SOFTWARE=1 --audio-driver Dummy --script tests/capture.gd`. 13 Bilder liegen in docs. Cleanup: Verarbeitung stoppen, Audio entpausieren, .2s warten, `_release_audio`, .2s warten, entfernen/queue_free und .15s Nachlauf. Die einzige Bildlauf-Warnung betrifft fehlende VSync-Umschaltunterstützung der Softwareanzeige.

`tools/profile_rendering.gd` liefert fünf feste Szenen mit 20 Warmup- und 80 Messframes, JSON und PNGs; Output-Stamm als Benutzerargument. Für faire Werte keinen parallelen schweren Render-/Exportlauf starten. Mittelwert/Median/P90, Drawcalls und Primitives verwenden; `TIME_PROCESS` enthält kurze Initialisierungsfenster. Software-GL-Werte sind **keine Android-Bildrate**. [Vergleichsdaten](render-profile-0.5.0.json).

## Signierung und Download

Aktuelle dauerhaft gesicherte APK: **Wolf-0.6.0-debug.apk**, lokale Datei `wolf-ready-06/builds/Wolf-0.6.0-debug.apk`. Größe 32.268.995 Bytes, SHA-256 `a726a697d37ca92603a83ee8f626ea4019f2a7befaadbc3b99d7d73a7cf4ff33`.

**Wolf-Android-debug.keystore** liegt außerhalb von git in `/workspace/scratch/7d54411ab077/wolf-android-signing/` und wurde dauerhaft als gleichnamige Datei gesichert. Bei Verlust genau diese Datei wiederherstellen, **keinen weiteren neuen Schlüssel erzeugen**. Standard-Debug-Alias `androiddebugkey`, Standard-Debug-Passwort; Editor-Konfiguration außerhalb des Repositorys.

Zertifikat-SHA256 `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c`. Nach Export `apksigner verify --verbose --print-certs`, AAPT-Manifest/ABI, ZIP-CRC, SHA256 und `zipalign -c -P 16 4` prüfen. Package `cloud.kosch.wolf`, nur ARM64, minSdk24, target35, offline.

0.6 verwendet denselben lokalen Schlüssel wie 0.4 und 0.5 und kann diese aktualisieren. Ältere lokale Builds bis 0.3 hatten eine andere nicht mehr verfügbare Signatur. Keine Deinstallation ohne Save-Backup empfehlen; [ADB-Hinweise](android-install.md) sind noch nicht auf einem Gerät geprüft. Actions-APKs besitzen temporäre Schlüssel und setzen die lokale APK-Signatur nicht fort.

## Offene Grenzen

Tatsächlicher Android-Start, Touchgefühl und Geräteperformance bleiben mangels Gerät/Emulator offen. 2D ist die Standardansicht, 3D eine frei umschaltbare Erkundungssicht. Der Stand ist ein spielfähiger Prototyp; vollständige Partnersuche, eigene Nachwuchspflege und kooperative Jagd sind noch nicht enthalten. Sinnvoll sind weitere eigenständige Landschafts-/Tierdetails, abwechslungsreiche echte Begegnungen und mögliche Geräteprofilierung; größere Gebietsanzahl allein ist weniger wert als begehbare Vielfalt und angenehme Darstellung. Saves, natürliches langsames Altern, offline Nutzung und friedliches Rudelleben erhalten. Ungetestete Änderungen nicht auf main veröffentlichen.
