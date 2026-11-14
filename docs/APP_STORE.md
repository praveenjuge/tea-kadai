# Putting Tea Kadai on the Mac App Store

The App Store build is made on your Mac (Apple's packaging needs Xcode), from the `macOS App Store` export preset, by `tools/build_app_store.sh`. It differs from the GitHub build in three ways:

- It runs in Apple's sandbox. Its save lives in the app's container, and share cards save to **Downloads**, since sandboxed apps can't write to the Desktop. (Godot's Pictures option writes an entitlement key Apple rejects, so Downloads it is.)
- It never updates itself or touches the network; the App Store updates it. The feedback button still works, because it only opens the browser.
- It's signed for the App Store and packaged as a `.pkg`.

A sandboxed test build of this preset has been run on this Mac and plays normally.

## One-time setup (done)

- **App ID:** `teakadai.praveenjuge.game`, registered as "Tea Kadai".
- **Installer certificate:** "3rd Party Mac Developer Installer: Juge Praveen", in the login keychain, valid until 14 November 2027.
- **Provisioning profile:** "Tea Kadai App Store" (Mac App Store Connect, with the Apple Distribution certificate in the keychain), saved at `~/Documents/Apple/TeaKadai_AppStore.provisionprofile`, valid until August 2027.
- **App record:** "Tea Kadai: Chennai Chai" (plain "Tea Kadai" is taken on the App Store), Apple ID 6834836627, SKU `tea-kadai`. The listing text, category, 4+ age rating, free pricing, "Data Not Collected" privacy answers, the [privacy page](https://tea-kadai.praveenjuge.com/privacy.html) and five screenshots from `docs/app-store/` are filled in.

## Each release, from CI

Every push to `main` also goes to the Mac App Store, in the `app-store` job of `.github/workflows/release.yml`, once its secrets are set. After the GitHub release is out, a Mac runner builds the package with `tools/build_app_store.sh`, uploads it, and `tools/app_store_submit.py` puts it up for review:

- If an older version is waiting for or in review, its submission is canceled and the same version is renumbered to the new build. Apple only reviews one version at a time, so the newest release is always the one in review.
- If the current version is live, it makes the next version, with the release's commit messages as "What's New".
- Versions go live as soon as Apple approves them.

To turn it on, run this once on the Mac with the signing certificates, with an App Store Connect API key that has the **App Manager** or **Admin** role (the "Tea Kadai CI" key is Developer, which can upload but not submit). macOS asks you to allow exporting the two signing identities:

```bash
tools/setup_app_store_secrets.sh <path to AuthKey_XXXXXXXXXX.p8> <key id> <issuer id>
```

`tools/app_store_submit.py --dry-run` shows what it would do without changing anything.

## By hand

```bash
export APPLE_TEAM_ID=XXXXXXXXXX
export APPSTORE_PROFILE=~/Documents/Apple/TeaKadai_AppStore.provisionprofile
tools/build_app_store.sh
```

Your team ID is the 10 characters in brackets after your name in Keychain Access, or on the [Membership page](https://developer.apple.com/account#MembershipDetailsCard).

The script uses the latest release tag as the version and the commit count as the build number, so each upload is higher than the last. It puts `project.godot` and `export_presets.cfg` back as they were when it's done. Then upload it, either by dragging `build/TeaKadai-AppStore.pkg` into the Transporter app and clicking **Deliver**, or with an App Store Connect API key:

```bash
xcrun altool --upload-package build/TeaKadai-AppStore.pkg --type macos --apple-id 6834836627 \
  --bundle-id teakadai.praveenjuge.game --bundle-version <build> --bundle-short-version-string <version> \
  --apiKey <key id> --apiIssuer <issuer id>
```

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
