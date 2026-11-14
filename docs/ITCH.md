# Putting Tea Kadai on itch.io

Once two settings are in place, every release also goes to itch.io, through [butler](https://itch.io/docs/butler/), itch's upload tool. Until then the step skips itself.

## Set it up

1. Make an [itch.io account](https://itch.io/register) if you don't have one.
2. Create the game page: [itch.io/game/new](https://itch.io/game/new).
   - **Title:** Tea Kadai
   - **Project URL:** `tea-kadai` (so the page is `https://<your-name>.itch.io/tea-kadai`)
   - **Kind of project:** Downloadable
   - **Pricing:** No payments (or "Donate" if you'd like a tip jar)
   - Paste in the page text below, add the screenshots, and save it as a draft.
3. Make an API key: [itch.io/user/settings/api-keys](https://itch.io/user/settings/api-keys) → **Generate new API key**.
4. Give the repo the key and the game's name:

```bash
gh secret set BUTLER_API_KEY
```

```bash
gh variable set ITCH_GAME --body "<your-itch-name>/tea-kadai"
```

5. Push anything to `main` (or re-run the latest workflow). The release uploads to three channels, `mac`, `windows` and `linux`, and itch tags each one with its platform by itself.
6. On the page's **Uploads** list, check each file is marked for the right platform, then set the page to **Public**.

The itch builds are the same files as the GitHub releases. The itch app keeps them updated, and the game's own updater does too; the two don't get in each other's way.

## Page text

**Short description** (shown under the title in listings)

> Run a little tea kadai on a busy Chennai street. Pour, fry, and grow it into a tea empire.

**Genre:** Simulation. **Tags:** cozy, pixel-art, shop, management, idle, incremental, clicker, india, chennai, tea, singleplayer.

**Description**

> Every morning the shutter rolls up on a little tea kadai on a busy Chennai street.
>
> Buy milk and tea dust at the market, then open up. Make tea and pour it from up high, letting go in the green for the perfect glass. Fry vadai and bajji and lift them out when they turn golden. Serve auto drivers, students, nurses, office folks and the retired uncle who's been coming for years.
>
> As the money comes in, grow: hire flask boys, office tea runners and a cart at the bus stand who earn while you pour. Catch the golden glass for a frenzy. Open branches across the city, from Triplicane to Kodambakkam.
>
> - Pour, fry and serve through the morning rush, a quiet afternoon and the evening crowd
> - Regulars with their own stories, like Karthik the student and Murugan the auto driver
> - Helpers, staff, upgrades and 40 trophies to collect, from one lakh to one padma
> - A new kolam every morning, film posters on Fridays, cricket on the radio, Karthigai Deepam and Pongal
> - Tamil and Tanglish all the way, with a glossary when you need it
> - Pixel art and music made for the game, and it's free and open source
>
> Mac, Windows and Linux.

## Screenshots

From `website/public/screenshots/`, in this order: `title.png`, `morning-rush.png`, `grow.png`, `market.png`, `night.png`, and `rainy-rush.gif` as the cover-style animation. For the **cover image** (630×500), crop `title.png`. The trailer from `tools/make_trailer.gd` can go in the page's video slot once it's on YouTube.
