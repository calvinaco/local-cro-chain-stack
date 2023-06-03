#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CRYPTO_ORG_CHAIN_ID=$(cat /app/crypto-org-chain/home/config/genesis.json | jq -r '.chain_id')
GAS_PRICES=$(toml get /app/.hermes/config.toml . | jq --arg crypto_org_chain_id $CRYPTO_ORG_CHAIN_ID -r \
    '.chains[] | select(.id==$crypto_org_chain_id) | (.gas_price.price|tostring)+.gas_price.denom')

ADDRESS=$(/app/cronos/chain/bin/cronosd --home=/app/cronos/home \
    keys list --keyring-backend=test \
    --output=json | jq -r '.[] | select(.name == "relayer-keepalive") | .address')
/app/crypto-org-chain/chain/bin/chain-maind --home=/app/crypto-org-chain/home \
    tx ibc-transfer transfer \
    transfer channel-0 $ADDRESS 1basecro \
    --from=relayer-keepalive \
    --keyring-backend=test \
    --chain-id=$CRYPTO_ORG_CHAIN_ID \
    --gas-prices=$GAS_PRICES --gas=auto --gas-adjustment=1.5 \
    --keyring-backend=test \
    --node=http://crypto-org-chain-validator0:26657 \
    --broadcast-mode=block \
    -y