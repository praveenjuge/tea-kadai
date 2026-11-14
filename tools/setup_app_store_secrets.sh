#!/usr/bin/env bash
# One-time setup so every release goes to the Mac App Store from CI.
# Run it on the Mac that has the signing certificates in its login keychain:
#
#   tools/setup_app_store_secrets.sh <path to AuthKey_XXXXXXXXXX.p8> <key id> <issuer id>
#
# The API key must have the App Manager or Admin role (App Store Connect →
# Users and Access → Integrations), since CI submits versions for review.
#
# It exports only the "Apple Distribution" and "3rd Party Mac Developer
# Installer" identities (macOS asks you to allow each export), and sets these
# repository secrets with gh, without printing any of them:
#   APPSTORE_APP_CERTIFICATE_P12, APPSTORE_INSTALLER_CERTIFICATE_P12,
#   APPSTORE_CERTIFICATES_PASSWORD, APPSTORE_PROVISIONING_PROFILE,
#   APPSTORE_API_KEY_ID, APPSTORE_API_ISSUER_ID, APPSTORE_API_PRIVATE_KEY

set -euo pipefail
cd "$(dirname "$0")/.."

key_file="${1:?Usage: $0 <AuthKey_XXXX.p8> <key id> <issuer id>}"
key_id="${2:?Give the API key ID}"
issuer_id="${3:?Give the issuer ID}"
profile="${APPSTORE_PROFILE:-$HOME/Documents/Apple/TeaKadai_AppStore.provisionprofile}"
repo="praveenjuge/tea-kadai"
[ -f "$key_file" ] || { echo "No API key at $key_file"; exit 1; }
[ -f "$profile" ] || { echo "No provisioning profile at $profile"; exit 1; }

work=$(mktemp -d)
chmod 700 "$work"
trap 'rm -rf "$work"' EXIT
password=$(openssl rand -hex 24)

# Export every identity, then keep only the two this needs, one .p12 each.
echo "Exporting signing identities; allow it when macOS asks."
security export -k "$HOME/Library/Keychains/login.keychain-db" -t identities -f pkcs12 \
	-P "$password" -o "$work/all.p12"
openssl pkcs12 -in "$work/all.p12" -nodes -legacy -passin "pass:$password" -out "$work/all.pem" 2>/dev/null

python3 - "$work" <<'PY'
import re, sys
work = sys.argv[1]
text = open(f"{work}/all.pem").read()
blocks = re.findall(r"Bag Attributes(.*?)(-----BEGIN ([A-Z ]+)-----.*?-----END \3-----)", text, re.S)
wanted = {"app": "Apple Distribution: ", "installer": "3rd Party Mac Developer Installer: "}
certs, keys = {}, {}
for attributes, pem, kind in blocks:
    key_id = re.search(r"localKeyID: ([0-9A-F ]+)", attributes)
    if not key_id:
        continue
    key_id = key_id.group(1).strip()
    if kind == "CERTIFICATE":
        name = re.search(r"friendlyName: (.*)", attributes)
        if name:
            certs[key_id] = (name.group(1).strip(), pem)
    else:
        keys[key_id] = pem
for label, prefix in wanted.items():
    found = [(k, c) for k, c in certs.items() if c[0].startswith(prefix) and k in keys]
    if not found:
        sys.exit(f"Couldn't find the '{prefix.strip(': ')}' identity in the login keychain.")
    key_id, (name, cert) = found[0]
    open(f"{work}/{label}.pem", "w").write(cert + "\n" + keys[key_id] + "\n")
    print(f"Found {name.split('(')[0].strip()}")
PY

for label in app installer; do
	openssl pkcs12 -export -legacy -in "$work/$label.pem" -out "$work/$label.p12" -passout "pass:$password"
done

base64 -i "$work/app.p12" | gh secret set APPSTORE_APP_CERTIFICATE_P12 --repo "$repo"
base64 -i "$work/installer.p12" | gh secret set APPSTORE_INSTALLER_CERTIFICATE_P12 --repo "$repo"
printf '%s' "$password" | gh secret set APPSTORE_CERTIFICATES_PASSWORD --repo "$repo"
base64 -i "$profile" | gh secret set APPSTORE_PROVISIONING_PROFILE --repo "$repo"
printf '%s' "$key_id" | gh secret set APPSTORE_API_KEY_ID --repo "$repo"
printf '%s' "$issuer_id" | gh secret set APPSTORE_API_ISSUER_ID --repo "$repo"
gh secret set APPSTORE_API_PRIVATE_KEY --repo "$repo" < "$key_file"

echo "Done. The next push to main also goes to the Mac App Store."
