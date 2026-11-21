# THE LAST PIXEL — Gameplay Test Checklist

Run the project (F5 in Godot) and verify every item. The logic was smoke-tested headless (boot, pickups, trail sampling, reconnection reward, game over, restart), but play-test on your target machine — and run section 10 before claiming web/Windows support.

## 1. Boot and world
- [ ] Game starts immediately — no menu, no splash, no loading screen.
- [ ] Background is pure black; no visible borders, walls or grid.
- [ ] 9 memory nodes, 14 fragments and 3 anchors exist as white outlines near spawn.
- [ ] Layout is identical on every fresh run (deterministic seed).
- [ ] FPS stays around 60 on modest hardware (check Godot debugger monitor).

## 2. Player and camera
- [ ] WASD and arrow keys both move the player.
- [ ] Movement reaches ~240 px/s, accelerates and stops snappily.
- [ ] Diagonal speed is not faster than cardinal speed (input normalized).
- [ ] Camera follows smoothly; the pixel stays clearly visible on black (glow layers breathe).

## 3. Memory trail
- [ ] White trail appears behind the player while moving.
- [ ] Trail fades gradually and old points vanish (~4.5 s lifetime by default).
- [ ] Standing still: the trail keeps shrinking until it disappears entirely.
- [ ] Long wandering: no stutter or FPS drop (points capped at 400).

## 4. Geometric objects
- [ ] Touch a memory node → ripple ring, soft chime, stability +18, trail lingers longer (+2 s bonus).
- [ ] Touch a fragment → ripple, chime with random pitch, DISCOVERED counter +1.
- [ ] Touch an anchor → big ripple, for 10 s the trail lasts about twice as long and stability drain halves.
- [ ] Used objects dissolve and cannot be re-triggered.

## 5. Pulse (SPACE)
- [ ] SPACE spawns an expanding white ring (~220 px) that fades smoothly.
- [ ] Nearby objects flash and ripple when the pulse reaches them.
- [ ] Cooldown is ~2.5 s; the PULSE bar refills and brightens when ready.
- [ ] No FPS drop when pulsing.

## 6. Trail reconnection
- [ ] Walk a loop back onto your own old trail → small ring, chime, stability +8, trail bonus +0.75 s.
- [ ] Rewards cannot be spammed: 2 s cooldown between rewards, only trail older than ~0.9 s counts.

## 7. Stability and game over
- [ ] STABILITY bar drains constantly; it blinks and dims below 20%.
- [ ] Memory nodes and reconnections visibly restore the bar.
- [ ] Anchoring visibly slows the drain while active.
- [ ] At zero: quick white flash → screen fades → GAME OVER, final DISCOVERED count, blinking restart prompt.
- [ ] Game-over tone plays and ambient audio fades out.

## 8. Restart
- [ ] R restarts instantly at any moment, including mid-run.
- [ ] After game over, R or ENTER restarts into a fresh run (score 0, stability 100, objects restored).

## 9. Audio
- [ ] Soft noise plays while moving; it fades out when you stop.
- [ ] Ambient pad loops without a loud click.
- [ ] Discovery / connect / pulse tones are gentle and do not clip.
- [ ] All audio is self-contained (no external dependencies).

## 10. Exports
### Windows
- [ ] Export Project (Windows Desktop) produces a runnable `.exe` on a real Windows machine.
### Web
- [ ] Export (Web) → serve the folder (`python -m http.server 8000`) → open in Chrome and Firefox.
- [ ] Keyboard input works; audio starts after the first key press.
- [ ] The game reaches a playable FPS in the browser.

Anything failing → check README Troubleshooting or the tuning constants at the top of `scripts/main.gd`.
