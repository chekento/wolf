# Validierung · Wolf 0.9.0

8. Oktober 2026; Godot 4.5.1.stable.official.f62fdbde1. Frisch gelesene Basis main `ea46e6f5f4f4d4dc868ee37bf1df3a395faa9789`, isolierter Checkout `wolf-next-09`. Fünf Agenten für Naturmissionen, Landschaftsdetails, Tiermodelle/Animation, Menüs und echte Missionsintegration; Root integrierte, prüfte, exportierte und signierte.

## Tatsächliche Spielprüfungen

**22 Suiten, 3257 bestandene Prüfungen**, Exit 0. Sauberer Editorimport; sämtliche vollständigen Schlusslogs ohne Script-/Enginefehler, Warnungen oder Ressourcenlecks. [Maschinelle Einzelwerte](validation-0.9.0.json).

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
| habitat_details | 40 | bestanden |
| animal_detail | 45 | bestanden |
| nature_journeys | 82 | bestanden |
| nature_journey_controls | 20 | bestanden |
| nature_journey_integration | 65 | bestanden |

Sechs Naturreisetypen ergeben 1536 regionale Angebote mit 3328 geordneten Zielen. Geprüft wurden alle kanonischen IDs und wirklichen Orte/Fährten/Schutzplätze, trockene Zielpunkte, begrenzte Caches, Annahme, frische geordnete Aktionen, nicht rückwirkendes Zählen, bekannte Fährten und Naturorte ohne doppelte Entdeckungsbelohnung, einmalige Abschlussbelohnung sowie Save-Migration 1–4 und beschädigte neue Felder. Die Hauptgeschichte mit acht Kapiteln und 21 Schritten, alte Rudelerinnerungen und Begegnungen bleiben getrennt erhalten.

Die echte Controllerintegration absolviert alle sechs lokalen Reiseabläufe über tatsächliche Menübuttons und Kontextaktionen. Sie prüft echte trockene Gebietsübergänge, Speicher-/Neustart außerhalb der Aufgabenregion, unverändertes Alter und persönliche Kartenziele. Rehbeobachtung benötigt dasselbe akzeptierte ruhige Individuum, wirkliche freie 3D-Sicht und vier aktive Sekunden. Rast zählt nur während tatsächlichen Liegens am ausgewählten Schutzplatz für drei aktive Sekunden. Menüs, Hintergrund, Bewegung, Sichtblockaden und falsche Tiere können keine Sekunden hinzufügen; ein verzögerter Tick ist auf 0,1 Sekunden begrenzt.

Die ausgewählte Aufgabenführung bestimmt Zieltext, Live-HUD, Kontextaktion und akzeptiertes Reh. Tests mit zwei gleichzeitig verschieden gebundenen Rehen sichern die getrennten Identitäten von Hauptgeschichte und Naturreise. Positions- und kanonische Kapitel-Fixtures wählen prüfbare Orte; dies ist kein behaupteter vollständiger menschlicher Spieldurchlauf.

## Landschaft und Tiermodelle

Alle 256 vollständigen Weltgenerationen stimmen weiterhin mit dem bisherigen Gesamtfingerabdruck `681fd8f2d02213bd55029cfbfc777b3038bd535b1cd6459c049545340cc4f283` überein. Alte Objekte, Fährten, Dekoration, Tierdaten, Höhen und Speicherkoordinaten bleiben erhalten. Die zusätzlichen Habitatpläne verändern ausschließlich Darstellungen und ersetzen höchstens 96 bestehende Unterflora-Instanzen in höchstens sechs räumlichen Detailbatches pro Gebiet. Kleine Gruppen meiden Wege, Wasser, Kollisionen und den unmittelbaren Höhlenraum; 2D und 3D teilen ihre Anker. Die 3D-Reichweite ist 26 Meter, ohne zusätzliche Schatten. Cachegrenzen: 16 Habitatpläne, 32 botanische Meshes.

Elf originale Motive umfassen Laub, Pilze, Totholz, Kiesel, Treibholz, Seggen, Moos, bereifte Zweige, Schneebüschel, Kräuter und Samenstände. Tatsächliche Meshformen, Vertexgrenzen, gemeinsamer 2D-Bake, echte 3D-Batches und unveränderte Instanzzahlen wurden geprüft. Die bisherigen schmalen Wege, weichen Gabeln, acht Bodenarten und der wegfreie Höhlenbereich bleiben erhalten.

Alle vier Tierarten behalten 21 geteilte Gelenkmeshes. Verfeinerte Schnauzen, Lippen, Nüstern, Ohren, Fellkonturen und kompakteres Rehgeweih bleiben unter 9000 Dreiecken pro Art. Neue Prüfungen messen echte Vertexgrenzen, Oberflächennormalen, geteilte Meshes, Pfotenkontakt und kontinuierliche Gras-/Trink-/Lausch-/Ruhe-/Heulübergänge. Die Schnauze erreicht niedrige Flora; Ruhebauch und Ohren bleiben über dem Boden. Bisherige Gang-, Gelände- und Stützpfotenprüfungen bestehen ebenfalls.

## Tatsächlich gerenderte Ansichten

Die Capture-Hilfe verwendet einen neuen Datenordner je Lauf, aktualisiert vor jedem Bild das reale HUD, fordert beim eingefrorenen 2D-Testspiel eine Neuzeichnung an und prüft den PNG-Schreibstatus. Frühere Aufnahmen zeigten einen alten Storycheckpoint beziehungsweise nach einem Gebietswechsel noch die vorherige Landschaft. Diese Bilder wurden vor der Veröffentlichung mit frischem Zustand und korrekter Neuzeichnung ersetzt. Die Aufnahmehilfe und Dokumentationsbilder sind aus den Spieleexports ausgeschlossen.

22 UI-/Spielaufnahmen wurden mit Linux/Xvfb/Mesa-llvmpipe im Hochformat 540×960 erstellt und angesehen. Die neuen Bilder zeigen die sechs auswählbaren Naturreisen und die aktive Aufgabe. Hauptgeschichte, echte Beobachtungsanzeige, Karten, Menüs, Wald, Schnee und Fluss wurden erneut gerendert. Zusätzliche identische Tier-Nahansichten vergleichen tatsächliches 0.8 und 0.9; sie verwenden originale Spielmeshes, keine Konzeptbilder. Zusätzlich wurden drei Habitat-Nahbilder an tatsächlichen Dekorationsankern geprüft: [Wald](habitat-woodland.png), [Wiese](habitat-meadow.png), [Moor](habitat-marsh.png). Einzig erwartete Godot-GL-Warnung: der Software-Renderer kann VSync nicht umschalten.

Ein erster Volltest mit wiederverwendeten Testdaten zeigte einen alten Begegnungsstand; dieselbe unveränderte UI-Suite bestand mit frischen Daten. Der vollständige Schlusslauf verwendet neue getrennte Datenverzeichnisse pro Suite. Die konkrete Herkunft der alten Fixturedateien blieb unbewiesen; daraus wurde kein Produktfehler abgeleitet.

Zwei während der parallelen Entwicklung gefundene Habitat-Typfehler wurden vor dem vollständigen sauberen Schlusslauf korrigiert. Frühere Läufe mit Scriptfehlern zählen nicht als bestandene Nachweise.

## Grafikvergleich

[Feste Rohdaten](render-profile-0.9.0.json): identische Szenen aus tatsächlichem 0.8 und 0.9, je 20 Warmup-/80 Messframes, 540×960, HUD verborgen, derselbe Linux-Software-Renderer. Exklusiver Messlauf ohne parallele schwere Tests oder Exporte.

| Szene | Median ms, 0.8 → 0.9 | Zeichenaufrufe | Primitive |
|---|---:|---:|---:|
| forest-2d | 35.12 → 31.61 | 183.16 → 183.16 | 47029 → 49559 |
| forest-eyes | 330.44 → 345.17 | 190.18 → 191.00 | 60510 → 63664 |
| forest-follow | 368.37 → 363.97 | 496.00 → 497.00 | 145249 → 154052 |
| snow-follow | 297.47 → 309.44 | 542.42 → 544.10 | 153214 → 160686 |
| river-follow | 144.16 → 150.59 | 199.74 → 200.40 | 62168 → 65281 |

Diese Software-Hostwerte sind keine Android-Bildraten. Zeitmessungen können durch die Hostumgebung schwanken; Draw- und Geometriewerte zeigen den tatsächlichen Umfang der Änderung. Reales Touchgefühl und Geräteperformance bleiben offen.

## Android und Web

Lokaler Export bestanden: **Wolf-0.9.0-debug.apk**, 32,351,567 Bytes, SHA256 `9c3799e55b8e95ccc352ebe5afb43b545a86760c3960ea1c26d313dec8d6dda2`. Dauerhaft gespeichert als `libfile_be640555e6548191b155d7bd050bfb48`.

`apksigner verify --verbose --print-certs` bestätigt v2/v3 und Zertifikat `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c`, identisch mit den lokalen 0.4–0.8-Builds. Manifest: `cloud.kosch.wolf`, versionCode 9, minSdk 24, targetSdk 35, ausschließlich ARM64, keine Internetberechtigung. APK-ZIP-CRC und `zipalign -c -P16 4` bestanden. Web-Release exportiert und ZIP-CRC geprüft; das Web-ZIP bleibt lokal/CI.

**Kein tatsächlicher Android-Geräte- oder Emulatorstart.** Die 3D-Grafik bleibt stilisiert. Vollständiger Lebenszyklus, Partnersuche, eigener Nachwuchs und kooperative Jagd sind noch nicht umgesetzt. Offline-Spiel, allmähliches Altern und alte Spielstände bleiben erhalten.
