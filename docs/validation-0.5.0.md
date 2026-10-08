# Prüfbericht · Wolf 0.5.0

Geprüft am 8. Oktober 2026 mit Godot **4.5.1.stable.f62fdbde1**. Quellstand: Auf leisen Pfoten, Spielstandformat 4.

## Automatisierte Prüfung

| Suite | Bestandene Prüfungen | Ergebnis |
|---|---:|---|
| Import | — | Exit 0, keine Parser-/Enginefehler |
| `tests/smoke.gd` | 2220 | 0 Fehler |
| `tests/gameplay_expansion.gd` | 138 | 0 Fehler |
| `tests/graphics_expansion.gd` | 75 | 0 Fehler |
| `tests/ui_expansion.gd` | 52 | 0 Fehler |
| `tests/animal_behavior.gd` | 18 | 0 Fehler |

Insgesamt **2503 bestandene Prüfungen**. Alle fünf Prozesse enden mit Exit 0; die vollständigen Logs enthalten keine `SCRIPT ERROR`, `ERROR`, Warnungen, fehlgeschlagenen Prüfungen oder ObjectDB-Leaks. [Maschinenlesbare Ergebnisse](validation-0.5.0.json).

Die bestehende Weltprüfung kontrolliert weiterhin 256 Gebiete, 960 gerichtete gegenseitige Nachbarschaften, tatsächliche Zugänge zu 1536 Naturorten, 768 Nahrungsstellen, 512 Ruheplätzen, 256 Trinkzugängen, 256 Wegsteinen und 6912 Fährtenspuren. Alte und beschädigte Saves, natürliche Story-Freigaben, echte Begegnungshandlungen, einmalige Belohnungen und langsames Alter/Jahreszeiten bleiben geprüft.

Neu geprüft: tatsächliche Tierwege um große Felsen und über vorhandene Flussbrücken, sichere begrenzte Bewegung ohne Aufholteleport, Elternwolf auf der falschen Seite eines nahen Felsens, Heimkehr vor Nacht-Ruhe, sicherer Begleitspawn und gespeicherte HUD-Vorliebe samt Altsave-Default. Der Navigationsgraph wird regional geteilt und erst für eine blockierte Wolfs-/längere Route aufgebaut; kleine Wildtiere nutzen zunächst lokales Ausweichen. Einmaliger 80×80-Testaufbau im Agententest: 206 ms. Dies ist keine Android-Messung.

Grafikchecks umfassen Distanzgeometrie, wiederverwendete saisonale 2D-Bodenflora, begrenzte 3D-Batches mit Instanzfarben, biomeigene Naturortformen, Anatomie, weiche Gelenkbewegungen, Wachstum, Folgekamera und Terrain-/Hindernisabstand. Echte Controller- und Menüabläufe prüfen den sichtbaren Einstieg, kompaktes HUD, nächste frische Fährte, manuelles Kartenziel, zwei unabhängige Touchpointer, ignorierte emulierte Mausduplikate, freie Kamerapointer nach Ansichtwechsel und Trinken vor entfernter Tierbeobachtung.

Die Audio-/Menüabläufe wurden zusätzlich **fünfmal hintereinander** mit aktivem Dummy-Playback ausgeführt: Ton aus/an über echte Einstellungen, acht schnelle Menüwechsel, App-Hintergrund/-Rückkehr und vollständige Ressourcenfreigabe. Alle fünf Logs waren sauber. Der frühere 0.4-Actions-Lauf scheiterte nach erfolgreichen Grafikchecks an einer intermittierenden Audio-Freigabewarnung; 0.5 stoppt Menü-/Hintergrundplaybacks und startet Naturklang erst draußen. Reine Grafikchecks verwenden keinen Ton; die Audioabläufe bleiben ausdrücklich in der UI-Suite geprüft. Der Workflow prüft weiterhin Fehler und Leaks strikt.

## Sichtprüfung und Rendering

13 neue echte Aufnahmen: Einstieg, Draufsicht, Wolfsblick, Welt-/Gebietskarte, Geschichte, Hauptmenü, Begegnung, Familie, Schnee, Fluss, 3D-Rudel und Folgekamera. Beim ersten Bildlauf waren kleine Menü-/Footer-Tasten durch gekappte Text-Mindestbreiten leer; vor Export korrigiert und alle Bilder erneut erzeugt. Bei der langen Aufnahmefolge war einmal ein Teil des Begegnungstitels im Softwarebild abgeschnitten; eine direkte neue GL-Aufnahme und Layoutprüfung bestätigen den vollständigen Titel bei 410 Pixeln verfügbarer Breite und 255 Pixeln Textbreite. Diese direkte Aufnahme wird verwendet; ein Gerätevergleich dieses intermittierenden Bildartefakts steht aus. Zusätzlich prüfte der Grafikagent alle vier Tierarten in fünf Posen sowie Küste, Moor und Pilze in 27 Detailbildern. Beide finalen Render-/Aufnahmeläufe endeten ohne Script-/Enginefehler oder Leaks; die Softwareanzeige meldet lediglich fehlende VSync-Umschaltunterstützung.

Fester Vergleich: Mesa llvmpipe, Godot OpenGL Compatibility, 540×960, 2×MSAA in 3D, Oberfläche verborgen, pro Szene 20 Aufwärm- und 80 Messbilder. Alte Grafik vor Optimierung versus finaler integrierter Stand; Tierzahl und Weltumfang bleiben erhalten. Mittelwerte beschreiben diese Softwareanzeige und **keine Android-Gerätebildrate**.

| Szene | Mittlere Bildzeit vorher → nachher | Drawcalls vorher → nachher | Primitives vorher → nachher |
|---|---:|---:|---:|
| Wald · Draufsicht | 39.3 → 23.7 ms | 1634 → 408 | 94202 → 49007 |
| Wald · Wolfsblick | 273.3 → 202.1 ms | 452 → 228 | 656743 → 69565 |
| Wald · Folgekamera | 293.1 → 221.4 ms | 666 → 403 | 817726 → 130660 |
| Schnee · Folgekamera | 270.6 → 181.9 ms | 604 → 456 | 1301184 → 148825 |
| Fluss · Folgekamera | 117.9 → 92.0 ms | 294 → 172 | 262519 → 54005 |

Die räumlichen Wald-MultiMeshes sinken von 589 auf 190. Eine Zusammenfassung allein senkte die Zeichenaufrufe, erhöhte aber die gemeinsam sichtbare Dreieckslast; native Distanzgeometrie korrigiert das. `Performance.TIME_PROCESS` wurde nicht als isolierte CPU-Messung verwendet, weil dessen Monitorfenster noch Initialisierung erfasste. [Messdaten](render-profile-0.5.0.json); Wiederholung mit `tools/profile_rendering.gd` und sichtbarem Renderer wie im README.

## Android-APK

- Datei: `Wolf-0.5.0-debug.apk`, **32.244.252 Bytes**.
- SHA-256: `aad54966e4a815bf97e927a134170cd047de853763529034189f95ec6080b9a7`.
- Package: `cloud.kosch.wolf`, versionCode 5, versionName 0.5.0.
- Ausschließlich ARM64, minSdk 24, targetSdk 35, keine Internetberechtigung.
- Godot-Android-Export Exit 0; `apksigner verify` bestätigt APK-Signaturen v2/v3. ZIP-CRC aller Einträge, Manifest, ABI, 16-KiB-ZIP-Ausrichtung und 16-KiB-ELF-Ladesegmente beider nativen Bibliotheken geprüft.
- Zertifikat-SHA-256: `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c`.

Die APK ist dauerhaft als Download gesichert. Sie verwendet denselben lokalen Debug-Schlüssel wie 0.4.0 und kann diese aktualisieren. Ältere lokale Builds bis 0.3.0 hatten einen anderen, nicht mehr verfügbaren Schlüssel; [Installations- und Sicherungshinweise](android-install.md).

Kein physisches Android-Gerät oder Emulator angeschlossen: tatsächlicher Android-Start, Geräteperformance, Touchgefühl und ADB-Save-Wiederherstellung sind weiter nicht praktisch geprüft. Die automatisierten Touchprüfungen verwenden echte Godot-InputEvents im Controller. Der Web-Export wird vom Workflow erstellt; diese Prüfung umfasst keinen Browserlauf.
