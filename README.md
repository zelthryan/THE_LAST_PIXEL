# THE LAST PIXEL

*You are the last pixel. Your trail is the world.*

A minimalist top-down exploration-survival prototype by ZELTHRYAN, built in **Godot 4.x / GDScript 2**. One glowing white pixel in an endless black void: your movement draws a fading memory trail, geometric objects answer your pulse, and the world's stability drains until you feed it with discoveries and reconnections — or it fades forever.

- Base resolution 1280x720, 60 FPS target on modest hardware (Intel UHD 630 class).
- Strict black & white: background `#000000`, everything else white outlines and white light.
- No menu, no lobby, no quests, no dialogue: the game starts the instant it runs.

## 1. Requirements

- **Godot 4.3 or newer** (standard build). No plugins, no external assets, no shaders.
- Export templates (only needed for Windows/Web export, installed from inside the editor).

## 2. Run (60 seconds)

1. Open Godot → **Import** → select `THE_LAST_PIXEL/project.godot` → **Import & Edit**.
2. Press **F5** (Run Project). The game starts immediately.

## 3. Controls

| Input | Action |
| --- | --- |
| `W A S D` / Arrow keys | Move (~240 px/s, snappy accel/decel) |
| `SPACE` | Pulse — expanding ring, 2.5 s cooldown |
| `R` | Restart at any time |
| `R` / `ENTER` | Restart after game over |

## 4. Exact node hierarchy

```
THE_LAST_PIXEL/
  project.godot                  Input Map, 1280x720, GL Compatibility renderer
  icon.svg
  scenes/
    main.tscn
    player.tscn
    memory_node.tscn
    fragment.tscn
    anchor.tscn
  scripts/
    main.gd
    player.gd
    memory_trail.gd
    pulse.gd
    world_object.gd
  assets/audio/
    ambient.wav  move.wav  pulse.wav  discover.wav  connect.wav  gameover.wav
  README.md
  TESTING_CHECKLIST.md
```

```
Main (Node2D, main.gd)
├── Trail (Line2D, memory_trail.gd)         gradient fade + width taper, max 400 points
├── WorldObjects (Node2D)                   9 MemoryNodes / 14 Fragments / 3 Anchors, spawned at runtime
├── Effects (Node2D)                        pulse + ripple rings, spawned at runtime
├── Player (instance of player.tscn)
│   ├── CollisionShape2D (CircleShape2D r=7)
│   ├── Glow2 (Polygon2D 32x32, alpha 0.07) ┐ layered lightweight glow,
│   ├── Glow1 (Polygon2D 20x20, alpha 0.16) ┘ alpha breathes in player.gd
│   ├── Body (Polygon2D 8x8, white)
│   ├── Camera2D (position smoothing enabled)
│   └── MoveSound (AudioStreamPlayer, move.wav)
├── Audio (Node)
│   ├── Ambient / SfxPulse / SfxDiscover / SfxConnect / SfxGameOver (AudioStreamPlayers)
└── UI (CanvasLayer)
    ├── DiscoveryLabel ("DISCOVERED N")
    ├── StabilityLabel + StabilityTrack/StabilityFill (bottom-center bar)
    ├── PulseLabel + PulseTrack/PulseFill (bottom-left cooldown bar)
    ├── HintLabel (control hint, fades out after ~6 s)
    └── GameOver (Control, hidden until death)
        ├── Dim (ColorRect, fades to alpha 0.88)
        ├── Flash (ColorRect, quick white flash)
        └── Center (CenterContainer) → VBox → GoTitle / GoSub / GoScore / GoHint
```

Object scenes (all `Area2D` + `CollisionShape2D`, one shared `world_object.gd`, visuals via `_draw()`):

```
MemoryNode (Area2D, kind = MEMORY_NODE) — CollisionShape2D r=18
Fragment   (Area2D, kind = FRAGMENT)    — CollisionShape2D r=12
Anchor     (Area2D, kind = ANCHOR)      — CollisionShape2D r=30
```

## 5. Input Map (preconfigured in project.godot)

| Action | Keys (physical, layout independent) |
| --- | --- |
| `move_up` | W, Up |
| `move_down` | S, Down |
| `move_left` | A, Left |
| `move_right` | D, Right |
| `pulse` | Space |
| `restart` | R |
| `confirm` | Enter |

## 6. Systems overview (tuning constants live at the top of each script)

- **World stability** (`main.gd`): starts 100, drains 3/s (halved while an Anchor is active). Memory node +18, trail reconnection +8, Anchor +5. At 0 → white flash, screen fade, GAME OVER.
- **Memory trail** (`memory_trail.gd`): a point every ≥12 px of movement, base lifetime 4.5 s, hard cap 400 points, gradient + width-taper fade. Memory nodes add +2 s temporary bonus, reconnections +0.75 s, Anchors double the lifetime for 10 s. Standing still lets the trail die.
- **Pulse** (`main.gd` + `pulse.gd`): radius 220 px, cooldown 2.5 s, one expanding ring; every object in range flashes and emits its own ripple.
- **Reconnection** (`main.gd`): standing within 26 px of a trail point older than 0.9 s rewards stability + trail lifetime, with a 2 s cooldown between rewards. Looping back over your own path is a core survival tactic.
- **World layout** (`main.gd`): deterministic (seeded RNG), 9 memory nodes at 320–900 px, 14 fragments at 160–1150 px, 3 anchors at 520–860 px, minimum 130 px spacing. Objects are consumed when used — the void slowly empties, which drives the survival loop.

### One-hour build plan → where it lives

| Plan slot | Implemented by |
| --- | --- |
| 0–10 min project + movement | `project.godot`, `player.tscn`, `player.gd` |
| 10–20 min memory trail | `memory_trail.gd`, Trail node in `main.tscn` |
| 20–30 min objects + collisions | `world_object.gd`, 3 object scenes, `_spawn_world()` |
| 30–40 min pulse + connection | `pulse.gd`, `_try_pulse()`, `_check_connection()` |
| 40–50 min stability, restart, UI | `_process()` / `_do_game_over()` / UI nodes |
| 50–60 min test + optimize | see `TESTING_CHECKLIST.md` |

## 7. Windows export

1. Editor → **Project → Export…** → **Add…** → **Windows Desktop**.
2. If prompted, install matching **Export Templates** (Editor → Manage Export Templates → Download and Install).
3. Optional preset tweaks: product name, embedded icon (`res://icon.svg` is used by default), "Embed Pck" for a single-file exe.
4. **Export Project** → choose a folder → you get `THE_LAST_PIXEL.exe` (+ `.pck` unless embedded). Use "Export With Debug" if you want the console log window.
5. Smoke test on the target machine: run the exe, verify 60 FPS and the checklist.

## 8. HTML5 / Web export

The project is already web-ready: **GL Compatibility renderer** (required on browsers), keyboard-only input, no platform-specific APIs, plain WAV audio.

1. Editor → **Project → Export…** → **Add…** → **Web**.
2. **Export Project** → e.g. `export/web/index.html` (+ `.wasm`, `.pck`, `.js` sidecar files).
3. Browsers refuse to boot such builds from `file://` — serve the folder over HTTP, e.g.:
   ```
   cd export/web
   python -m http.server 8000
   ```
   then open `http://localhost:8000/index.html`.
4. Browser autoplay policy: audio starts after the first key press (the engine resumes the audio context on first input; the game self-heals ambient playback every frame).
5. **Honesty note (per the project spec):** the game logic was smoke-tested headless (boot, pickups, trail, reconnection, game over, restart), but the **web export itself has not been built and tested in a browser as part of this delivery** — please run checklist section 10 before claiming web support.

## 9. Performance notes

- No shaders, no lights, no 3D, no particles: glow is layered semi-transparent squares; rings are single `_draw()` arcs.
- Trail: ≤400 points, Line2D rebuild only when points actually change.
- ~26 static objects, each one `Area2D` with a `CircleShape2D`; visuals redrawn as a few polyline/arc calls.
- Reconnection scan runs 10x/second over ≤400 points — negligible.
- Object pooling intentionally omitted: effects are tiny Node2Ds freed after <1 s.

## 10. Troubleshooting

- Opening in a newer 4.x shows a version notice for the "4.3" feature tag — informational, click through.
- First import may print UID warnings for hand-authored scenes — harmless; the editor assigns UIDs on first save.
- No audio: all sounds are generated WAVs in `assets/audio/` — check the system mixer first; volumes are set per-AudioStreamPlayer.
- The world feels too harsh/generous: tune `DRAIN_PER_SEC`, `NODE_STABILITY`, `PULSE_COOLDOWN` at the top of `scripts/main.gd`.
