# Entwicklungsübergabe · Wolf

Stand **0.4.0**, 8. Oktober 2026. Repository `chekento/wolf`; Veröffentlichung getesteter Änderungen auf main ist vom Nutzer autorisiert. Zieltermin: 8. Oktober 2026, 10:00 Europe/Berlin. Genau zwei Entwicklungsagenten sind autorisiert: Welt/Gameplay und Grafik/Animation. Hauptagent übernimmt Integration, UI, Tests und APK; keine weiteren Agenten.

## Arbeitsstand

0.4 vergrößert 64 auf 256 Gebiete mit 1536 Naturorten, 18 Storykapiteln, 40 Erlebnissen, wiederholbaren echten Begegnungsaufgaben, Rudelroutinen und allmählichen Jahreszeiten. Neue Modelle, Folgekamera, Unterwuchs, Himmel, Wetter, illustriertes Menü und detaillierter Atlas sind integriert. Alle alten Gebiets-IDs und lokalen Koordinaten bleiben gültig; alte Saves werden nach v4 übernommen.

Die Grundlage dieses Durchgangs war main `362b5b57c18bd710ee91334d0fb95b9002c1fe7e`, Baum `56cf207d99bb69209076b9b248c4291a420f417f`. Der lokale Commit `7f6c04e` hatte denselben Baum. Weiterarbeit immer mit **frischem main** in isoliertem Checkout beginnen; ältere lokale Arbeitskopien nicht als neuesten Stand ansehen. Bei Veröffentlichung die erwartete main-SHA prüfen und atomar per Compare-and-swap aktualisieren. Bei konkurrierender Änderung zuerst Inhalt/Konflikte prüfen.

Aktueller lokaler Checkout: `/workspace/scratch/7d54411ab077/wolf-ready-04`. Die ältere Arbeitskopie `wolf` ist ein unveröffentlichtes Zwischencheckpoint und darf nicht darüberkopiert werden. Beide Agenten haben 0.4 eingefroren; keine ausstehende Codeänderung.

## Relevante Architektur

- `world_data.gd`: deterministischer 16×16-Verbund, alte IDs/Seeds, sechs Naturorte je Gebiet; `water_bank(region)` ist ein freier und tatsächlich trinkbarer Zielpunkt.
- `state.gd`/`pack_life.gd`: atomare Saves, echte Aktionszähler, angenommene Begegnungsbaselines und Seriennummern, natürliche Story-Gates, Tagesroutinen, 30 Tage je Jahreszeit. Menüs und Hintergrund pausieren; ein Tag = 3600 aktive Sekunden, eine Alterswoche = sieben Tage.
- `main.gd`: reale Aktionen, Menüführung, Leitziele, sichere Bewegungs-Teilschritte, Hintergrund-/Zurück-Navigation. `_save_game()` sichert auch die Tierwelt; `_release_audio()` entpausiert vor Stop/Stream-Freigabe.
- `session_cache.gd`: höchstens 16 vollständige Welten, kompakte Tierpositionen separat in `wolf_save_v1.json.wildlife.json`; atomare Cache-Saves und robuste Eingaben.
- `collision_index.gd`: räumliche Buckets statt vollständiger Hindernissuche bei jeder Tierbewegung.
- `world_view.gd`/`animal_model.gd`/`forest_mesh.gd`: gemeinsame 3D-Modelle, weiche Posen, Augen-/Folgesicht mit Hindernisprüfung, saisonale Landschaft. Terrain, Wege und Wasser werfen keine eigenen Schatten: verhindert die sichtbare Schattenakne. Tier-/Baumschatten bleiben erhalten.
- `menu_art.gd`/`cartography.gd`: eigene Illustrationen, detaillierter Atlas, Naturort-Klickziele und Suchfunktion mit Erkundungsnebel.

## Runtime und Prüfungen

Godot 4.5.1 unter `/workspace/scratch/7d54411ab077/tool-cache/godot/Godot_v4.5.1-stable_linux.x86_64`; Android SDK unter `tool-cache/android-sdk`, JDK 17 unter `/usr/lib/jvm/java-17-openjdk-amd64`. Exportvorlagen unter `tool-cache/godot/templates/4.5.1.stable`. Nach Umgebungsausfall offizielle Godot-4.5.1- und Android-SDK-Pakete wiederherstellen. Der Build-Workflow enthält die vollständigen URLs und Schritte.

Import und alle vier Tests aus README laufen fehlerfrei. **2452 Prüfungen bestanden**; [Prüfbericht](validation-0.4.0.md). Zusätzlich immer vollständige Logs auf `SCRIPT ERROR`, `ERROR`, Fehlprüfungen und Leaks prüfen, da Godot bei einzelnen Enginefehlern trotzdem Exit 0 liefert. Tests nutzen getrennte Spielstanddateien.

Xvfb wurde ohne Systeminstallation aus Debian-Paketen nach `tool-cache/display` entpackt. Benötigt `LD_LIBRARY_PATH=.../display/usr/lib/x86_64-linux-gnu` und `xkbcomp` unter `/usr/bin/xkbcomp`. Für Aufnahmen Xvfb und Godot im selben Shell-Aufruf über TCP-Display starten, z.B. neues Display :153 mit `-listen tcp -nolisten unix -nolisten local -ac`. Alte Display-Nummern können eine Sperrdatei zurücklassen. Godot mit `DISPLAY=127.0.0.1:153 LIBGL_ALWAYS_SOFTWARE=1 --audio-driver Dummy --script tests/capture.gd` starten. 13 Bilder liegen in docs. Test-/Capture-Cleanup entpausiert Audio vor Stop; Capture wartet dazu einen kurzen Audiotakt.

## Signierung und Download

Die aktuelle gesicherte APK heißt **Wolf-0.4.0-debug.apk**; lokale Datei `wolf-ready-04/builds/Wolf-0.4.0-debug.apk`. SHA-256 `1bf4056c18ca55c4532a4e95625e57f5625e15f8454700966a457d7b77e18c07`.

Der frühere Schlüssel für 0.3 war nicht verfügbar. Der neue **Wolf-Android-debug.keystore** liegt außerhalb von git in `/workspace/scratch/7d54411ab077/wolf-android-signing/` und wurde dauerhaft als gleichnamige Datei gesichert. Falls lokal verloren: diese genaue gespeicherte Datei wiederherstellen, **keinen weiteren neuen Schlüssel generieren**. Standard-Debug-Alias `androiddebugkey`, Standard-Debug-Passwort; Editor-Konfiguration bleibt außerhalb des Repositorys.

Zertifikat-SHA-256 `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c`. APK nach Export mit `apksigner verify --verbose --print-certs`, AAPT-Manifest/ABI und SHA-256 prüfen. Package `cloud.kosch.wolf`, nur ARM64, minSdk24, target35, offline.

0.4 kann nicht direkt über die alte lokale Signatur installiert werden. Nutzer darüber informieren und keine Deinstallation ohne Save-Backup empfehlen. [Installationshinweise](android-install.md) enthalten eine ADB-Sicherung, die noch nicht auf einem Gerät ausprobiert wurde. Workflow-APKs haben temporäre Schlüssel und sind keine Signaturfortsetzung der lokalen APK. Bei fehlendem Buildzugriff die dauerhaft gesicherte geprüfte APK liefern und den Blocker offen nennen.

## Nächste sinnvolle Arbeit

Zuerst Android-Performance und tatsächliche Touchabläufe auf einem Gerät prüfen, soweit verfügbar. Danach bessere Orientierung beim Einstieg, ruhigerer HUD-Platzverbrauch, weitere eigenständige Landschaftsdetails und natürliche Begegnungsabläufe verbessern. Größere Gebietsanzahl allein hat geringere Priorität als spielbare Vielfalt und flüssige Darstellung. Saves, natürliches langsames Altern, offline Nutzung und friedliches Rudelleben erhalten. Ungetestete Änderungen nicht auf main veröffentlichen.
