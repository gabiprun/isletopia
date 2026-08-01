#!/bin/bash
# Store the Isletopia Play upload key in KeyVault.
#
# The master passphrase is collected from you at run time (TTY prompt, or a
# macOS dialog when there is no TTY) and is never written anywhere. The signing
# password and keystore are read from disk, so neither is typed or echoed.
#
# Run:  bash ~/Desktop/isletopia/tools/push_key_to_keyvault.sh
set -euo pipefail

KV_DIR="$HOME/Desktop/Vibe coded projects/keyvault"
SECRETS="$HOME/.config/keystore-backup/ISLETOPIA-SIGNING.txt"
KEYSTORE="$HOME/Desktop/isletopia/isletopia-release.jks"
NAME="isletopia-signing"

[ -d "$KV_DIR" ]   || { echo "KeyVault not found at $KV_DIR"; exit 1; }
[ -f "$SECRETS" ]  || { echo "Secrets file missing: $SECRETS"; exit 1; }
[ -f "$KEYSTORE" ] || { echo "Keystore missing: $KEYSTORE"; exit 1; }

PW=$(grep '^store/key password:' "$SECRETS" | sed 's/^store\/key password: //')
[ -n "$PW" ] || { echo "Could not read the signing password"; exit 1; }

# sanity: the password on file must actually open the keystore
if ! keytool -list -keystore "$KEYSTORE" -storepass "$PW" >/dev/null 2>&1; then
  echo "Refusing to store: the recorded password does not open the keystore."
  exit 1
fi

CERT=$(keytool -list -v -keystore "$KEYSTORE" -alias isletopia -storepass "$PW" 2>/dev/null \
       | grep 'SHA256:' | head -1 | sed 's/.*SHA256: //' | tr -d ' ')
B64=$(base64 < "$KEYSTORE" | tr -d '\n')

# --- master passphrase, from you, never from a file ---
if [ -t 0 ]; then
  read -r -s -p "KeyVault master passphrase: " KEYVAULT_PASSPHRASE; echo
else
  KEYVAULT_PASSPHRASE=$(osascript -e \
    'display dialog "KeyVault master passphrase" default answer "" with hidden answer buttons {"OK"} default button "OK"' \
    -e 'text returned of result' 2>/dev/null) || true
fi
[ -n "${KEYVAULT_PASSPHRASE:-}" ] || { echo "No passphrase entered; nothing stored."; exit 1; }
export KEYVAULT_PASSPHRASE

cd "$KV_DIR"
python3 cli.py set "$NAME" \
  --field "password=$PW" \
  --field "alias=isletopia" \
  --field "package=com.Isletopia" \
  --field "keystore_path=$KEYSTORE" \
  --field "cert_sha256=$CERT" \
  --field "keystore_b64=$B64" \
  --tags "android,signing,play,isletopia" \
  --notes "Play upload key for Isletopia (com.Isletopia). PKCS12: store and key password are the same - rotate with 'keytool -storepasswd' only. Restore the keystore with: base64 -d <<< \"\$keystore_b64\" > isletopia-release.jks. Losing this key means the app can never be updated again."

unset KEYVAULT_PASSPHRASE PW B64
echo
echo "Stored as '$NAME'. Verify with:  cd \"$KV_DIR\" && python3 cli.py list"
