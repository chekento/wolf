# Entwicklungsübergabe · Wolf

Stand **0.9.0**, 8. Oktober 2026. Repository `chekento/wolf`; Veröffentlichung funktionierender geprüfter Änderungen auf main ist autorisiert. Auf ausdrücklichen Nutzerwunsch wurden **fünf bestehende Agenten** für Naturmissionen, Welt-/Habitatdetails, Tiermodelle/Animation, Menüs und echte Missionsintegration eingesetzt. Root übernahm Integration, vollständige Tests, UI-Bilder, festen Rendervergleich und signierte APK.

## Basis und Veröffentlichung

Frisch gelesener main **`ea46e6f5f4f4d4dc868ee37bf1df3a395faa9789`**, Baum `9d64b226953928b839bc4d7b4027ee1e09317837`. Isolierter Checkout `/workspace/scratch/f0379b84af57/wolf-next-09`, Branch `wolf-09-development`. Unveränderte Vergleichsbasis `wolf-next-08`; bilingualer README-Frontpage-Stand und ältere Prüfberichte bleiben erhalten.

Weiterarbeit immer vom frisch gelesenen main in einem isolierten Checkout. Funktionierende Änderungen atomar mit erwarteter main-SHA veröffentlichen. Bei gleichzeitig geändertem main zuerst Inhalte und Konflikte prüfen. Lokaler Git-Push ist hier nicht authentifiziert; GitHub-API-Blobs, Tree, Commit und UpdateRef mit erwarteter SHA verwenden. Der Remote-Tree muss dem getesteten lokalen Tree exakt entsprechen. Keine privaten Schlüssel in git.

## Neue Naturreisen

`scripts/nature_journeys.gd` ist eine separate kanonische Missionsebene: sechs Typen je Gebiet, **1536 regionale Angebote mit 3328 geordneten Zielen**. Duft (Ort→Markierung), Wasser (wirkliches Trinkufer→Ort), Fährten (konkrete Hasenspuren 9 → 11), Beobachtung (dasselbe ruhige Reh 4 s→Ort), Orte (Ort4→5), Rast (Ort2→ausgewählter Variante-1-Schutzplatz → 3 s tatsächliche Ruhe). Dies sind sechs wiederkehrende Aufgabentypen mit regionalen Zielen, keine 1536 separat geschriebenen Hauptgeschichten.

- APIs: `definitions`, `definition`, `options`, `initial`, `status`, `begin`, `claim`, `abandon`, `note_action`, `note_observation`, `tick`, `clear_live`, `saved`, `restored`.
- Kanonische Definitionen entstehen aus unveränderter `WolfWorldData.generate`, werden lazily pro Gebiet erzeugt und auf 16 Regionen begrenzt. IDs `region:kind` sind streng kanonisch validiert.
- Genau eine aktive Naturreise. Annahme nur im aktuellen Gebiet; geordnete frische echte Handlungen, kein rückwirkendes Zählen. Einmalige explizite Belohnung: 30 XP, 2 Skillpunkte und 1 Bindungspunkt. Maximal 1536 eindeutige abgeschlossene IDs.
- Save bleibt **Version4**, zusätzliches validiertes Feld `nature_journeys`. Alte 0.8-Saves ohne das Feld beginnen ohne erfundene Nebenreise; Migration 1–4 und beschädigte neue Werte sind geprüft. Verdiente Schritte/Sekunden bleiben, Live-Presence wird bei Pause/Wechsel/Load geräumt.
- Beobachtung: tatsächliches akzeptiertes Reh, stabile Identität, freie 3D-Sicht, 145–420 Abstand, ruhige Pfoten, kein Alarm/Fluchtzustand. Rast: wirkliches Liegemood und korrekter Shelter. Missionstick maximal 0,1 s; Menüs/Hintergrund pausieren.
- State-Wrapper: `nature_journeys_options`, `nature_journey_status`, `begin_nature_journey`, `claim_nature_journey`, `abandon_nature_journey`, `note_nature_journey_action`, `note_nature_journey_observation`, `tick_nature_journey`, `clear_nature_journey_presence`. Normale reale `note_action` leitet beide Missionsebenen weiter; spezifische Fährten-ID wird explizit gesendet.

Die Hauptgeschichte **Die Düfte der Heimat** mit 8 Kapiteln/21 Handlungen, 18 Rudelerinnerungen, 40 Erlebnissen und vorhandenen Begegnungen bleibt erhalten. Reale Mutterbegrüßung, gemeinsame ruhige Ankunft, feste Story-Fährten, Watch-Identität, Kapitelbestätigung und einmalige Belohnungen unverändert. Langsames Altern: 60 min/Spieltag, 30 Tage/Jahreszeit, friedliches Rudelleben und Offline-Spiel bleiben erhalten; Rast überspringt keine Tage.

## UI und Controller

`show_nature_journeys` zeigt sechs kompakte Angebote, aktive Ziele, Fortsetzen, expliziten Abschluss und Zurücklegen. Reale Handlungen arbeiten auch neben der Mutter; bekannte genaue Fährten und Naturorte sind ohne doppelte Entdeckungsbelohnung erneut untersuchbar. Regionale Menüillustrationen unterscheiden Wald, Laubwald, Wiese, Moor, Küste und Schnee.

Root behob bei Integration die Aufgabenpriorität: solange eine Naturreise aktiv und kein `guided_main_story` gewählt ist, bevorzugen Zieltext, Live-HUD, Kontextaktion und tatsächliches `observe` die Naturreise. Explizite Storyführung schaltet zurück. Zwei gleichzeitig verschieden akzeptierte Rehe dürfen ihre Identitäten nicht tauschen; die neue echte Controller-Suite prüft dies. Physische gemeinsame Handlungen können passende getrennte Missionen legitim voranbringen.

`set_waypoint` beendet automatische Führungsflags; persönliche Kartenziele bleiben bei Missionsfortschritt und Save/Restart erhalten. Die Führungsflags sind wie bisher UI-Sitzungszustand, während tatsächlicher Wegpunkt und Missionen gespeichert werden. HUD-Panels ignorieren Pointer. Beobachtungsanzeigen zählen reale aktive Sekunden.

## Originalgrafik und Habitat

`habitat_details.gd` plant rein dekorative Gruppen an **vorhandenen decor-Indizes**: höchstens 96 ersetzte Unterflora-Instanzen, sechs zusätzliche räumliche Batches pro Gebiet. Keine neuen Weltobjekte, Kollisionen, RNG-Aufrufe oder verschobenen alten Positionen. Alle 256 vollständigen Generator-Hashes stimmen weiterhin mit `681fd8f2d02213bd55029cfbfc777b3038bd535b1cd6459c049545340cc4f283` überein.

Elf originale Meshgruppen: Laub, Pilze, Totholz, Kiesel, Treibholz, Seggen, Moos, bereifte Zweige, Schneebüschel, Kräuter, Samenstände. `forest_mesh.gd` begrenzt den gemeinsamen Meshcache auf 32; Habitatpläne auf 16 Regionen. `world_view.gd` ersetzt bestehende Flora 1:1, Detailreichweite 26 m, 3 m Rand, keine zusätzlichen Schatten. Wald tatsächlich 5451 → 5451 Instanzen und 191 → 197 Batches. `map_view.gd` zeichnet dieselben Anker in vorhandene Bodenchunks; bewegte Kamera löst keinen neuen Bake aus. Wege, Wasser, Kollisionen und unmittelbarer Höhlenraum bleiben frei. SurfaceTool-Normalen der tatsächlichen Laub-/Kiesel-/Pilzoberseiten zeigen nach oben und sind geprüft. Details sind dekorativ, keine neue Ess-/Sammelmechanik.

`animal_model.gd`: schlankere Schnauzen, Nasenbrücken, Lippen, Nüstern, weichere Fell-/Schulterkonturen, gerundete Hasenohren, größere Fuchsohren und kompakteres dreizinkiges Rehgeweih. Verfeinerte Normalen und Gras-/Trink-/Ruheposen bleiben in 21 geteilten Gelenkmeshes je Art. Dreiecke: Wolf/Fuchs 7292, Reh 5632, Hase 6548. Tatsächliche Schnauzenhöhe, Vertexgrenzen, durchgehender Pfotenkontakt und kontinuierliche Übergänge sind geprüft. Alte distanzbasierte Gangphase, Gelände-IK, Stützpfoten und weiche Landungen erhalten. Originale PNG-Atlanten unverändert, keine fremden Modellpakete.

Die 0.8-Renderwege bleiben: zwei bis drei schmale organische Arme mit überlappungsfreier Gabel, acht Bodenstile, auslaufende Enden; kein Südarm zur Heimathöhle. Alte Generator-/Physikreservierungen unverändert, gemeinsame sichtbare Geometrie in 2D/3D/Karten. `_release_audio`, Pointerbehandlung, Native-Zurück-Navigation und natürliche Tiernavigation erhalten.

## Tatsächliche Nachweise

**22 Suiten / 3257 bestandene Prüfungen**, vollständiger zentraler Schlusslauf mit sauberem Editorimport. Alle Headlesslogs ohne Script-/Enginefehler, Warnungen oder Ressourcenlecks. Neue Suiten: habitat_details, animal_detail, nature_journeys, nature_journey_controls, nature_journey_integration. CI führt alle 22 Suiten sowie Android-/Web-Export, Signatur, Manifest und 16 KiB-Ausrichtung aus. [Prüfbericht](validation-0.9.0.md), [Einzelwerte/APK](validation-0.9.0.json), [fester Grafikvergleich](render-profile-0.9.0.json).

22 tatsächliche UI-/Spielaufnahmen in 540 × 960 wurden neu erstellt und angesehen. Zusätzlich 3 Habitat-Nahbilder an tatsächlichen bestehenden Ankern (Wald Region 0/decor 1568; Wiese Region 3/decor 748; Moor Region 13/decor 262) sowie je 18 kontrollierte 0.8/0.9-Tieraufnahmen mit Originalspielmeshes. Separate Modell-Testszene ist ausdrücklich beschriftet. Nur erwartete Software-VSync-Warnung inGL. Zwei während paralleler Entwicklung gefundene Habitat-Typfehler wurden vor dem sauberen zentralen Lauf korrigiert; fehlerhafte Zwischenläufe zählen nicht.

Fester exklusiver Rendervergleich mit tatsächlichem 0.8/0.9, fünf Szenen,20 Warmup-/80 Messframes und verborgenem HUD. Rohwerte im Report; keine Android-FPS-Aussage. Reale Controllerprüfungen nutzen Positions- und spätere kanonische Kapitel-Fixtures, keinen behaupteten vollständigen menschlichen Durchlauf.

## Runtime und neue APK

Godot 4.5.1: `/workspace/scratch/f0379b84af57/runtime-08/godot/Godot_v4.5.1-stable_linux.x86_64`. Offizielle geprüfte Exportvorlagen unter `runtime-08/data/godot/export_templates/4.5.1.stable`. SDK `runtime-08/android-sdk`, JDK 17 `/usr/lib/jvm/java-17-openjdk-amd64`. XDG_CONFIG_HOME=`runtime-08/config`, XDG_DATA_HOME=`runtime-08/data`. Prüf-/Export-/Capture-/Profile-Wrapper unter `runtime-09`. Der Test-Runner verwendet strikt getrennte XDG_DATA_HOME-Verzeichnisse pro Suite unter `runtime-09/validation-userdata`; vorhandene alte Runtime-Daten nicht für frische Menütests wiederverwenden.

Xvfb samt Bibliotheken/Fonts liegt unter `runtime-08/display/root`; `/usr/bin/xkbcomp` verweist auf das extrahierte Binary. Xvfb und Godot im selben Toolaufruf, eindeutiges TCP-Display, `-listen tcp -nolisten unix -nolisten local -ac`, LIBGL_ALWAYS_SOFTWARE=1, DummyAudio. Profile exklusiv ohne andere schwere Tests/Exporte messen. Kein angeschlossenes Android-Gerät und kein gestarteter Emulator; ADB-Verbindungsnotizen sind keine Geräteprüfung.

Dauerhaft gespeichert: **Wolf-0.9.0-debug.apk**, 32.351.567 Bytes, SHA256 `9c3799e55b8e95ccc352ebe5afb43b545a86760c3960ea1c26d313dec8d6dda2`, Datei-ID `libfile_be640555e6548191b155d7bd050bfb48`. Lokal `/workspace/scratch/f0379b84af57/wolf-next-09/builds/Wolf-0.9.0-debug.apk`. ARM64/minSdk 24/target 35, package `cloud.kosch.wolf`, versionCode 9, keine Internetberechtigung. Signaturen v2/v3, Manifest, APK-ZIP-CRC und `zipalign -c -P16 4` bestanden. Web-Release exportiert und ZIP-CRC geprüft; Web-ZIP bleibt lokal/CI.

Vorhandenen Schlüssel wiederverwendet: `recovered-08/Wolf-Android-debug.keystore`, dauerhaft `libfile_5a217f1d32088191ae46acaa939f8b24`. Bei Umgebungsverlust genau diesen wiederherstellen, Standard-Debug-Alias/-Passwort. Zertifikat SHA256 `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c` stimmt mit lokalen 0.4–0.8 überein. Bis 0.3 gab es einen anderen verlorenen Schlüssel; CI verwendet temporäre Schlüssel. Nicht ohne Save-Sicherung zur Deinstallation raten. [Installation](android-install.md).

Stabiler 0.8-Rückfall: `libfile_93150e4470788191ac1ef977bd5dd029`, 32.322.565 Bytes, SHA256 `9cc4592bce5cdce5aba3deb49a5e1570c1d3eff7851cf9698f13a2b2c1423be5`, lokal `wolf-next-08/builds/Wolf-0.8.0-debug.apk`.

**Kein tatsächlicher Android-Geräte-/Emulatorstart.** Touchgefühl und Geräteperformance offen. Modelle und Nahflora bleiben stilisiert und kantig. Vollständiger Lebenszyklus, Partnersuche, eigener Nachwuchs und kooperative Jagd fehlen. Nächste sinnvolle Arbeit: reale Geräteprüfung, weitere Originalmodelle und Flora, erzählerisch abwechslungsreichere Naturmissionen und Hauptstory-Ausbau.
