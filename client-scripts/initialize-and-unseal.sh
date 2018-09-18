#!/usr/bin/env bash
set -e

# init vault
echo "INFO: init Vault"
vault operator init | tee init.output
IFS=$'\r\n' GLOBIGNORE='*' command eval \
  "UNSEAL_KEYS=($(cat init.output | grep '^Unseal' | rev | cut -d ' ' -f 1 | rev))"

# export root token
export ROOT_TOKEN=$(cat init.output | grep '^Initial' | rev | cut -d ' ' -f 1 | rev)
export VAULT_TOKEN=$ROOT_TOKEN

# unseal vault
#  0 - unsealed
#  1 - error
#  2 - sealed
echo "INFO: unseal Vault"
KEY_INDEX=0
while [[ $(vault status > /dev/null)$? != 0 ]]; do
  vault operator unseal $(echo "${UNSEAL_KEYS[$KEY_INDEX]}")
  KEY_INDEX=$(( $KEY_INDEX + 1 ))
done
vault status

echo "INFO: Vault has been unsealed"
env | grep VAULT

exit 0;