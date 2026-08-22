# Game of Life

A theme-synced, retro LED-matrix Conway's Game of Life for the Omarchy bar.
Lightweight, no dependencies, pure QML + JS. The grid follows your active
Omarchy theme automatically — no separate theme code.

## Features

- Retro pixel LED grid rendered on a canvas (no per-cell items — stays light).
- CRT-style ghosting trails (configurable).
- Theme-synced colors via the active Omarchy shell theme.
- Click / drag to draw (left = alive, right = erase).
- Seed presets: Glider, Pulsar, Gosper Glider Gun, plus Random and Clear.
- Keyboard: `space` play/pause, `R` random, `C` clear.

## Install

```sh
omarchy plugin add https://github.com/guillechuma/gameoflife.git --enable
```

## Usage

Click the `GOL` widget to open or close the panel. Press `Escape` to close.

## Configure

All options live in the widget's `shell.json` settings:

| Key     | Type    | Default | Description                              |
|---------|---------|---------|------------------------------------------|
| cols    | number  | 48      | Cells horizontally                       |
| rows    | number  | 32      | Cells vertically                         |
| speed   | number  | 8       | Steps per second while playing           |
| wrap    | boolean | true    | Loop edges (torus)                       |
| trail   | number  | 0.35    | 0 = no ghosting, 1 = long CRT fade       |

```sh
omarchy bar move io.github.guillechuma.gameoflife --section right
```

## Remove

```sh
omarchy plugin remove io.github.guillechuma.gameoflife
```
