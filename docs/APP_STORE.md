# Putting Tea Kadai on the Mac App Store

The App Store build is made on your Mac (Apple's packaging needs Xcode), from the `macOS App Store` export preset, by `tools/build_app_store.sh`. It differs from the GitHub build in three ways:

- It runs in Apple's sandbox. Its save lives in the app's container, and share cards save to **Pictures**, since sandboxed apps can't write to the Desktop.
- It never updates itself or touches the network; the App Store updates it. The feedback button still works, because it only opens the browser.
- It's signed for the App Store and packaged as a `.pkg`.

A sandboxed test build of this preset has been run on this Mac and plays normally.

## One-time setup

You already have the Apple Developer Program and an **Apple Distribution** certificate in your keychain.

1. **App ID.** In [Identifiers](https://developer.apple.com/account/resources/identifiers/list), click **+** → **App IDs** → **App**. Platform macOS, description "Tea Kadai", explicit bundle ID `teakadai.praveenjuge.game`. No capabilities needed.
2. **Installer certificate.** In [Certificates](https://developer.apple.com/account/resources/certificates/list), click **+** → **Mac Installer Distribution**. Upload a certificate request (Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority, saved to disk), download the certificate and double-click it. It shows in your keychain as **3rd Party Mac Developer Installer: …**.
3. **Provisioning profile.** In [Profiles](https://developer.apple.com/account/resources/profiles/list), click **+** → **Mac App Store Connect** (under Distribution), pick the `teakadai.praveenjuge.game` App ID and your Apple Distribution certificate, name it "Tea Kadai App Store", and download the `.provisionprofile`. Keep it somewhere stable, like `~/Documents/Apple/TeaKadai_AppStore.provisionprofile`.
4. **App record.** In [App Store Connect](https://appstoreconnect.apple.com/apps), click **+** → **New App**: platform macOS, name "Tea Kadai", primary language English (UK or US), bundle ID `teakadai.praveenjuge.game`, SKU `tea-kadai`.
5. **Transporter.** Install [Transporter](https://apps.apple.com/app/transporter/id1450874784) from the Mac App Store and sign in with your Apple ID.

## Each release

```bash
export APPLE_TEAM_ID=XXXXXXXXXX
export APPSTORE_PROFILE=~/Documents/Apple/TeaKadai_AppStore.provisionprofile
tools/build_app_store.sh
```

Your team ID is the 10 characters in brackets after your name in Keychain Access, or on the [Membership page](https://developer.apple.com/account#MembershipDetailsCard).

The script uses the latest release tag as the version and the commit count as the build number, so each upload is higher than the last. It puts `project.godot` and `export_presets.cfg` back as they were when it's done.

Then open Transporter, drag in `build/TeaKadai-AppStore.pkg` and click **Deliver**. After a few minutes the build appears under the app's **TestFlight** tab and can be added to a version for review.

## The store listing

- **Name:** Tea Kadai
- **Subtitle:** A Chennai tea stall sim
- **Category:** Games, with Simulation and Casual as game categories
- **Price:** Free
- **Age rating:** 4+ (no objectionable content)
- **Privacy:** "Data Not Collected". The App Store build has no network access at all.
- **Description:** use the one in [docs/ITCH.md](ITCH.md).
- **Keywords:** tea,chai,chennai,india,shop,cozy,idle,clicker,pixel,kadai
- **Support URL:** https://github.com/praveenjuge/tea-kadai/issues
- **Marketing URL:** https://tea-kadai.praveenjuge.com
- **Screenshots:** the Mac App Store wants 16:10 shots (2880×1800 or 1440×900). Run the game in a window that size and take them with ⇧⌘5, or ask Claude to add a 16:10 mode to `tools/take_screenshots.gd`.

Review usually takes a day or two. A common first-time request is a fuller description of what the app does; the itch text covers it.
