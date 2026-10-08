# Prüfbericht · Wolf 0.4.0

Geprüft am 8. Oktober 2026 mit Godot **4.5.1.stable.f62fdbde1**. Quellstand: Pfade der Wildnis, Spielstandformat 4.

## Automatisierte Prüfung

| Suite | Bestandene Prüfungen | Ergebnis |
|---|---:|---|
| Import | — | Exit 0, keine Parser-/Enginefehler |
| `tests/smoke.gd` | 2220 | 0 Fehler |
| `tests/gameplay_expansion.gd` | 138 | 0 Fehler |
| `tests/graphics_expansion.gd` | 62 | 0 Fehler |
| `tests/ui_expansion.gd` | 32 | 0 Fehler |

Insgesamt **2452 bestandene Prüfungen**. Alle vier Prozesse enden mit Exit 0; ihre vollständigen Logs enthalten keine `SCRIPT ERROR`, `ERROR`, fehlgeschlagenen Prüfungen oder ObjectDB-Leaks.

Die Gameplay-Prüfung kontrolliert 256 Gebiete, 960 gerichtete gegenseitige Nachbarschaften, tatsächliche Zugänge zu 1536 Naturorten, 768 Nahrungsstellen, 512 Ruheplätzen, 256 Trinkzugängen, 256 Wegsteinen und 6912 Fährtenspuren. Sie prüft natürliche Story-Freigaben, Begegnungsbaselines und einmalige Belohnungen, Trinken-vor-Ruhen, allmähliches Alter/Jahreszeiten sowie alte und beschädigte Spielstände.

Grafikprüfungen decken Anatomie, weiche Gelenkbewegungen, Wachstum, geteilte Modelle, Folgekamera, Hindernisabstand, Terrainhöhe, Rückkehr zum exakten Wolfsblick und deaktivierten Schattenwurf des Bodens ab. UI-Prüfungen verwenden tatsächliche Menübuttons und Controllerbewegung für Annahme/Erfüllung/Belohnung; zusätzlich Hintergrundpause, Android-Zurück, Wasserwegführung, Ruhen neben Familie, Karteninput, Suchnebel, räumliche Kollision und Tiercache-Verdrängung/-Neustart/-Beschädigung.

## Sichtprüfung

13 echte Aufnahmen mit OpenGL Compatibility und Mesa llvmpipe: Einstieg, Draufsicht, Wolfsblick, Welt-/Gebietskarte, Geschichte, Hauptmenü, Begegnung, Familie, Schnee, Fluss, 3D-Rudel und Folgekamera. Zusätzlich wurden Fluss/Brücke und Nachthimmel kontrolliert. Die starke Boden-Selbstverschattung wurde dabei erkannt und korrigiert. Der abschließende Aufnahmeprozess beendet sich ohne Parser-/Enginefehler oder Leaks; die Softwareanzeige meldet lediglich fehlende VSync-Umschaltunterstützung.

## Android-APK

- Datei: `Wolf-0.4.0-debug.apk`, **32.223.611 Bytes**.
- SHA-256: `1bf4056c18ca55c4532a4e95625e57f5625e15f8454700966a457d7b77e18c07`.
- Package: `cloud.kosch.wolf`, versionCode 4, versionName 0.4.0.
- Ausschließlich ARM64, minSdk 24, targetSdk 35, keine Internetberechtigung.
- Godot-Android-Export Exit 0; `apksigner verify` bestätigt APK-Signaturen v2/v3. ZIP-CRC aller Einträge geprüft; Manifest und ABI mit Android Build Tools geprüft.
- Zertifikat-SHA-256: `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c`.

APK und neuer Debug-Schlüssel wurden dauerhaft gesichert. Der alte Debug-Schlüssel war nicht verfügbar; ein direktes Update über die ältere lokale APK ist deshalb blockiert. [Installations- und Sicherungshinweise](android-install.md).

Kein physisches Android-Gerät oder Emulator angeschlossen: tatsächlicher Android-Start, Geräteperformance, Touchgefühl und ADB-Save-Wiederherstellung sind noch nicht praktisch geprüft. Der Web-Export wird vom Workflow erstellt; diese Prüfung umfasst keinen Browserlauf.
