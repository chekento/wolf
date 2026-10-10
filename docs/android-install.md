# Android-Installation · 0.13.0

**Hinweis:** Der GitHub-Actions-Build 0.13.0 nutzt einen temporären Signierschlüssel und ist nicht direkt aktualisierungskompatibel mit der lokal signierten 0.10.0. Die bisherige App keinesfalls ohne verlässliche Sicherung deinstallieren.


Die APK unterstützt Android 7 oder neuer und ARM64-Geräte. Sie spielt offline und benötigt keine Internetberechtigung. Android muss die Installation aus der verwendeten Downloadquelle erlauben.

**Die lokal signierte 0.10.0 verwendet denselben vorhandenen Signierschlüssel wie 0.4.0 bis 0.9.0.** GitHub Actions baut 0.13.0 jedoch mit einem separaten temporären Schlüssel. Deshalb ist der neue CI-Build nicht direkt über die lokale 0.10.0 installierbar; eine Deinstallation kann den Spielstand löschen.

## Vorhandene Installation

Der frühere lokale Debug-Signierschlüssel für 0.3.0 war in der wiederhergestellten Entwicklungsumgebung nicht mehr verfügbar und konnte auch unter den gespeicherten Dateien nicht gefunden werden. 0.4.0 wird mit einem neuen, dauerhaft gesicherten Debug-Schlüssel signiert. Android lehnt deshalb ein direktes Update über 0.3.0 ab. **Eine Deinstallation löscht normalerweise den lokalen Spielstand. Nicht ohne vorherige Sicherung deinstallieren.**

Die Spielstanddatei selbst bleibt kompatibel: `wolf_save_v1.json` wird aus älteren Formaten ins Format 4 übernommen; Gebiets-IDs, Alter, Bindung, Fährten und Storyfortschritt bleiben erhalten. Dateikompatibilität ersetzt nicht die fehlende Signaturkontinuität.

## Sicherung eines Debug-Builds mit ADB

Ein Computer mit Android Platform Tools und freigegebenem USB-Debugging kann die App-Daten einer Debug-Version sichern. Zuerst im Spiel speichern und die App schließen. Die folgenden Terminalbefehle sichern den gesamten `files`-Ordner:

```sh
adb devices
adb shell am force-stop cloud.kosch.wolf
adb exec-out run-as cloud.kosch.wolf tar -cf - files > wolf-save-backup.tar
tar -tf wolf-save-backup.tar
```

**Erst fortfahren, wenn das Archiv vorhanden ist und die gespeicherte JSON-Datei enthält.** Danach die alte App entfernen, die neue APK installieren und die App noch nicht öffnen:

```sh
adb uninstall cloud.kosch.wolf
adb install Wolf-0.13.0-debug.apk
adb shell run-as cloud.kosch.wolf tar -xf - < wolf-save-backup.tar
```

Nun Wolf starten. Das Backup behalten, bis der alte Fortschritt sichtbar ist. Diese ADB-Wiederherstellung konnte hier mangels angeschlossenem Android-Gerät nicht praktisch getestet werden; die Save-Migration wurde in Godot geprüft. Bei fehlendem `run-as`-Zugriff oder unsicherem Backup die bisherige App behalten.

Neuer lokaler Zertifikat-Fingerabdruck (SHA-256):

`08b255aa8a68369a40d089d7a5bb0e0c5e058d6ddb358f9ef449630a81bd3f1c`

GitHub-Actions-Builds verwenden einen temporären Debug-Schlüssel und sind nicht automatisch mit der lokal bereitgestellten APK aktualisierungskompatibel.
