# 🐺 Wolf · Wildnis & Rudel

Ein niedliches, naturbezogenes Wolfspiel in **Godot 4.5.1**. Die erste spielbare Version verbindet eine echte **2D-Draufsicht mit freier Bewegung in alle Richtungen** mit einer **überall zuschaltbaren 3D-Sicht aus den Augen des Wolfs**.

Du beginnst als Jungwolf nahe deiner Familie. Erkunde vier zusammenhängende Gebiete, lerne Fährten kennen und finde Wasser, Nahrung und geschützte Ruheplätze. Kein menschliches Verhalten, keine Waffen, keine grafische Gewalt.

**Stand: 0.1.0 · spielbarer Prototyp.** Noch kein vollständiger Lebenszyklus-Simulator. Tiere und Landschaft verwenden bewusst einfache, eigenständige Grafik. Erweiterte Rudel-KI, Jagd, Jahreszeiten, Animationen und langsames körperliches Wachstum sind weitere Entwicklungsstufen.

## Spielen

- **Android:** APK aus dem [Build-Artefakt](https://github.com/chekento/wolf/actions/workflows/build.yml) herunterladen, ZIP entpacken und `Wolf-0.1.0-debug.apk` installieren. Android 7+; ARM64. Der Build benötigt keine Internetberechtigung.
- **Computer:** Repository herunterladen, `project.godot` mit Godot **4.5.1** öffnen und F6/F5 starten. Das Spiel verwendet den Compatibility-Renderer.
- **Browser:** Das Web-Artefakt enthält einen exportierten Browser-Build. Entpacken und mit einem lokalen HTTP-Server öffnen, z. B. `python3 -m http.server 8000` im Web-Ordner. `index.html` nicht direkt als lokale Datei öffnen.

Die APK wird zusätzlich direkt im zugehörigen Chat als Download bereitgestellt. CI-Artefakte stehen nach erfolgreichem Workflow zur Verfügung und können eine GitHub-Anmeldung erfordern.

## Ansichten

| 2D-Draufsicht | 3D-Wolfsblick |
|---|---|
| ![Echte Spielaufnahme aus der Draufsicht](docs/top-down.png) | ![Echte Spielaufnahme aus dem Wolfsblick](docs/wolfs-eye.png) |

Dies sind **Aufnahmen des laufenden Spiels**, keine Konzeptbilder. Beide Ansichten verwenden dieselben Gebiets-, Objekt-, Tier- und Fährtendaten. Ein Baum wechselt beim Umschalten nicht den Ort. Der Wolfsblick beginnt an derselben Position und mit derselben Blickrichtung.

## Gebiete und Spielumfang

| Gebiet | Verbindungen | Charakter |
|---|---|---|
| Rudelhöhle | Norden: Bergwiese · Osten: Kiefernwald | Sicherer Anfang mit zwei erwachsenen Rudelwölfen |
| Kiefernwald | Westen: Rudelhöhle · Norden: Flussauen | Dichte Bäume und Fährten |
| Flussauen | Süden: Kiefernwald · Westen: Bergwiese | Fluss mit passierbarer Furt |
| Bergwiese | Süden: Rudelhöhle · Osten: Flussauen | Offeneres Gelände und Aussicht |

Die Karten bilden einen zusammenhängenden 2×2-Verbund. Folge den breiten Wegen zu den offenen Kartenrändern. Gebietswechsel funktionieren in beiden Ansichten, ohne Teleportmenü.

- Sieben Erlebnisse: Wasser finden, drei Spuren lesen, Rudelantwort hören, alle Gebiete erkunden, Reh und Hase beobachten, vier Wegsteine entdecken und an der Höhle ruhen.
- Schnüffeln zeigt Fährten für 18 Sekunden; untersuchte Spuren bleiben markiert.
- Tiere bewegen sich und fliehen bei Annäherung. Beobachtung im Wolfsblick benötigt Abstand, Blickkontakt und eine freie Sichtlinie.
- Nahrung, Wasser, Kraft und Rudelbindung; langsamer Verbrauch, Erholung und optionaler Trab.
- Naturtagebuch und lokale Spielstände. Automatisches Speichern alle 20 Sekunden, bei Gebietswechseln und beim Wechsel in den Hintergrund.
- Hochkant-Oberfläche, Touch-Steuerung und scrollbare, pausierende Menüs.

## Steuerung

| Aktion | Android / Touch | Tastatur / Maus |
|---|---|---|
| Bewegen | Stick unten links | WASD oder Pfeiltasten |
| Umsehen in 3D | Über die Landschaft wischen | Linke Maustaste ziehen; alternativ I/J/K/L |
| Ansicht wechseln | 3D / 2D-Taste | V |
| Schnüffeln | Schnüffeln | F |
| Spuren / Wasser / Nahrung / Wegstein / Tier untersuchen | Untersuchen | E |
| Heulen | Heulen | H |
| Ruhen nahe einer Höhle | Ruhen | R |
| Schneller laufen | Trab umschalten | Umschalt halten |
| Gebietskarte | Karte | M |
| Menü / zurück | ☰ / × | Escape |

Die Landschaftswischfläche liegt zwischen Kopfzeile und Steuerung, damit Kamera und Stick getrennt bedienbar bleiben. Im Wolfsblick ist die Bewegungsrichtung relativ zur Kamera.

## Warum Godot?

Godot vereint eine eigene 2D-Engine und echte 3D-Szenen in einem Projekt, bietet Android- und Web-Exporte und benötigt für diesen Prototyp keine zusätzlichen Bibliotheken. Die Compatibility-Darstellung hält den technischen Einstieg klein. Eine zentrale Weltdefinition verhindert, dass 2D und 3D auseinanderlaufen.

Die 2D-Ansicht ist ein `Node2D` mit eigenständiger Zeichnung; der 3D-Modus erzeugt dieselbe Karte als `Node3D` mit `Camera3D` in Wolfshöhe. Kein Bildfilter und keine vorgerenderte Panoramaansicht.

## Entwickeln und prüfen

```sh
godot --headless --editor --import --quit
godot --headless --script tests/smoke.gd
godot --path .
```

Der Smoke-Test prüft reproduzierbare Karten, gegenseitige Übergänge, sichere Ankunftspunkte, Speichern/Laden, Interaktionen, Sichtlinien, Kameraausrichtung, die Flussfurt und Menüwechsel. Tests verwenden eine separate Spielstanddatei, damit der echte Spielstand unberührt bleibt.

```sh
mkdir -p builds/web
godot --headless --export-debug Android builds/Wolf-0.1.0-debug.apk
godot --headless --export-release Web builds/web/index.html
```

Für Android: passende Godot-Exportvorlagen, JDK 17, Android SDK mit `platform-tools`, `build-tools;35.0.1` und `platforms;android-35`. Die Pfade in Godots Editor-Einstellungen unter **Export → Android** eintragen. Godot erstellt einen lokalen Debug-Schlüssel; der private Schlüssel wird nicht ins Repository übernommen. Diese APK ist zum Testen, nicht als Play-Store-Release signiert.

## Dateien

- `scripts/world_data.gd`: reproduzierbare Karten und Verbindungen
- `scripts/state.gd`: Bedürfnisse, Fortschritt, Tagebuch und Spielstände
- `scripts/main.gd`: Spielablauf, Interaktionen und Menüs
- `scripts/map_view.gd`: 2D-Draufsicht
- `scripts/world_view.gd`: echte 3D-Welt und Kamera
- `scripts/touch_stick.gd`: Touch-/Maus-Stick
- `tests/smoke.gd`: Gameplay-Prüfungen

## Grenzen dieser Version

Noch keine Prüfung auf einem physischen Android-Gerät. Die APK wurde gebaut, signiert und technisch überprüft. Die Darstellung wurde unter Linux mit einem Software-Renderer geprüft. Die Systemwerte und das Verhalten sind spielerisch vereinfacht; Rudel-KI und Tageszeiten stehen am Anfang. Das Alter wird noch nicht als körperliches Wachstum simuliert. Für längere Spielverläufe folgen weitere Begegnungen, Szenen, Gebiete und Ziele.

Idee und Ausrichtung: KoSch / Kolja Werner Schumann. Inhaltlich angelehnt an den Wolf-Simulator: natürliches Rudelleben, nachvollziehbare Entwicklung, Entdeckungen und Geschichte aus Sicht eines Wolfs.
