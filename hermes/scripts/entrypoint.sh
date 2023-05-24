#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CRYPTO_ORG_CHAIN_BLOCK_PENDING=true
while [[ $CRYPTO_ORG_CHAIN_BLOCK_PENDING == "true" ]]; do
    sleep 1
    CRYPTO_ORG_CHAIN_BLOCK_PENDING=$(curl http://crypto-org-chain-validator0:26657/block?height=1 | jq 'has("error")')
done
CRONOS_BLOCK_PENDING=true
while [[ $CRONOS_BLOCK_PENDING == "true" ]]; do
    sleep 1
    CRONOS_BLOCK_PENDING=$(curl http://cronos-validator0:26657/block?height=1 | jq 'has("error")')
done

set +e
CHANNEL_SIZE=$(./bin/hermes --json query channels --chain=$CRYPTO_ORG_CHAIN_ID | tail -1 | jq '.result | length')
set -e
if [[ $CHANNEL_SIZE -eq 0 ]]; then
    /app/bin/hermes create channel \
        --a-chain $CRYPTO_ORG_CHAIN_ID \
        --b-chain $CRONOS_CHAIN_ID \
        --a-port transfer \
        --b-port transfer \
        --new-client-connection --yes
fi

/app/bin/hermes start
