# Validierung · Wolf0.8.0

8. Oktober2026; Godot4.5.1.stable.official.f62fdbde1. Frische Basis main `6e2a3fe1aa08ec6a430a86516c7d1c0411643855`, isolierter Checkout `wolf-next-08`. Fünf Agenten für Welt, Animation, Hauptgeschichte, Menüintegration und Reiseprüfung; Root integrierte und prüfte den gesamten Stand.

## Tatsächliche Spielprüfungen

**17 Suiten, 3005 bestandene Prüfungen**, Exit0. Alle vollständigen Logs ohne Script-/Enginefehler, Warnungen oder Ressourcenlecks; sauberer Editorimport. [Maschinelle Einzelwerte](validation-0.8.0.json).

| Suite | Prüfungen | Ergebnis |
|---|---:|---|
| smoke | 2220 | bestanden |
| gameplay_expansion | 138 | bestanden |
| graphics_expansion | 75 | bestanden |
| ui_expansion | 52 | bestanden |
| animal_behavior | 18 | bestanden |
| atlas_expansion | 25 | bestanden |
| ecology_expansion | 63 | bestanden |
| encounter_controls | 25 | bestanden |
| locomotion_expansion | 40 | bestanden |
| living_world | 58 | bestanden |
| landscape_expansion | 11 | bestanden |
| atlas_observation | 25 | bestanden |
| path_expansion | 31 | bestanden |
| animation_expansion | 56 | bestanden |
| main_story | 91 | bestanden |
| main_story_controls | 36 | bestanden |
| story_journey | 41 | bestanden |

Die neue Hauptgeschichte hat acht Kapitel und21 geordnete Handlungen. Geprüft wurden Save-Migration1–4, kanonische und beschädigte Missionsstände, einmalige Belohnungen, echte Mutterbegrüßung, gemeinsame Ankunft mit tatsächlicher Mutterbewegung, Trinken/Naturort/Markierung neben der Mutter, bekannte konkrete Fährten ohne doppelte Belohnung, dasselbe ruhige Reh mit tatsächlicher freier Sicht, Bewegung/Alarm/Ansicht-/Menü-/Hintergrundsperren, Rast und gemeinsame Heimkehr. Die zusätzliche Reiseprüfung läuft tatsächliche Übergänge0→3→2→1→0 über `move_wolf`, prüft einen einzigen Begleiter sowie Speicher-/Tiercache-Erhaltung. Kanonische spätere Kapitel-Checkpoints dienen als Fixtures; dies ist kein behaupteter vollständiger menschlicher Spieldurchlauf.

Die Weltprüfung vergleicht alle256 erzeugten Gebiete mit dem alten Gesamtfingerabdruck `681fd8f2d02213bd55029cfbfc777b3038bd535b1cd6459c049545340cc4f283`. Alte Objekte, Fährten, Dekoration und Koordinaten bleiben identisch. Neue separate Renderwege haben526341 Gesamtvertices, maximal2781 pro Gebiet, acht Bodenarten,48 auslaufende Arme und0,846% bemalte Fläche. Alle Gabeln sind überlappungsfrei; Schulterpunkte, Dreieckkanten/-mitten und Geländeanschluss wurden geprüft. 3D-Normalen zeigen nach oben. Höhle und Spawn bleiben außerhalb der Wege; bestehende Brücken bleiben tatsächlich erreichbar.

Die Animationsprüfung umfasst56 neue Prüfungen sowie40 bisherige Locomotion-,75 Grafik- und11 Landschaftsprüfungen. Vier Arten behalten21 Gelenkmeshes, tatsächlichen Gelände-Pfotenkontakt und distanzbasierte Phasen. In kontrollierten540-Frame-Reihen je Art: maximal0,947mm Stützdrift pro Frame und0,037mm Kontaktfehler; kein Android-Performancewert.

## Tatsächlich gerenderte Ansichten

20 UI-/Spielbilder und15 Wegbilder entstanden unter Linux/Xvfb mit Mesa-llvmpipe. Hauptstory-Start/Fortsetzung, tatsächliche2/4-Sekunden-Beobachtungsanzeige, Missionsmenü, Menüs/Karten, Höhlenumfeld, Gabeln, Bodenarten und Brückenanlauf wurden angesehen. Einzig erwartete Godot-GL-Warnung: keine Software-VSync-Umschaltung. Die Umgebung musste vor dem Bildlauf mit fehlender XKB-Bibliothek vervollständigt werden; der erste erfolglose Displaystart zählt nicht als bestandener Spiellauf.

## Offene Grenzen

Kein tatsächlicher Android-Geräte- oder Emulatorstart. Touchgefühl und Gerätebildraten bleiben unbestätigt. Die3D-Nahflora ist weiterhin kantig; vollständiger Lebenszyklus, Partnersuche, eigener Nachwuchs und kooperative Jagd sind noch nicht implementiert. Offline-Spiel, allmähliches Altern, vorhandene Welt und bisherige Rudelerinnerungen bleiben erhalten.

## Grafikvergleich

[Feste Rohdaten](render-profile-0.8.0.json): je Szene20 Warmup-/80 Messframes,540×960, HUD verborgen, identischer Linux-Software-Renderer. Wald-Folgekamera Median366,37→368,04ms; Wald-Augen379,99→351,48ms. 2D-Zeichenaufrufe200,16→183,16, Waldinstanzen5394→5451, unverändert191 Batches. Der erste2D-Zeitwert30,67→66,71ms war auffällig. Die danach abwechselnd gemessenen A–B–B–A-Läufe ergeben alt31,69/42,50ms, neu36,03/37,44ms; die Bereiche überlappen und bestätigen keine Verdopplung. Schnee- und Flusszeiten steigen im ersten Vergleich ebenfalls; wegen variierender Software-Hostzeiten bleibt tatsächliche Geräteprofilierung nötig. Keine Android-FPS-Aussage.

## Android und Web

Lokaler Export bestanden: **Wolf-0.8.0-debug.apk**, 32.322.565 Bytes, SHA256 `9cc4592bce5cdce5aba3deb49a5e1570c1d3eff7851cf9698f13a2b2c1423be5`. Dauerhaft gespeicherte Datei `libfile_93150e4470788191ac1ef977bd5dd029`.

`apksigner verify --verbose --print-certs` bestätigt v2/v3-Signaturen und das Zertifikat `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c`, identisch mit den lokalen0.4–0.7-Builds. Manifest: `cloud.kosch.wolf`, versionCode8, minSdk24, targetSdk35, ausschließlich ARM64, keine Internetberechtigung. APK-ZIP-CRC und `zipalign -c -P16 4` bestanden. Web-Release exportiert und ZIP-CRC geprüft.

Ein fehlplatziertes lokales SDK-Unterverzeichnis wurde vor dem sauberen Export korrigiert. Der ADB-Daemon ist hier nicht gestartet; seine Verbindungsnotiz ist kein Geräte-Test. Kein tatsächlicher Telefon-/Emulatorstart.
