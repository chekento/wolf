# Grafikquellen · 0.2.0

`assets/woodland-atlas.png` wurde mit dem integrierten Bildgenerator erzeugt, als neues transparentes Spriteatlas mit lokalen Stilreferenzen aus den vom Nutzer bereitgestellten Bildern. Das Bild wird als unveränderte PNG-Datei verwendet; `scripts/atlas.gd` wählt die Spritebereiche zur Laufzeit aus. Keine externen Spielgrafiken wurden übernommen.

Generierungsrichtung: Niedliche, farbige, handgemalte Comic-Wildnis; weiche Konturen, warme Farben, freundliche Wölfe, natürlicher Lebensraum. Transparenter 4×4-Atlas mit Kiefer, Eiche, Birke, Busch, Fels, Baumstumpf, Blumen und Höhle; Wolf in vier Richtungen; Reh, Hase, Fuchs und Wolfporträt. Einzelne Objekte ohne Beschriftung, ohne Rahmen und ohne Hintergrund, für ein Spiel aus schräger Draufsicht. Die beigefügten Wald-, Rudel- und Schneeansichten dienen als stilistische Orientierung.

Die Dateien in `docs/` sind echte Aufnahmen des laufenden Spiels. Die 3D-Modelle werden direkt in Godot aus räumlichen Grundformen erstellt und sind eine erste Ausbaustufe.


## Erweiterung 0.3.0

- `assets/wolf-walk-atlas.png`: neuer, unverändert verwendeter transparenter PNG-Atlas mit je vier Laufphasen in vier Richtungen. Prompt: dieselbe junge graue Comic-Wolffigur, vier natürliche Pfoten, cremefarbenes Fell an Bauch/Schnauze, bernsteinfarbene Augen; 4×4-Atlas, abwechselnde diagonale Laufphasen, Kamera leicht von oben, ohne Texte oder Landschaft.
- `assets/wildlife-action-atlas.png`: neuer, unverändert verwendeter transparenter PNG-Atlas. Prompt: vier Laufphasen eines Rehs, vier Sprungphasen eines Hasen, vier Laufphasen eines Fuchses; vier Wolfaktionen (Schnüffeln, Heulen, eingerolltes Ruhen, Spielbogen); gleiche handgemalte Comic-Ästhetik, natürliche Tiere und vier gleich breite Spalten, ohne Texte oder Hintergrund. Beide Bilder wurden mit der integrierten Bildgenerierung erzeugt; vorhandene Atlasbilder dienen ausschließlich als Stilreferenz.
- `scripts/atlas.gd`: Bildausschnitte werden im Spiel als AtlasTexture gewählt. Uneinheitliche Zeilenränder der generierten Bilder werden hier berücksichtigt, ohne die PNG-Dateien zu bearbeiten.
- `scripts/animal_model.gd`: eigene räumliche, farbige Meshes und bewegliche Gelenke. Kein externes 3D-Modell; Laufphasen folgen der zurückgelegten Strecke.
- `scripts/forest_mesh.gd`, `assets/wilderness.gdshader`: eigene Baum-, Fels- und Bodenoberflächen.
- `assets/fonts/DejaVuSerif.ttf`: DejaVu Serif; Lizenz und Herkunft in `assets/fonts/LICENSE.txt`.

Die Bilder in `docs/` sind Aufnahmen des Godot-Spiels unter Linux mit Software-Rendering. Keine Konzeptbilder werden als Spielaufnahmen ausgegeben.

## Erweiterung 0.4.0

- Eigene anatomische Mesh-Modelle mit zusätzlichen Fellpartien, Schnauzen, Augen, Pfoten und beweglichen Knien; Arten teilen zusammengefasste Meshes und Materialien zur Laufzeit.
- Eigene Geometrien für Farne, Gräser, Schilf, Blumen, Holz und Landschaftsorte. Keine externen Modellpakete.
- `assets/wild-sky.gdshader`: eigener Tageshimmel mit Wolken, Sternen und Mond; `assets/wilderness.gdshader`: eigene saisonale Boden- und Wasseroberflächen.
- `scripts/menu_art.gd`: prozedural gezeichnete Wald- und Flussillustrationen mit dem vorhandenen originalen Wolfporträt.
- `scripts/cartography.gd`: gezeichnete Kartenflächen, Höhenlinien, Vegetationszeichen, Kompass und Maßstab aus tatsächlichen Weltdaten.

Die bestehenden PNG-Atlanten werden unverändert weiterverwendet. Neue Darstellungen entstehen aus eigenem Code und Modellgeometrie.
