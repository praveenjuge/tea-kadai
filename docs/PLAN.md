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

## Playtest 1 notes (2026-11-14)

Played part of a service day.

- **Felt:** stressful. The pace of customers was about right, but everything competed for attention.
- **Why:** draining patience bars and walkouts, too much to juggle, too many keys, hard to read (small bubbles, busy bottom panels, the whole game small on screen).
- **Tea:** four presses before every pour was too many steps. The pour itself was enjoyable.
- **Vadai:** didn't really get tried.
- **Liked:** the street scene, the pour, earning money, the morning market.
- **Look:** wants real pixel art soon.

### Decisions

- Tea is one press to prepare the glass, then the pour.
- No walkouts. A customer who waits too long grumbles and tips nothing, but still pays.
- Vadai fry in batches of four with one timing moment, then stay warm on a plate.
- Mouse first. Space (tea), F (vadai), 1 to 4 (serve) and P (pause) are optional shortcuts.
- Claude makes the pixel art as small hand-authored PNG sprites.

## Playtest 2 notes (2026-11-14)

After the calm-down pass.

- **Felt:** better, but still busy.
- **Working:** tea (press to fill, hold to pour) feels just right, batch vadai is liked, window size and bubbles are good, and the day length is about right.
- **Still busy because:** eyes jump between the customers up top and the stations below.
- **Wanted:** rushes that start slower and build over the week, sound, customers with faces and personality, and a goal to aim for.

### Changes made

- Day 1 has noticeably fewer customers, building up to the full pace by day 4.
- Bubbles show which items are ready right now (bright) and which aren't (faded), so you can read the counter without looking down.
- Messages show at the bottom of the street, next to the stations, instead of the top.

## Round 3 decisions (2026-11-14)

- **First regular:** Karthik, a broke, dreamy engineering student. Speech bubbles in the street (the game keeps running), a question with two answers on some days, "the usual" from day 3, friendship that unlocks bigger tips, ginger tea, and bringing friends. His week ends with passing his exams. "Pay you tomorrow" is just a running joke.
- **Menus:** a living-street title screen (Continue, New game, How to play, Settings, Credits, Quit); a pause menu (Resume, Settings, How to play, Quit to title); settings for music, effects and street volume plus fullscreen.
- **Morning:** illustrated market stalls, a newspaper headline with a forecast, and a week strip.
- **Night:** a celebratory tally with stars, then upgrades to buy.
- **Polish:** pixel font (Pixelify Sans), fades between screens, coins flying to the money counter, sparkles on perfect pours, wood and tin-sign styled panels and buttons.
- **Hooks:** upgrades to save for, and a story cliffhanger each night.
- **Juice:** pour streaks with bonuses and rising pitch, customer reactions, rush-hour banners with a percussion layer.
- **World:** passers-by (walkers, cyclists, a dog, school kids), rain about one day in three, street chatter, and day names with dates.

All of the above is built.

## Playtest 3 notes and round 4 (2026-11-14)

Played, restarted a few times. Liked the title and menus, the market stalls and the street life. Stopped because the loop felt the same all day and the day was too long. Also: the story came too late, the art looked too simple, there was no sense of progress, and new players don't know to stock up on day 1.

Built in response:

- **Five-minute days**, with Karthik coming in the morning on his way to college.
- **An opening story:** you quit a dull IT job to open a tea stall.
- **Plenty of stock on day 1**, and a "Running low" note in the mornings.
- **Kadai level:** reputation from happy customers. Each level puts something new on the menu for free: lemon tea (2), bajji (3), filter coffee (4), samosa (5). Lemon tea and coffee share the tea station; bajji shares the kadai.
- **Three weekly goals** (customers, perfect pours, sales) with a reward each.
- **Visible growth to buy at night**, unlocked by level: fresh paint and a proper sign (the stall starts faded with a cardboard sign), plants and string lights, a radio with posters, a bigger counter with a second stove.
- **Faces:** bigger front-facing customers with eyes, hair styles, mustaches, glasses, sarees and helmets; two new customer types (a nurse and a flower seller); varied passers-by; face portraits beside regulars' speech.
- **Prices** moved into their own panel.

## Round 5: responsive and real-game look (2026-11-14)

Asked for: no black bars in fullscreen, and graphics and UI that look like a real game. The service screen felt the weakest.

- **Responsive:** the game fills any window or screen at a crisp whole-number pixel scale; extra space shows more street (UI stays the same size).
- **Service screen:** an icon HUD (clock dial that fills through the day, rolling coin counter, level badge, weather) and one wooden counter for the stove, kadai and steel tray instead of three flat panels.
- **Street:** a sky that changes from dawn to starry night, a row of colourful shop fronts and houses with lit windows at night, tiled pavement with cracks, a colourful kolam, a drain, a proper auto rickshaw, a bus with windows, scooters, street lamps with glow, and shadows that follow the sun.
- **Polish:** outlined pixel-art boxes, flames under the pot and kadai, heat shimmer, a newspaper picture, buttons that lift and squash, panels that pop in, money that rolls up, and customers who wave, slump with a storm cloud when grumpy, and hop when they leave happy.

## Round 6: ready to share (2026-11-14)

- Fullscreen fills any screen with no bars (smooth scaling).
- The kadai is a real shop in the building row: open front with shelves inside, counter, awning, sign, a flat upstairs, and a table with plastic chairs outside.
- Murugan, an auto driver saving for his own auto, is the second regular in week 2.
- Each week ends with a "Week N" card (save it to the Desktop); the night screen can save a day card too. After week 2 the game thanks friends for playing and keeps going.
- Balance tuned from a two-week bot run; no stuck days (customers eventually give up on orders you can't make, and Amma sends money if you're broke and out of tea).
- Sound volumes evened out by measured loudness.
- A Mac app (universal, ad-hoc signed) for friends, with first-launch instructions in the README.

## Round 7: open source (2026-11-14)

- MIT licence; the repo is public.
- No Godot boot splash.
- GitHub Actions builds macOS, Windows and Linux on every push to main and publishes the next patch release. A newer push cancels an older run, and only the last 10 releases are kept.


## Round 8: longer play, Chennai and polish (2026-11-14)

Asked for: play for longer (more cookie clicker), more Chennai, and everything more detailed and pleasant.

- **Clicker growth:** helpers (flask boys up to film set catering) who earn on their own and cost 15% more each; staff who take over a station you leave alone (chai boy, Cousin Ravi, vadai master); boosts that double things; golden glasses for a bonus or a 7x frenzy; half-rate earnings while away, up to 8 hours; branches across Chennai as the prestige reset (+25% each, for good). All under **Grow**, which also holds the kadai upgrades now.
- **Feel:** the night screen is the kadai under the moon, shutter half down, you counting coins, the tally on a chalkboard and the story in a notebook. A rolling shutter between screens. Oil splashes, confetti, floating "+₹", screen shake. New sounds: glass clink, shutter, temple bell at dawn, crowd murmur in the rushes, bubble pops, oil splash, a cheer and a radio jingle.
- **Chennai:** a different kolam every day, festivals on the calendar, a film poster wall and Friday cutouts, an auto stand, radio songs and weekend cricket, Tanglish chatter and a glossary.
- **Pixel art:** people and items painted pixel by pixel in code with shading and outlines.


## Round 9: more like Cookie Clicker (2026-11-14)

Playtest: money pace felt right, golden glasses were loved, everything new was liked. The shutter between every screen got tiresome.

- Shutter only when opening and closing the kadai; a quick fade elsewhere.
- Long wooden benches on the pavement instead of plastic chairs, like a real Chennai tea kadai.
- Helper upgrade tiers at 1/10/25/50/100 owned, each doubling that helper (replacing the three per-helper boosts; old saves keep them as tier one).
- 40 achievements, +1% each to helper income and tips, with a trophy note during the day and a Trophies tab.
- Big Indian numbers (lakh to padma): a banner and cheer, a newspaper story, and a grander kadai each time.
- A Stats tab; helpers visible on the street; a news ticker on the title screen and in the morning paper.
- Clicking a big cookie-like object was considered and skipped: serving stays the clicking.

## Next up

In order:

1. **Calm-down pass:** the decisions above, bigger bubbles, a simpler bottom panel, and a window that isn't tiny on Retina screens.
2. **Sound (first pass done):** synthesized placeholders for the pour, fill, perfect pour, oil sizzle, vadai chime, coins, grumbles, crows, auto horns, bicycle bells, street rumble, and day and night music in Mohanam with a tanpura drone. Real recordings or a composer can replace the files later.
3. **First regular (done):** Karthik, see round 3 above. A second regular could follow the same pattern in `story.gd`.
4. **Save + Mac build:** days save between sessions, plus a double-clickable `.app`.
5. **Pixel art pass:** sprites for people, the stall, and props, replacing the drawn shapes. Customers get faces and a bit of personality (a wave, a sip, a nod).
6. **A goal for the day:** a small daily target shown in the morning ("Serve 20 people", "Earn ₹300"), plus something to save up for across the week.

### Ideas parked for later

- **Rain shower:** a sudden rain mid-day brings a rush of tea drinkers who huddle under the awning.
- **Radio on the shelf:** click to switch stations. Pure mood, no pressure.
- **Afternoon chit-chat:** in the quiet afternoon, customers linger and gossip in speech bubbles. This is where stories and events start.
- **Tip jar:** a jar on the counter that fills up as you earn tips.
- **Night upgrades:** spend profit on a fan (customers stay calm longer), a bench (one more seat), or a tube light (busier evenings).
- **Pour streaks:** a little celebration for three perfect pours in a row.
- **The milkman:** a vendor on a bicycle at the morning market instead of a plain list.
- **End-of-day photo:** a snapshot of your kadai at closing, to share.

## Open questions for later

- Does the radio play original songs, talk shows, cricket commentary, or a mix?
- How are helpers paid: a daily wage, or a share of sales?
- Where do the Daily challenge leaderboards live: Steam's own, or a small server of our own?
- Is there one ending, or does it change based on choices with the regulars?
