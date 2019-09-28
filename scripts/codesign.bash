#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [[ -z $1 ]]; then
  echo "Usage: $0 [codesign name]"
  exit 1
fi

CODESIGN_NAME="$1"

# check exist
if security find-identity -v | grep "$CODESIGN_NAME" > /dev/null 2>&1; then
  echo "already exist $CODESIGN_NAME"
  exit 1
fi

cat <<EOF > "$CODESIGN_NAME".cfg
[ req ]
default_bits            = 4096                  # RSA key size
encrypt_key             = no                    # Protect private key
default_md              = sha512                # MD to use
prompt                  = no                    # Prompt for DN
distinguished_name      = codesign_dn           # DN template
[ codesign_dn ]
commonName              = "$CODESIGN_NAME"
[ codesign_reqext ]
keyUsage                = critical,digitalSignature
extendedKeyUsage        = critical,codeSigning
EOF

openssl req -new -newkey rsa:4096 -x509 -days 7300 -nodes -config "$CODESIGN_NAME.cfg" -extensions codesign_reqext -batch -out "$CODESIGN_NAME.cer" -keyout "$CODESIGN_NAME.key"
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CODESIGN_NAME.cer"
sudo security import "$CODESIGN_NAME.key" -A -k /Library/Keychains/System.keychain

# restart(reload) taskgated daemon
sudo pkill -f /usr/libexec/taskgated
