# Prüfbericht · Wolf 0.6.0

Geprüft am 8. Oktober 2026 mit Godot 4.5.1. Import und neun eigenständige Suiten liefen vollständig durch. Die Logs enthalten keine Script-/Enginefehler, Warnungen, fehlgeschlagenen Prüfungen oder gemeldeten Instanzlecks.

| Suite | Bestandene Prüfungen |
|---|---:|
| smoke | 2220 |
| gameplay_expansion | 138 |
| graphics_expansion | 75 |
| ui_expansion | 52 |
| animal_behavior | 18 |
| atlas_expansion | 25 |
| ecology_expansion | 63 |
| encounter_controls | 25 |
| locomotion_expansion | 36 |
| **Gesamt** | **2652** |

Der Android-Debugexport wurde anschließend signiert und geprüft: `cloud.kosch.wolf`, VersionCode 6, VersionName 0.6.0, minSdk 24, targetSdk 35, nur `arm64-v8a`, ohne angeforderte Internetberechtigung. APK-Signaturschemata v2 und v3, ZIP-Integrität und 16-KiB-ZIP-Ausrichtung bestanden. Zertifikat-SHA256: `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c`.

APK: `Wolf-0.6.0-debug.apk`, 32.268.995 Bytes, SHA-256 `a726a697d37ca92603a83ee8f626ea4019f2a7befaadbc3b99d7d73a7cf4ff33`.

Die Grafikprofile liefen in fünf festen 540×960-Szenen mit Mesa llvmpipe, 20 Aufwärm- und 80 Messbildern. Sie dienen als Regressionsvergleich, nicht als Aussage über Android-Bildrate. Ein physisches Android-Gerät oder Emulator war nicht verfügbar; Start, Touchgefühl und Leistung auf echter Hardware sind daher nicht bestätigt.
