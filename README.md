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

1. **Title:** continue your saved week or start a new kadai. The game saves at the start of every morning.
2. **Morning:** read the paper (with the weather forecast), check the week ahead, and buy from the market stalls. Set your prices. The game is paused while you plan.
3. **Service (about 11 minutes):** morning rush, quiet afternoon, evening rush, closing time. Customers stand at the counter with what they want in a bubble; a green border means everything they want is ready. Nobody walks out: people who wait too long grumble and skip the tip. About one day in three it rains, and everyone wants tea.
4. **Night:** the day's takings count up, you get one to three stars, a line about what Karthik is up to, and upgrades to buy.

You can't lose. A bad day just means less money for tomorrow.

### Karthik

A broke, dreamy engineering student who drops by every day. He chats, asks you things, and after a couple of days just orders "the usual" (remember it for a bonus). Get friendly and he teaches you ginger tea, brings his friends, and tips double. His story runs across the first week.

### Upgrades

Bench (one more seat), bigger milk pot (glasses fill twice as fast), table fan (customers stay patient longer), lit signboard (busier evenings).

## Controls

The game is mouse first. Keys are optional shortcuts.

| Action | Mouse | Key |
| --- | --- | --- |
| Make a glass of tea | Press Make tea | Space |
| Pour (hold, let go in the green) | Hold the tea button | Hold Space |
| Switch plain / ginger tea (once learned) | Plain / Ginger | G |
| Fry a batch of 4 vadai, then lift them out when golden | Fry button, or click the kadai | F |
| Serve a customer | Click them or their bubble | 1 to 5 |
| Answer a customer's question | Click an answer | |
| Pause menu | Menu | P or Esc |
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
- `test_play.gd` plays the real game through mouse and keyboard events: title, market, service, pause menu, Karthik's visit, night, the next morning, and quitting to the title. It opens a window and uses its own save file. Add `--write-movie play.avi --fixed-fps 30` to record it.

## Layout

```
scripts/data/catalog.gd     All tunable numbers: menu, market, customers, day phases, upgrades, weather
scripts/data/story.gd       The regulars and their week of story
scripts/core/               Game rules, no drawing: state, saving, settings, clock, tea, fryer, service, regulars
scripts/ui/                 Screens, placeholder art drawn in code, and the sound board
assets/sounds/              Sound effects, ambience and music (placeholders for now)
assets/fonts/               Pixelify Sans (SIL Open Font License)
tools/make_sounds.gd        Synthesizes the placeholder sounds
tests/                      Headless rule checks and an input-driven play test
docs/PLAN.md                The game plan
```
