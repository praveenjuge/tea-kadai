# Tea Kadai: Game Plan

A cozy shop sim about running a roadside tea kadai in today's Chennai. You make tea by hand, get to know your regulars, and slowly grow from one street-corner stall into a small chain of kadais.

## The pitch

- **Genre:** shop tycoon + cozy life sim
- **Tone:** warm and funny
- **Audience:** everyone, with a proud Tamil/Chennai flavour
- **Price:** one-time purchase
- **Built by:** one person, with Claude, in Godot

## Look and sound

- **Art:** pixel art, isometric view of the stall and the street around it
- **Setting:** Chennai today: autos, UPI payments, Marina beach, metro construction
- **Music:** original Tamil-inspired tracks (nadaswaram, veena, light percussion) that change with the time of day
- **Ambience:** auto horns, crows, rain on a tin roof, oil hissing, glasses clinking
- **Voice:** short Tamil barks only ("Anna, oru tea!", "Strong-a podunga")
- **Radio:** a radio on the shelf with a few stations you can switch between
- **Text:** English, with Tamil words mixed in and a glossary

## How a day plays

Each day has three parts:

1. **Morning planning (paused).** Buy stock from the market (milk, tea powder, sugar, oil, flour), set prices, and assign helpers.
2. **Live service.** Morning rush, quiet afternoon, evening rush, closing time. About 10–15 real minutes.
3. **Night summary.** Money earned, who visited, what ran out, what the regulars said.

A **Relaxed mode** setting removes the timer, so customers wait patiently and each order plays out at your own pace.

### Making things

- **Hands-on early:** boil milk, add decoction, add sugar, then do the long "meter" pour. Fry vadai and bajji in the kadai.
- **Automated later:** hired helpers and better equipment take over steps, so you can focus on customers and the bigger shop.

### Menu (full game)

- **Drinks:** plain tea, masala, ginger, lemon tea, filter coffee, malt drinks
- **Fried snacks:** vadai, bajji, bonda, samosa
- **Packaged snacks:** biscuits in glass jars, bun, rusk, murukku, bananas
- **Other:** newspapers, goli soda, small sundries

### Money

- Buy stock every morning. If something runs out, you can't sell it that day.
- Set your own prices. Regulars notice when tea goes from ₹12 to ₹15.
- You can't lose. A bad day means slower growth, never game over.

## People

- **Regulars with stories:** an auto driver, college kids, a retired uncle, an office worker, and more. Each story plays out over many visits.
- **Remember their order:** "Less sugar, extra strong." Getting it right builds loyalty.
- **Gossip and news:** cricket, cinema, local news. What you overhear can start events.
- **Your own story:** the owner is customizable (name, look, clothes) and has a backstory, such as taking over the family kadai.

## Growth

- **Upgrade the stall:** bigger stove, more benches, a fan, a tube light, a signboard
- **Hire helpers:** a glass-washer, a vadai fryer, each with a personality
- **New locations:** street corner → bus stand → beach → railway station → college gate
- **Unlock recipes:** learned from customers, family, and festivals

## Events

- **Weather:** monsoon rain brings tea crowds, heat waves bring soda and buttermilk
- **Festivals:** Deepavali, Margazhi season, Pongal, each with special items and decorations
- **Cricket and cinema days:** a big match on the radio or a star's film release brings huge crowds
- **Everyday trouble:** power cuts, a milk strike, a cow eating your bananas, a corporation inspection

## Modes

- **Campaign (~5 hours):** one season, from the northeast monsoon to Pongal. Three locations, with an ending at the Pongal festival.
- **Daily challenge (endless):** a new set of rules each day (rain day, match day, power cut) with a score and a leaderboard.

## Platforms and controls

- **First:** Mac + Steam, played with mouse and keyboard shortcuts
- **Later:** Mac App Store, iOS, Android, PS5

Two things to plan for now so ports stay cheap later:

- **Keep input separate from game logic.** Every action ("pour", "serve seat 3") goes through one input layer. Touch (phones) and a controller (PS5, Steam Deck) can then be added without touching game code.
- **PS5 needs extra steps.** It needs a Sony developer licence and a Godot console porting partner. Plan this after the Steam launch.

## Milestones

### 1. One fun day (first playable)

Goal: prove that a single day is fun.

- One street-corner stall, isometric, placeholder pixel art
- Hands-on tea making (boil, decoction, sugar, pour) and vadai frying
- Biscuits and bun as no-prep items
- 4–5 generic customer types with patience and simple orders
- Morning stock buying and price setting
- Live service with the four day phases
- Night summary
- Mouse + number-key shortcuts
- Mac build

**Done when:** you play a full day, want to play another, and the pour feels good.

### 2. A week at the kadai (vertical slice)

- Days connect into a week, with saves
- 2–3 regulars with short stories and remembered orders
- First upgrade (bench or fan) and first helper
- One weather event (rain)
- Relaxed mode toggle
- First real pixel art pass, ambience, and a first music track
- Steam playtest build

### 3. The full season (campaign)

- All three locations, with branches
- Full menu and recipe unlocks
- All regulars' stories, gossip events, and the owner's story
- Festivals, cricket/cinema days, everyday trouble
- Radio, voiced barks, full soundtrack
- Character customization
- Steam release

### 4. Daily challenge

- Daily rule sets generated from a date seed
- Score and online leaderboard

### 5. Ports

- Mac App Store
- iOS and Android with touch controls
- PS5 with controller support, through a porting partner

## Open questions for later

- Does the radio play original songs, talk shows, cricket commentary, or a mix?
- How are helpers paid: a daily wage, or a share of sales?
- Where do the Daily challenge leaderboards live: Steam's own, or a small server of our own?
- Is there one ending, or does it change based on choices with the regulars?
