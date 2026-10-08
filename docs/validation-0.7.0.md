# Prüfbericht · Wolf 0.7.0

Geprüft am 8. Oktober 2026 mit Godot 4.5.1 auf der Grundlage des unveränderten main `2e70c5808507f9c47a3e1bbf7124a0ba9835f830`. Import und zwölf eigenständige Suiten bestanden. Die vollständig ausgewerteten finalen Logs enthalten keine Script-/Enginefehler, Warnungen, Fehlprüfungen oder gemeldeten Instanzlecks. Ein anfänglich fehlender expliziter Datentyp im neuen Atlas-Prüfharness wurde korrigiert; die betroffene Suite wurde danach vollständig sauber wiederholt.

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
| locomotion_expansion | 40 |
| living_world | 58 |
| landscape_expansion | 11 |
| atlas_observation | 25 |
| **Gesamt** | **2750** |

Die Prüfungen verwenden eigene Spielstanddateien; der Gesamtlauf hatte außerdem ein getrenntes XDG-Userdata-Verzeichnis. Reale Controllerwege, alle 256 Regionen, 1280 Reh-Gruppenanker, Ruhe-/Spielphasen, Alarmende, Save4 und wiederholbare Aufgaben sind geprüft. Die neuen UI-Prüfungen nutzen tatsächliche Kartenbuttons, Kartenpositionen, freie Sicht, Beobachtungsidentität und Elternnähe. Das testet Spielregeln und Godot-Touchevents, keine physische Telefonoberfläche.

Die signierte lokale APK enthält `cloud.kosch.wolf`, VersionCode 7, VersionName 0.7.0, minSdk 24, targetSdk 35 und ausschließlich ARM64. Keine Internetberechtigung. APK-Signaturschemata v2/v3, ZIP-CRC und 16-KiB-ZIP-Ausrichtung sind geprüft. Zertifikat-SHA256 `08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c` stimmt mit den lokalen Builds 0.4 bis 0.6 überein.

APK: `Wolf-0.7.0-debug.apk`, 32.285.379 Bytes, SHA-256 `389028d826585e08218b0db6d9da6d0fd179c818a56e1b39d55be4ecd5c3466d`. Die Datei ist dauerhaft gesichert. Android- und Web-Exportlogs sind sauber.

Die erneuerten Menüs, Karten und Beobachtungsanzeigen wurden im laufenden 540×960-Godot-Spiel tatsächlich angesehen. Die Aufnahme lief ohne Script-/Enginefehler oder Leaks; einzige Warnung ist die fehlende VSync-Umschaltung der Softwareanzeige. Zusätzlich wurden 23 Grafikdetailbilder aufgenommen und repräsentative Landschaften und Tierhaltungen geprüft.

Der [Grafikvergleich](render-profile-0.7.0.json) verwendet denselben Mesa-llvmpipe-Renderer und je 20 Aufwärm-/80 Messbilder. Wald-Draufsicht: Median 22,26 → 19,10 ms, Zeichenaufrufe 408,6 → 200,2. Wald-Folgekamera: 211,86 → 217,44 ms; Schnee 177,50 → 177,60 ms; Fluss 90,50 → 91,00 ms. Im Wald steigen Instanzen 5359 → 5394 und gesamte räumliche Batches 190 → 191. Das ist ein Regressionsvergleich, keine Android-Bildratenmessung.

Kein physisches Android-Gerät oder Emulator stand zur Verfügung. Geräte-Start, Touchgefühl und Geräteperformance bleiben offen. Die Grafik bleibt stilisiert; der vollständige Lebenszyklus mit Partnersuche, eigenem Nachwuchs und kooperativer Jagd ist weiterhin nicht enthalten.
