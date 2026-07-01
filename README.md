# SnipMC

**macOS Menu Bar Screenshot Tool mit integriertem Bildeditor**

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/Lizenz-Freeware-green)

SnipMC ist ein schlankes Screenshot-Tool für macOS, das in der Menüleiste lebt. Es bietet drei Aufnahme-Modi, einen integrierten Bildeditor für Annotationen und ein URL-Schema zur Steuerung über externe Tools wie Logitech Options+, Kurzbefehle oder Stream Deck.

## Features

- **Screenshot-Modi**: Ganzer Bildschirm, Fenster oder frei wählbarer Bereich
- **Bildeditor**: Pfeile, Rechtecke, Ellipsen und Text-Annotationen
- **Flexibler Zugriff**: Letzte Aufnahme bearbeiten, Bild aus Zwischenablage, Datei öffnen
- **URL-Schema** (`snipmc://`): Externe Steuerung per Tastenkürzel, Stream Deck etc.
- **Einstellungen**: Speicherort, Bildformat (PNG/JPG), konfigurierbare Tastenkürzel
- **Menüleisten-App**: Kein Dock-Icon, läuft dezent im Hintergrund

## Installation

1. `SnipMC.dmg` aus dem [aktuellen Release](https://github.com/mwende/SnipMC/releases/latest) herunterladen
2. DMG öffnen und `SnipMC.app` nach `/Programme` ziehen
3. App starten — das Kamera-Icon erscheint in der Menüleiste
4. Beim ersten Start die Berechtigung **Bildschirmaufnahme** erteilen:
   *Systemeinstellungen → Datenschutz & Sicherheit → Bildschirmaufnahme*

## Screenshot-Modi

| Modus | Beschreibung |
|---|---|
| Ganzer Bildschirm | Nimmt den gesamten Bildschirm auf |
| Fenster | Klicke auf ein Fenster, um es aufzunehmen |
| Bereich auswählen | Ziehe einen Rahmen um den gewünschten Bereich |

## Bildeditor

Der integrierte Editor öffnet sich nicht automatisch nach jeder Aufnahme, sondern nur auf expliziten Wunsch — über das Menü, per URL-Schema oder über die Tastenkombination.

### Werkzeuge

| Werkzeug | Beschreibung |
|---|---|
| Pfeil | Linie mit Pfeilspitze zeichnen |
| Rechteck | Rahmen um einen Bereich zeichnen |
| Ellipse | Kreis oder Oval zeichnen |
| Text | Klicke auf eine Stelle und tippe Text ein |

### Tastenkürzel im Editor

| Kürzel | Aktion |
|---|---|
| ⌘Z | Rückgängig |
| ⌘⇧Z | Wiederholen |
| ⌫ / Entf | Ausgewählte Annotation löschen |
| ⌘S | Speichern |

## URL-Schema

SnipMC registriert das URL-Schema `snipmc://` und kann so von externen Tools gesteuert werden.

| URL | Aktion |
|---|---|
| `snipmc://fullscreen` | Vollbild-Screenshot |
| `snipmc://window` | Fenster-Screenshot |
| `snipmc://region` | Bereich-Screenshot |
| `snipmc://region?edit=true` | Bereich aufnehmen + Editor öffnen |
| `snipmc://fullscreen?edit=true` | Vollbild aufnehmen + Editor öffnen |
| `snipmc://edit` | Bild aus Datei im Editor öffnen |
| `snipmc://editlast` | Letzten Screenshot im Editor bearbeiten |
| `snipmc://clipboard` | Bild aus Zwischenablage bearbeiten |

### Einrichtung per macOS Kurzbefehle

1. Kurzbefehle-App öffnen
2. Neuer Kurzbefehl → Aktion **URL öffnen**
3. URL eintragen, z. B.: `snipmc://region`
4. Optional: Tastaturkurzbefehl zuweisen

### Einrichtung per Terminal

```bash
open snipmc://region
open "snipmc://region?edit=true"
open snipmc://editlast
```

## Einstellungen

- **Ausgabe**: Nur speichern, nur Zwischenablage, oder beides
- **Bildformat**: PNG oder JPG
- **Speicherort**: Standard `~/Bilder/Screenshots`, frei wählbar
- **Tastenkürzel**: Für jeden Aufnahme-Modus individuell konfigurierbar

## Systemvoraussetzungen

- macOS 14.0 (Sonoma) oder neuer
- Berechtigung **Bildschirmaufnahme** erforderlich

## Entwicklung

```bash
# Voraussetzung: Xcode + XcodeGen
brew install xcodegen

# Projekt generieren und bauen
xcodegen generate
xcodebuild -project SnipMC.xcodeproj -scheme SnipMC -configuration Release build
```

## Autor

**Marco Wende — [Wende.IT](https://wende.it)**

Freeware — kostenlos nutzbar.
