# Tea Kadai

A cozy pixel-art shop sim about running a roadside tea kadai in Chennai. Make tea by hand, fry vadai, get to know the people on your street, and grow one stall into a few.

This is the first playable: **one fun day** at one stall. See [docs/PLAN.md](docs/PLAN.md) for the full game plan and milestones.

## Run it

Needs [Godot 4.7](https://godotengine.org/) (`brew install --cask godot` on a Mac).

```bash
godot --path .
```

Skip the morning market and go straight to service:

```bash
godot --path . -- --service
```

Or open the folder in the Godot editor and press Play.

## How a day works

1. **Morning:** buy milk, tea powder, sugar, batter, oil, biscuits and buns, and set your prices. The game is paused while you plan.
2. **Service (about 11 minutes):** morning rush, quiet afternoon, evening rush, closing time. Customers stand at the counter with what they want in a bubble. When the bubble border turns green, everything they want is ready. Nobody walks out: people who wait too long grumble (red border) and skip the tip, but still pay. If you run out of something, they skip it.
3. **Night:** see what you sold, your tips, your profit, and who waited too long.

You can't lose. A bad day just means less money for tomorrow.

## Controls

The game is mouse first. Keys are optional shortcuts.

| Action | Mouse | Key |
| --- | --- | --- |
| Make a glass of tea | Press Make tea | Space |
| Pour (hold, let go in the green) | Hold the tea button | Hold Space |
| Fry a batch of 4 vadai, then lift them out when golden | Fry button, or click the kadai | F |
| Serve a customer | Click them or their bubble | 1 to 4 |
| Pause | | P |
| Sound on/off | | M |

## Sound

All sounds are placeholders synthesized by `tools/make_sounds.gd` into `assets/sounds/`. To replace one, drop in a real recording with the same file name. To regenerate them:

```bash
godot --headless --path . -s tools/make_sounds.gd
godot --headless --path . --import
```

All input goes through named actions in `scripts/core/controls.gd`, so touch and controller support can be added there later.

## Tests

```bash
godot --headless --path . --import
godot --headless --path . -s tests/test_core.gd
godot --path . -s tests/test_play.gd
```

- `test_core.gd` checks the rules (clock, market, pour, fryer, serving) and has a bot play a whole day.
- `test_play.gd` plays the real game through mouse and keyboard events, from the morning market to the next day. It opens a window. Add `--write-movie play.avi --fixed-fps 30` to record it.

## Layout

```
scripts/data/catalog.gd     All tunable numbers: menu, market, customers, day phases
scripts/core/               Game rules, no drawing: state, clock, tea, fryer, service, controls
scripts/ui/                 Screens, placeholder art drawn in code, and the sound board
assets/sounds/              Sound effects, ambience and music (placeholders for now)
tools/make_sounds.gd        Synthesizes the placeholder sounds
tests/                      Headless rule checks and an input-driven play test
docs/PLAN.md                The game plan
```
