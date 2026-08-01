#!/bin/bash
# Store the Isletopia Play upload key in KeyVault over the HTTP API.
#
# Reads a write-scoped API token from ~/.config/keyvault/token (chmod 600),
# the same pattern as ~/.config/cloudflare/token. No master passphrase needed:
# a token without the `read` scope seals its writes to the vault's X25519
# public key, so it can deposit into a locked vault and never decrypt one.
#
# Mint the token first (this part needs your master passphrase, so you run it):
#   cd ~/Desktop/Vibe\ coded\ projects/keyvault
#   python3 cli.py token create isletopia-signing --scopes write --pattern 'isletopia-*'
#   mkdir -p ~/.config/keyvault
#   printf '%s' 'kv_…' > ~/.config/keyvault/token && chmod 600 ~/.config/keyvault/token
#
# Then run:  bash ~/Desktop/isletopia/tools/keyvault_api_push.sh
set -euo pipefail

BASE="${KEYVAULT_URL:-https://key.prundaru.ca}"
TOKEN_FILE="$HOME/.config/keyvault/token"
SECRETS="$HOME/.config/keystore-backup/ISLETOPIA-SIGNING.txt"
KEYSTORE="$HOME/Desktop/isletopia/isletopia-release.jks"
NAME="isletopia-signing"

[ -f "$TOKEN_FILE" ] || { echo "No API token at $TOKEN_FILE — see the header of this script."; exit 1; }
[ -f "$SECRETS" ]    || { echo "Secrets file missing: $SECRETS"; exit 1; }
[ -f "$KEYSTORE" ]   || { echo "Keystore missing: $KEYSTORE"; exit 1; }

KV=$(tr -d '\r\n' < "$TOKEN_FILE")
PW=$(grep '^store/key password:' "$SECRETS" | sed 's/^store\/key password: //')
[ -n "$PW" ] || { echo "Could not read the signing password"; exit 1; }

# never archive a password that does not actually open the keystore
if ! keytool -list -keystore "$KEYSTORE" -storepass "$PW" >/dev/null 2>&1; then
  echo "Refusing to store: the recorded password does not open the keystore."
  exit 1
fi

CERT=$(keytool -list -v -keystore "$KEYSTORE" -alias isletopia -storepass "$PW" 2>/dev/null \
       | grep 'SHA256:' | head -1 | sed 's/.*SHA256: //' | tr -d ' ')
B64=$(base64 < "$KEYSTORE" | tr -d '\n')

BODY=$(PW="$PW" CERT="$CERT" B64="$B64" KEYSTORE="$KEYSTORE" NAME="$NAME" python3 -c '
import json, os
print(json.dumps({
    "name": os.environ["NAME"],
    "fields": {
        "password":      os.environ["PW"],
        "alias":         "isletopia",
        "package":       "com.Isletopia",
        "keystore_path": os.environ["KEYSTORE"],
        "cert_sha256":   os.environ["CERT"],
        "keystore_b64":  os.environ["B64"],
    },
    "tags": ["android", "signing", "play", "isletopia"],
    "notes": ("Play upload key for Isletopia (com.Isletopia). PKCS12: store and key "
              "password are identical - rotate with keytool -storepasswd only. Restore: "
              "base64 -d <<< \"$keystore_b64\" > isletopia-release.jks. "
              "Lose this key and the app can never be updated again."),
}))')

CODE=$(printf '%s' "$BODY" | curl -sS -o /tmp/kv_resp.json -w '%{http_code}' \
  -X POST "$BASE/api/secrets" \
  -H "Authorization: Bearer $KV" -H 'Content-Type: application/json' \
  --data-binary @-)

unset KV PW B64
if [ "$CODE" = "200" ] || [ "$CODE" = "201" ]; then
  echo "Stored '$NAME' in KeyVault ($BASE)."
else
  echo "Failed: HTTP $CODE"
  head -c 400 /tmp/kv_resp.json; echo
  rm -f /tmp/kv_resp.json
  exit 1
fi
rm -f /tmp/kv_resp.json
