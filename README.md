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
2. **Service (about 11 minutes):** morning rush, quiet afternoon, evening rush, closing time. Customers stand at the counter with what they want in a bubble. When the bubble border turns green, everything they want is ready.
3. **Night:** see what you sold, your tips, your profit, and who walked off.

You can't lose. A bad day just means less money for tomorrow.

## Controls

| Action | Mouse | Key |
| --- | --- | --- |
| New glass, then decoction, sugar, milk | Tea button | T |
| Pour (hold, let go in the green) | Hold Pour | Hold Space |
| Drop a vadai in the oil | Drop vadai | F |
| Lift a vadai out (golden is best) | Click the vadai | Z, X, C |
| Serve a customer | Click them | 1 to 4 |
| Pause | | P |

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
scripts/ui/                 Screens and placeholder art drawn in code
tests/                      Headless rule checks and an input-driven play test
docs/PLAN.md                The game plan
```
