# 🐺 Wolf · Wildnis & Rudel

**0.4.0 · Pfade der Wildnis** — ein offline spielbares Wolfspiel für Android in Godot 4.5.1. Du beginnst als 16 Wochen alter Jungwolf bei Mutter, Vater und zwei Geschwistern. Gerüche, Fährten, vorsichtige Beobachtungen und gemeinsame Wege erschließen deine Heimat.

Frei begehbare **2D-Draufsicht**, **echter 3D-Wolfsblick** und eine neue **3D-Folgekamera** teilen Landschaften, Tierpositionen und Spuren. Eigene Comic-Grafik und Tiermodelle verbinden sich mit friedlichen Rudelgeschichten und langsamer natürlicher Entwicklung.

## Spielen & Download

- **Android 7+ / ARM64:** Die geprüfte, signierte `Wolf-0.4.0-debug.apk` wird direkt im Chat bereitgestellt. [GitHub Actions](https://github.com/chekento/wolf/actions/workflows/build.yml) erstellt zusätzlich Android- und Web-Artefakte. Debug-Builds mit lokalem Spielstand und ohne Internetberechtigung.
- **Computer:** `project.godot` mit Godot **4.5.1** öffnen und starten.
- **Browser:** Web-Artefakt entpacken, im Web-Ordner `python3 -m http.server 8000` starten und `http://localhost:8000` öffnen.

**Installation gegenüber 0.3.0:** Der frühere lokale Debug-Schlüssel war nicht mehr verfügbar. Die im Chat ausgegebene 0.4.0 verwendet einen neuen, dauerhaft gesicherten Schlüssel. Android erlaubt damit kein direktes Update über 0.3.0. Einen vorhandenen Spielstand vor jeder Deinstallation sichern; siehe [Installationshinweise](docs/android-install.md). Spätere lokal ausgelieferte Builds sollen denselben neuen Schlüssel verwenden. Actions-Builds erhalten einen eigenen temporären Debug-Schlüssel.

## Echte Spielaufnahmen

| Draufsicht | Neue Folgekamera |
|---|---|
| ![Draufsicht](docs/top-down.png) | ![Folgekamera](docs/follow-camera.png) |

| Menü | Wildnisatlas |
|---|---|
| ![Menü](docs/menu.png) | ![Wildnisatlas](docs/world-map.png) |

Die Bilder zeigen das laufende Godot-Spiel unter Linux mit Software-Rendering.

## 256 verbundene Gebiete

Die Welt umfasst **16×16 Gebiete** mit jeweils 3200×3200 Welteinheiten: **vierfache Fläche gegenüber 0.3.0**, sechzehnfache gegenüber 0.2.0. Die bisherigen 64 Gebiets-IDs und lokalen Koordinaten bleiben erhalten; die ursprüngliche Heimat liegt weiter in der Mitte.

**1536 benannte Naturorte**, sechs pro Gebiet, liegen in Wald, Schnee, Bergen, Küste, Moor und Wiesen. Jedes Gebiet enthält Nahrung, Wasser und geschützte Ruheplätze. Wegeprüfungen kontrollieren tatsächliche Zugänge zu Naturorten, Ressourcen, Wegsteinen und Fährten. Fünfzehn Wildtiere pro Gebiet und die Familie in der Heimat bewegen sich durch die Landschaft.

Der **Wildnisatlas** zeigt Landschaftssymbole, Höhenlinien, Gewässer, Kompass und Maßstab. Ziehen, Aufziehen und Gebietssuche erleichtern die Orientierung. Die Detailkarte zeigt tatsächliche Vegetation, Wasser, Höhlen, Naturorte und Tierpositionen. Antippen setzt ein **Duftziel**; Route und Kompass führen zu den nächsten Übergängen. Unerkundete Gebiete bleiben gedämpft. Kein Karten-Teleport.

## Rudelleben & Erlebnisse

- **18 zusammenhängende Kapitel** mit natürlichen Entscheidungen und Freigaben durch tatsächliche Erlebnisse.
- **40 Erlebnisse** und wiederholbare regionale **Wildnisbegegnungen**: neue Fährten, Naturorte, eigene Wege, Nachbargebiete, Tierbeobachtung, Trinken und Ruhen oder vertraute Rudelrufe. Alte Handlungen erfüllen keine neu angenommene Aufgabe. Belohnungen lassen sich einmal abholen.
- Fünf Tagesroutinen für Mutter, Vater und Geschwister. Begrüßen, Heulen, Erkunden, Spielen und Ruhen stärken die Bindung. Ab Bindung 48 kann die Mutter dich über Gebietsgrenzen begleiten.
- Reh-, Hasen- und Fuchsspuren mit unterscheidbaren Trittsiegeln. Schnüffeln macht sie sichtbar; eine geübte Nase verlängert die Anzeige.
- Tiere wandern, lauschen und fliehen bei zu naher Annäherung. Beobachten in 3D benötigt Abstand, Blickrichtung und freie Sicht.
- Nahrung, Wasser, Kraft, Rudelbindung, Duftmarken und Naturtagebuch mit Filtern.
- **Ein Spieltag dauert 60 Minuten aktiver Spielzeit.** Menüs und App-Hintergrund pausieren die Entwicklung. Ruhen überspringt keine Tage. Alter und Körpergröße wachsen allmählich; Jahreszeiten wechseln nach jeweils 30 Spieltagen.

## Grafik & Animation

Eigene 3D-Tiermodelle unterscheiden Wolf, Reh, Hase und Fuchs durch Körperbau, Schnauze, Ohren, Fell und Gliedmaßen. Bewegliche Knie, Kopf, Ohren, Kiefer und Schwanz verbinden sich mit weich überblendeten Lauf-, Ruhe-, Spiel-, Schnüffel- und Heulposen. Die Folgekamera zeigt den eigenen wachsenden Wolf und verkürzt ihren Abstand bei Hindernissen.

Gräser, Farne, Schilf, Blumen, liegendes Holz und zusätzliche Naturortmodelle verdichten die Landschaft. Jahreszeitliche Farben, bewegtes Wasser, eigener Himmel mit Wolken, Mond und Sternen sowie mehrschichtiger Regen, Schnee und Nebel ergänzen die Wildnis. Die Draufsicht verwendet Comic-Laufsequenzen, Aktionsposen und Bodenschatten.

Illustrierte Menüs, Familienroutinen, Begegnungsfortschritt, Karten und Tierwissen sind scroll- und touchfähig. Naturklang, Wetter, ruhige Animationen, weiche 3D-Kanten und Kartenansicht sind einstellbar. [Grafikherkunft und Schriftlizenz](docs/art-assets.md).

## Steuerung

| Aktion | Android | Computer |
|---|---|---|
| Bewegen | Pfotenstick | WASD / Pfeile |
| 3D umsehen | Landschaft wischen | Maus ziehen / I J K L |
| Ansicht wechseln | 3D / 2D | V |
| 3D-Kamera wechseln | Wolfsblick / Folgekamera | Schaltfläche |
| Schnüffeln | Schnüffeln | F |
| Spur, Wasser, Tier, Naturort | Kontextaktion | E |
| Heulen | Heulen | H |
| Ruhen nahe einem Schutzplatz | Aktion / Menü | R |
| Trab | Trab umschalten | Umschalt halten |
| Karte | Karte / Minikarte | M |
| Menü / zurück | ☰ / × / Android-Zurück | Escape |

## Spielstände & Entwicklung

Spielstandformat 4 übernimmt Fortschritte aus 0.1–0.3. Automatisches Speichern erfolgt alle 20 Sekunden, beim Gebietswechsel und beim Wechsel in den Hintergrund. Der Hauptspielstand wird atomar ersetzt. Begegnungen und tatsächliche Aktionszähler werden mitgespeichert. Ein begrenzter Sitzungscache und kompakte Tierpositionen erhalten besuchte Tierwelten über Cache-Verdrängung und App-Neustarts.

```sh
godot --headless --editor --import --quit
godot --headless --script tests/smoke.gd
godot --headless --script tests/gameplay_expansion.gd
godot --headless --script tests/graphics_expansion.gd
godot --headless --script tests/ui_expansion.gd
mkdir -p builds/web
godot --headless --export-debug Android builds/Wolf-0.4.0-debug.apk
godot --headless --export-release Web builds/web/index.html
```

Android: Godot-4.5.1-Exportvorlagen, JDK 17, Android SDK mit `platform-tools`, `build-tools;35.0.1`, `platforms;android-35`. Package `cloud.kosch.wolf`, ARM64, minSdk 24, targetSdk 35. Private Signierschlüssel bleiben außerhalb des Repositorys. [Entwicklungsübergabe](docs/development-handoff.md) und [Prüfbericht](docs/validation-0.4.0.md) beschreiben den tatsächlich geprüften Stand.

Spielbarer Prototyp. Noch kein Test auf einem physischen Android-Gerät und noch kein vollständiger Lebenszyklus mit Partnersuche, eigener Nachwuchspflege oder kooperativer Jagd. Bedürfnisse und Tierverhalten bleiben spielerisch vereinfacht.

Idee und Ausrichtung: **KoSch / Kolja Werner Schumann**.
