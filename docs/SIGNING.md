# Signing the Mac and Windows builds

The release workflow signs each build once its secrets are in place. Until then it keeps shipping unsigned builds, so you can set up one platform at a time.

## Mac: Apple Developer ID and notarization

The workflow signs `Tea Kadai.app` with your Developer ID, has Apple notarize it, staples the ticket, and zips it back up. It uses [rcodesign](https://gregoryszorc.com/docs/apple-codesign/main/), so it all runs on the Linux build machine.

**Set up on 14 November 2026.** The builds use their own Developer ID Application certificate (ID `53A3ZXVPVC`), separate from the one on your Mac, so it can be revoked without touching anything else. It expires on **14 December 2027**: make a new one before then and update `MACOS_CERTIFICATE_P12` and `MACOS_CERTIFICATE_PASSWORD`. Notarization uses the App Store Connect team key "Tea Kadai CI" (`YDN265645T`, Developer access).

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) ($99 a year).
2. Make a **Developer ID Application** certificate:
   1. On your Mac, open **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority**. Fill in your email, pick **Saved to disk**, and save the request.
   2. In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list), click **+**, choose **Developer ID Application**, upload the request, and download the certificate.
   3. Double-click it to add it to Keychain Access. Under **My Certificates**, right-click **Developer ID Application: …**, choose **Export**, and save it as a `.p12` with a password.
3. Make an App Store Connect API key for notarization: in [App Store Connect](https://appstoreconnect.apple.com/access/integrations/api), go to **Users and Access → Integrations → App Store Connect API → Team Keys**, click **+**, and give it **Developer** access. Download the `AuthKey_….p8` file (Apple only lets you download it once), and note the **Issuer ID** and **Key ID**.
4. Add the secrets to the repo:

```bash
base64 -i DeveloperID.p12 | gh secret set MACOS_CERTIFICATE_P12
gh secret set MACOS_CERTIFICATE_PASSWORD
gh secret set APPLE_API_ISSUER_ID
gh secret set APPLE_API_KEY_ID
gh secret set APPLE_API_PRIVATE_KEY < AuthKey_XXXXXXXXXX.p8
```

The next push to `main` makes a signed, notarized Mac release. If notarization fails, the step's log has the submission ID; `rcodesign notary-log` shows why.

## Windows: SignPath Foundation

**Not applied yet.** SignPath Foundation wants executables to have a verifiable reputation, decides at its discretion and has no appeal, so the plan is to apply once the game has some traction (stars, downloads, posts about it) rather than as a brand-new repo.

[SignPath Foundation](https://signpath.org/) signs open source projects for free. The certificate is theirs, so Windows shows "SignPath Foundation" as the publisher. Their rules are on [signpath.org/terms](https://signpath.org/terms). The ones that matter here:

- Two-factor login on GitHub and SignPath for everyone on the project.
- A code signing policy page linked from the download page. That's [tea-kadai.praveenjuge.com/code-signing](https://tea-kadai.praveenjuge.com/code-signing), linked in the site's footer. Once signing is live, remove the "Signing starts once…" line there.
- Every release is approved by hand in SignPath before it's signed.
- The exe carries the product name and version. The workflow stamps both (`Tea Kadai`, and the release version).

Steps:

1. [Apply on signpath.org](https://signpath.org/apply) with the repo link. They review each project.
2. Once accepted, in SignPath:
   1. Set the project slug to `tea-kadai` and link it to the predefined **GitHub.com** trusted build system.
   2. Use the signing policy slug `release-signing`. The workflow expects these two slugs; change them in `.github/workflows/release.yml` if yours differ.
   3. The workflow uploads a zip with `TeaKadai-Windows.exe` at its root, so the artifact configuration should be a `<zip-file>` holding a `<pe-file path="TeaKadai-Windows.exe">` with `<authenticode-sign/>`.
   4. Create an API token for a user with the submitter role on that project and policy.
3. Add the token and your organization ID to the repo:

```bash
gh secret set SIGNPATH_API_TOKEN
gh variable set SIGNPATH_ORGANIZATION_ID
```

From then on, each release run stops at **Sign the Windows exe with SignPath** and waits up to an hour for you to approve the request in SignPath. Then it publishes the signed exe.

Signing doesn't make the SmartScreen warning vanish right away: it fades as signed releases build up a reputation ([Microsoft's notes](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation)).

## After both are live

The Mac steps are already gone from the website and README. Once Windows is signed too, drop the SmartScreen note from the "Opening it the first time" section on the website (`website/public/index.html`) and from the Install section in the README.
