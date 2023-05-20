#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

echoerr() {
    echo "$@" 1>&2;
    echo 1>&2;
    helpFunction 1>&2;
    exit 1;
}

helpFunction() {
    cat << EOF
Usage: $0 docker-image assets-folder output-folder

Arguments:
    docker-image:                       The chain docker image to use to initialize the home folder.
    assets-folder:                      The working folder for assets.
    output-folder:                      The folder to output the home folder to.

Flags:
    --chain-id:                         The chain ID to initialize the home. Default: "cronoslocal_65536-1"
    --validator-initial-delegation:     The amount of stake to delegate to the validator. Note amount must be greater
                                        than the default power reduction of 1000000. Default: 100000000
    --validator-count:                  The number of validators to generate. Default: 2
    --basecro:                          The basecro denom. Default: "basecro"
    --debug:                            Enable debug mode. Default: false
    --help:                             Show this help message
EOF
    exit 1
}

if [[ ! -x "$(command -v jq)" ]]; then
    echoerr "jq is required. Please install jq first."
fi

DEBUG=0
VALIDATOR_COUNT=2
CHAIN_ID=cronoslocal_65536-1
VALIDATOR_INITIAL_DELEGATION_AMOUNT=100000000
BASECRO_DENOM=basecro
while [[ $# > 0 ]]; do
    case "$1" in
        --debug)
            DEBUG=1
            set -x
            shift 1 
        ;;
        --help)
            helpFunction
        ;;
        --chain-id)
            CHAIN_ID=$2
            shift 2
        ;;
        --validator-count)
            VALIDATOR_COUNT=$2
            shift 2
        ;;
        --validator-initial-delegation)
            VALIDATOR_INITIAL_DELEGATION_AMOUNT=$2
            shift 2
        ;;
        --basecro-denom)
            BASECRO_DENOM=$2
            shift 2
        ;; 
        *)
            if [[ $# -ne 3 ]]; then
                echoerr "Expected 3 arguments"
            fi
            DOCKER_IMAGE=$1
            ASSETS_ROOTDIR=$2
            OUTPUT_FOLDER=$3
            shift 3
        ;;
    esac
done
VALIDATOR_INITIAL_DELEGATION=${VALIDATOR_INITIAL_DELEGATION_AMOUNT}stake

if [[ -z ${DOCKER_IMAGE+x} ]]; then
    echoerr "Missing docker-image argument"
fi
if [[ -z ${ASSETS_ROOTDIR+x} ]]; then
    echoerr "Missing assets-folder argument"
fi
if [[ -z ${OUTPUT_FOLDER+x} ]]; then
    echoerr "Missing output-folder argument"
fi
if [[ $VALIDATOR_INITIAL_DELEGATION_AMOUNT -lt 1000000 ]]; then
    echoerr "Validator initial delegation must be greater than 1000000"
fi

KEYS_LIST=$(docker run -v ${ASSETS_ROOTDIR}:/app $DOCKER_IMAGE keys list --keyring-backend=test --output=json)
AUTH_ACCOUNTS=$(echo $KEYS_LIST | jq '[.[] | .= {
    "@type": "/ethermint.types.v1.EthAccount",
    base_account: {
        address: .address,
        pub_key: null,
        account_number: "0",
        sequence: "0"
    },
    code_hash: "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
}]')
MIN_STAKE=$((VALIDATOR_INITIAL_DELEGATION_AMOUNT * 10000))
BANK_BALANCES=$(echo $KEYS_LIST | jq --arg min_stake $MIN_STAKE --arg base_cro $BASECRO_DENOM '[.[] | .= {
    address: .address, coins: [{
        denom: $base_cro,
        amount: "1000000000000000000000000000"
    },{
        denom: "stake",
        amount: $min_stake
    }]
}]')

ACCOUNT_EXISTS=$(cat ${ASSETS_ROOTDIR}/home/config/genesis.json | jq --arg lookup_address $(echo $KEYS_LIST | jq -r '.[0].address') '.app_state.bank.balances[] | select( .address | index($lookup_address))' | wc -l | xargs)
if [[ $ACCOUNT_EXISTS -gt 0 ]]; then
    echo "✅ Genesis file already initialized. Skipped."
else
    cp ${ASSETS_ROOTDIR}/home/config/genesis.json ${ASSETS_ROOTDIR}/home/config/genesis.json.bak
    # write output tempfile because output redirection may empty the folder before jq runs
    cat ${ASSETS_ROOTDIR}/home/config/genesis.json | jq --argjson auth_accounts "$AUTH_ACCOUNTS" --argjson bank_balances "$BANK_BALANCES" '.app_state.auth.accounts += $auth_accounts | .app_state.bank.balances += $bank_balances' > ${ASSETS_ROOTDIR}/home/config/genesis.json.tmp
    mv ${ASSETS_ROOTDIR}/home/config/genesis.json.tmp ${ASSETS_ROOTDIR}/home/config/genesis.json
    echo "✅ Genesis file initialized."
fi

mkdir -p $OUTPUT_FOLDER
if [[ -f ${OUTPUT_FOLDER}/.prepared ]]; then
    echoerr "Output folder already prepared. Preparation aborted."
fi
touch ${OUTPUT_FOLDER}/.prepared

GEN_TXS=[]
NODE_IDS_LIST=()
PERSISTENT_PEERS_LIST=()
i=0; while [[ $i -lt $VALIDATOR_COUNT ]]; do
    KEY_NAME=validator$i
    HOST=cronos-validator$i
    MONIKER=cronos-validator$i
    WORKDIR=${OUTPUT_FOLDER}/validator$i
    HOME=${WORKDIR}/home
    mkdir -p $HOME
    cp -r ${ASSETS_ROOTDIR}/ $WORKDIR

    TEMPDIR=$(mktemp -d)
    docker run -v ${ASSETS_ROOTDIR}/chain:/app/chain \
        -v ${TEMPDIR}:/app/home \
        $DOCKER_IMAGE init node --chain-id=$CHAIN_ID > /dev/null 2>&1
    cp $TEMPDIR/config/node_key.json $HOME/config
    cp $TEMPDIR/config/priv_validator_key.json $HOME/config
    echo "✅ Validator$i home folder created"

    docker run -v ${ASSETS_ROOTDIR}/chain:/app/chain \
        -v ${HOME}:/app/home \
        $DOCKER_IMAGE gentx $KEY_NAME $VALIDATOR_INITIAL_DELEGATION \
        --keyring-backend=test --chain-id=$CHAIN_ID --moniker=$MONIKER > /dev/null 2>&1 
    GEN_TX=$(docker run -v ${ASSETS_ROOTDIR}/chain:/app/chain \
        -v ${HOME}:/app/home \
        $DOCKER_IMAGE collect-gentxs 2>&1 | jq '.app_message.genutil.gen_txs[0]')
    GEN_TXS=$(echo $GEN_TXS | jq --argjson gen_tx "$GEN_TX" '. += [$gen_tx]')
    echo "✅ Validator$i create validator transaction generated"

    NODE_ID=$(docker run -v ${ASSETS_ROOTDIR}/chain:/app/chain \
        -v ${HOME}:/app/home \
        $DOCKER_IMAGE tendermint show-node-id 2>&1)
    NODE_IDS_LIST+=(\"$NODE_ID\")
    PERSISTENT_PEERS_LIST+=(${NODE_ID}@${HOST}:26656)

    ((i=i+1))
done

NODE_IDS=$(echo ${NODE_IDS_LIST[@]} | tr ' ' ',')
PERSISTENT_PEERS=$(echo ${PERSISTENT_PEERS_LIST[@]} | tr ' ' ',')

GENESIS=$(cat ${ASSETS_ROOTDIR}/home/config/genesis.json | jq --argjson gen_txs "$GEN_TXS" '.app_state.genutil.gen_txs = $gen_txs')
i=0; while [[ $i -lt $VALIDATOR_COUNT ]]; do
    MONIKER=cronos-validator$i

    cp ${OUTPUT_FOLDER}/validator${i}/home/config/config.toml ${OUTPUT_FOLDER}/validator${i}/home/config/config.toml.bak
    sed -i '' "s#^persistent_peers *=.*#persistent_peers = \"$PERSISTENT_PEERS\"#" ${OUTPUT_FOLDER}/validator${i}/home/config/config.toml
    sed -i '' "s#^moniker *=.*#moniker = \"$MONIKER\"#" ${OUTPUT_FOLDER}/validator${i}/home/config/config.toml

    cp ${OUTPUT_FOLDER}/validator${i}/home/config/genesis.json ${OUTPUT_FOLDER}/validator${i}/home/config/genesis.json.bak
    echo $GENESIS | jq > ${OUTPUT_FOLDER}/validator${i}/home/config/genesis.json

    echo "✅ Validator$i prepareation completed"
    ((i=i+1))
done
