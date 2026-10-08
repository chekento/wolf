# Entwicklungsübergabe · Wolf

Stand **0.8.0**, 8. Oktober 2026. Repository `chekento/wolf`; Veröffentlichung getesteter Änderungen auf main ist autorisiert. Auf ausdrücklichen Nutzerwunsch arbeiteten **fünf Agenten** an Welt/Wege, Grafik/Animation, Hauptgeschichte, Menüintegration und Reiseprüfung. Root übernahm Integration, vollständige Tests, Dokumentation, signierte APK und Web-Export.

## Grundlage und Veröffentlichung

Frischer main: `6e2a3fe1aa08ec6a430a86516c7d1c0411643855`, Baum `db599951805dc31d6868f5c073ed3cdfa90d6ab1`. Isolierter Checkout `/workspace/scratch/f0379b84af57/wolf-next-08`, Branch `wolf-08-development`; unveränderte Vergleichsbasis `wolf-baseline-07`. Der bilinguale README-Frontpage-Commit bleibt erhalten.

Beim Umgebungswechsel fehlten die vorherigen uncommitteten 0.8-Dateien und die Runtime. Die Erweiterungen wurden vom gesicherten 0.7 aus rekonstruiert und vollständig erneut geprüft. Frühere verlorene Prüfungen und Bilder zählen nicht als aktuelle Nachweise.

Weiterarbeit immer mit frisch gelesenem main, isoliert und atomarer Veröffentlichung gegen die erwartete main-SHA. Bei parallel verändertem main zuerst Inhalte und Konflikte prüfen. Lokaler Git-Push ist hier nicht authentifiziert; GitHub-API-Blobs, Tree, Commit und UpdateRef mit erwarteter SHA verwenden. Der Remote-Tree muss dem getesteten lokalen Tree exakt entsprechen. Keine privaten Schlüssel in git.

## Spiel und Speicher

Die neue Hauptgeschichte **Die Düfte der Heimat** hat acht Kapitel und 21 geordnete körperliche Handlungen. Die Reise führt von der Höhle zur Bergwiese, über Flussauen und Kiefernwald zurück nach Hause. Alte 18 Rudelerinnerungen, 40 Erlebnisse, Begegnungen und 256 Gebiete mit 1536 Naturorten bleiben erhalten. Alte Seeds, Objekte, Fährten, Dekoration, Höhen und Koordinaten sind exakt erhalten.

Saves bleiben **Version 4**; `main_story` ist ein zusätzliches, validiertes Feld. Migration 1–4 ist geprüft. Alter und Jahreszeiten wachsen nur während aktiven Spiels; Menüs und Hintergrund pausieren. Rast überspringt keine Tage. Friedliches Rudelleben und Offline-Spiel bleiben erhalten.

- `main_story.gd` hält kanonische Kapitel, Ziele und Titel einmal im Cache. API: `initial`, `restored`, `saved`, `status`, `begin`, `advance`, `note_action`, `note_observation`, `tick`, `clear_live`. Eine zusammenhängende Liste abgeschlossener Kapitel-IDs ist Speicherautorität. Beschädigte Checkpoints können keine Ziele oder Belohnungen frei setzen. Aktionen vor Missionsbeginn zählen nicht rückwirkend.
- Kapitel müssen explizit bestätigt werden und geben einmal 40 XP, drei Skillpunkte und zwei Bindungspunkte. Gemeinsame Ankunft benötigt echte ruhige Mutterbewegung, Escort, Nähe und freien Bodenpfad für drei aktive Sekunden. Die erste Begrüßung betrifft die tatsächliche erwachsene Mutter überall in Region 0, außerhalb der Heimat muss sie echte Begleiterin sein.
- Beobachtung benötigt dasselbe ruhige Reh, stabile Individuenidentität, tatsächliche 3D-Sicht, 145–420 Abstand und vier aktive Sekunden. Finale Rast benötigt vier Sekunden tatsächliche Ruhe nahe der Mutter. Missionstick ist auf 0,1 Sekunden begrenzt. Live-Presence wird beim Speichern und bei Pausen/Ansicht-/Gebietswechseln verworfen; verdienter Fortschritt bleibt.
- `state.gd` besitzt `main_story_progress` und Wrapper. Normale tatsächliche Aktionen werden weitergeleitet. `clear_encounter_presence` räumt Story-Presence vor dem eigenen frühen Return auf. Alte Storyfelder bleiben unabhängig.
- `main.gd.show_main_story` zeigt Start, Fortsetzen und Kapitelabschluss vor langen Texten; Ziele, Stageplan, aktive Sekunden und Duftführung sind erreichbar. Footer Geschichte öffnet die Hauptgeschichte; `show_story` bleibt als Rudelerinnerungen erreichbar. Wichtige Missionshandlungen haben vor allgemeiner Mutterbegrüßung Vorrang. Eine bereits gefundene konkrete Fährte darf ohne doppelte Belohnung gelesen werden. Persönliche Kartenziele beenden Storyführung. HUD-Panels ignorieren Pointereingaben.

## Wege und Animation

`wilderness_paths.gd` und `world_data.render_paths` liefern eine separate deterministische Rendergeometrie mit Cache16: zwei bis drei schmale organische Arme, gemeinsame überlappungsfreie Gabel, acht Bodenstile und auslaufende Enden. Region 0 hat keinen Südarm zur Höhle. Alte `path_points`/`on_path` bleiben Generatorreservierung und Physik; alle vier Renderer teilen die neue sichtbare Geometrie. Zusätzliche Unterflora füllt frühere breite Reservierungen, ohne neue Kollisionen. 3D-Normalen zeigen nach oben; Höhe ist `height_at+.012`, Alpha/Vertexfarbe ohne Schatten. Explizites `painted_colour` verhindert zu helle Bodenstreifen.

`animal_model.gd` behält 21 Gelenkmeshes, Gelände-Pfotenkontakt und distanzbasierte Gangphase. Hermite-Swing, stabile Stützpfoten, weiche Gangartwechsel und auslaufende Landung verhindern abrupte Schritte. Frühe Torso-Anpassung vermeidet spätes Absinken. Eine identische positive Clock darf die Pose bei wiederholtem `sync_camera` nicht zurücksetzen. Kopf, Ohren, Rute und Atmung bleiben artspezifisch. Die 2D-Pose wird pro Individuum und Region geglättet, Cache maximal24, ohne zusätzliche Spriteflächen; NPC-Phase dient als animation_key.

Bestehende tatsächliche Tiernavigation, Kamerakollision, begrenzter AStar, Wildlife-Speicher und `_release_audio` erhalten. Keine kurzen Audio-Pause-/Resume-Wechsel einführen. Kleine Buttontexte und Android-Zurück-Navigation erhalten.

## Aktuelle Nachweise

**17 Suiten mit 3005 Prüfungen neu bestanden**, sämtliche vollständigen Logs ohne Script-/Enginefehler, Warnungen oder Leaks. Sauberer Editorimport. CI führt alle 17 Suiten sowie Android-/Web-Export, Signatur, Manifest und 16-KiB-Ausrichtung aus. [Prüfbericht](validation-0.8.0.md), [Einzelwerte/APK](validation-0.8.0.json), [Grafikrohwerte](render-profile-0.8.0.json).

20 tatsächliche UI-/Spielbilder und 15 Wegbilder wurden unter Linux/Xvfb/Mesa aufgenommen und angesehen. Die Missionsaufnahme zeigt echte 2/4-Sekunden-Beobachtung. Ein anfänglich fehlendes XKB-Paket wurde vor dem erfolgreichen Bildlauf ergänzt. Einzige Godot-GL-Warnung: keine Software-VSync-Umschaltung.

Fester Vergleich mit fünf Szenen, 20 Warmup-/80 Messframes, 540×960 und verborgenem HUD: Wald-Folge Median366,37→368,04ms; Wald-Augen379,99→351,48ms; 2D-Zeichenaufrufe200,16→183,16. Die auffällige erste 2D-Zeitmessung wurde mit ABBA nachgeprüft: alt31,69/42,50ms, neu36,03/37,44ms. Die Bereiche überlappen. Ausschließlich Software-Hostwerte, keine Android-FPS-Aussage.

## Runtime

Godot4.5.1: `/workspace/scratch/f0379b84af57/runtime-08/godot/Godot_v4.5.1-stable_linux.x86_64`. Offizielle Exportvorlagen vollständig ZIP-CRC geprüft, unter `runtime-08/data/godot/export_templates/4.5.1.stable`. SDK `runtime-08/android-sdk`, JDK17 `/usr/lib/jvm/java-17-openjdk-amd64`. Export mit XDG_CONFIG_HOME=`runtime-08/config`, XDG_DATA_HOME=`runtime-08/data`.

SDK-Platform-Tools lagen lokal zunächst ein Verzeichnis zu tief und wurden vor dem sauberen Export richtig eingeordnet. ADB-Version tatsächlich geprüft, Daemon nicht gestartet, kein Gerät verbunden. Xvfb unter `runtime-08/display/root/usr/bin/Xvfb`, Bibliotheken und Fonts im selben extrahierten Root. `/usr/bin/xkbcomp` verweist auf das extrahierte Binary. Xvfb und Godot im selben Toolaufruf mit eindeutigem TCP-Display, `-listen tcp -nolisten unix -nolisten local -ac`, LIBGL_ALWAYS_SOFTWARE=1, DummyAudio. Profile exklusiv ohne parallele schwere Tests/Exporte messen.

## APK, Schlüssel und Grenzen

Dauerhaft gesichert: **Wolf-0.8.0-debug.apk**,32.322.565 Bytes, SHA256 `9cc4592bce5cdce5aba3deb49a5e1570c1d3eff7851cf9698f13a2b2c1423be5`, Datei-ID `libfile_93150e4470788191ac1ef977bd5dd029`. Lokal `wolf-next-08/builds/Wolf-0.8.0-debug.apk`. ARM64, minSdk24, target35, Package `cloud.kosch.wolf`, versionCode8, keine Internetberechtigung. Signaturen v2/v3, ZIP-CRC und `zipalign -c -P16 4` bestanden. Web-Release exportiert und ZIP-CRC geprüft; Web-ZIP bleibt lokal/CI, kein behaupteter dauerhaft gespeicherter Web-Download.

Vorhandener **Wolf-Android-debug.keystore** wiederhergestellt unter `recovered-08/Wolf-Android-debug.keystore`, dauerhaft `libfile_5a217f1d32088191ae46acaa939f8b24`. Bei Umgebungsverlust genau diesen wiederherstellen; Standard-Debug-Alias/-Passwort. ZertifikatSHA256 `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c` stimmt mit den lokalen0.4–0.7-Builds überein. Bis0.3 gab es einen anderen verlorenen Schlüssel; Actions-Builds haben temporäre Schlüssel. Nicht ohne Save-Sicherung zur Deinstallation raten. [Installation](android-install.md).

0.7-Rückfall: `libfile_3310e9b33ce88191bccf946ea949b3c3`,32.285.379 Bytes, SHA256 `389028d826585e08218b0db6d9da6d0fd179c818a56e1b39d55be4ecd5c3466d`.

**Kein tatsächlicher Android-Geräte-/Emulatorstart.** Touchgefühl und Geräteperformance bleiben offen. 2D ist Standard, 3D optional. Nahflora und Modelle sind weiterhin stilisiert und kantig. Vollständiger Lebenszyklus, Partnersuche, eigener Nachwuchs und kooperative Jagd fehlen noch. Nächste sinnvolle Arbeit: Geräteprofilierung, feinere Originalmodelle/Nahflora und zusätzliche Naturmissionen.
