# GutenbergLumen

Arcade **Lights Out** — press a cell to toggle it and its neighbors; clear the board.

Gameplay from [Lumen](../lumen), skinned with [GutenbergArcadeUI](../GutenbergArcadeUI).

## Layers

| Layer | Owns |
|-------|------|
| `GutenbergLumenKit` | Board rules, daily/random puzzle generation, session |
| `LumenGame` | Controller: difficulty, hints, streak / best persistence |
| App views | Board, splash, rail wiring |
| `GutenbergArcadeUI` | Neon chrome, celebration shell, rail controls |

## Build

```bash
xcodegen generate
open GutenbergLumen.xcodeproj
```

Schemes: `GutenbergLumen-iOS`, `GutenbergLumen-tvOS`, `GutenbergLumen-macOS`.

Signing: copy `Signing.local.xcconfig` with your `DEVELOPMENT_TEAM` (see `Signing.xcconfig`).
