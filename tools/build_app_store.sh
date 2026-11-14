#!/usr/bin/env bash
# Builds the Mac App Store package, build/TeaKadai-AppStore.pkg, on a Mac with
# Xcode. See docs/APP_STORE.md for the one-time Apple setup.
#
# Your Apple details come from the environment, so nothing personal is
# committed:
#   APPLE_TEAM_ID          your 10-character team ID
#   APPSTORE_PROFILE       path to the Mac App Store .provisionprofile
#   APPSTORE_IDENTITY      app signing certificate (default "Apple Distribution")
#   APPSTORE_INSTALLER     installer certificate (default "3rd Party Mac Developer Installer")
#
# The version is the latest release tag; the build number counts commits, so
# every upload is higher than the last, as App Store Connect requires.

set -euo pipefail
cd "$(dirname "$0")/.."

: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID (see docs/APP_STORE.md)}"
: "${APPSTORE_PROFILE:?Set APPSTORE_PROFILE to your .provisionprofile}"
APPSTORE_IDENTITY="${APPSTORE_IDENTITY:-Apple Distribution}"
APPSTORE_INSTALLER="${APPSTORE_INSTALLER:-3rd Party Mac Developer Installer}"
[ -f "$APPSTORE_PROFILE" ] || { echo "No provisioning profile at $APPSTORE_PROFILE"; exit 1; }

git fetch --tags --quiet origin || true
version=$(git tag --list 'v*.*.*' --sort=-v:refname | head -n 1)
version="${version#v}"
version="${version:-0.1.0}"
build=$(git rev-list --count HEAD)
echo "Building Tea Kadai $version ($build) for the Mac App Store"

# Stamp the version and signing details into copies of the settings, and put
# the originals back however this ends.
backup=$(mktemp -d)
cp project.godot export_presets.cfg "$backup/"
restore() {
	cp "$backup/project.godot" "$backup/export_presets.cfg" .
	rm -rf "$backup" version.txt
}
trap restore EXIT

echo "$version" > version.txt
sed -i '' "s/^config\/version=.*/config\/version=\"$version\"/" project.godot
python3 - "$version" "$build" "$APPLE_TEAM_ID" "$APPSTORE_PROFILE" "$APPSTORE_IDENTITY" "$APPSTORE_INSTALLER" <<'PY'
import re, sys
version, build, team, profile, identity, installer = sys.argv[1:]
text = open("export_presets.cfg").read()
start = text.index('name="macOS App Store"')
head, section = text[:start], text[start:]
values = {
    "application/short_version": version,
    "application/version": build,
    "codesign/apple_team_id": team,
    "codesign/provisioning_profile": profile,
    "codesign/identity": identity,
    "codesign/installer_identity": installer,
}
for key, value in values.items():
    section = re.sub(rf'^{re.escape(key)}=.*$', f'{key}="{value}"', section, count=1, flags=re.M)
open("export_presets.cfg", "w").write(head + section)
PY

mkdir -p build
godot --headless --path . --import >/dev/null
godot --headless --path . --export-release "macOS App Store" build/TeaKadai-AppStore.pkg
pkgutil --check-signature build/TeaKadai-AppStore.pkg
echo
echo "Ready: build/TeaKadai-AppStore.pkg. Upload it with the Transporter app."
