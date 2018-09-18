#!/usr/bin/env bash
set -e

if [[ $# -ne 1 ]]; then
    echo "ERROR: must include path to input file"
    exit 2;
elif [[ ! -e $1 ]]; then
    echo "ERROR: specified file does not exist"
    exit 3;
fi

while read secret; do
    if [[ -n "$secret" && "$secret" != [[:blank:]#]* ]]; then
        VAULT_CMD='vault kv put '$secret
        echo $VAULT_CMD
        $VAULT_CMD
    fi
done < <(cat $1)

exit 0;