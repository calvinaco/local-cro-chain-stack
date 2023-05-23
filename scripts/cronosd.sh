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
Usage: $0 [tx|query|easy-tx|*] (arguments)

Command:
    tx:         Transaction commands that pre-fills connection to the node.
    query:      Query commands that pre-fills connection to the node.
    easy-tx:    Easy transaction command that pre-fills gas and keyring.
    *:          Any command to be run.

Flags:
    --help:     Show this help message
    --runtime:  The runtime to use under runtime/cronos folder. Default: "validator0". Make sure the flag is
                passed before the command.
EOF
    exit 1
}

DOCKER_IMAGE=local-cro-chain/cronos
HOST_PORT=$(docker inspect local-cro-chain-cronos-validator0 | jq -r '.[0].NetworkSettings.Ports."26657/tcp"[0].HostPort')

RUNTIME=./runtime/cronos/validator0
while [[ $# > 0 ]]; do
    case "$1" in
        --help)
            helpFunction
        ;;
        --runtime)
            RUNTIME=./runtime/cronos/$2
            shift 2
        ;;
        *)
            break
        ;;
    esac
done

if [[ "$1" == "easy-tx" ]]; then
    shift 1
    set -x
    docker run -it --network=host \
        -v ${RUNTIME}:/app \
        $DOCKER_IMAGE \
        tx \
        --gas-prices=0.025basecro --gas=auto  --gas-adjustment=1.5 --keyring-backend=test --node=http://127.0.0.1:$HOST_PORT \
        $@
elif [[ "$1" == "tx" ]]; then
    shift 1
    set -x
    docker run -it --network=host \
        -v ${RUNTIME}:/app \
        $DOCKER_IMAGE \
        tx --node=http://127.0.0.1:$HOST_PORT \
        $@
elif [[ "$1" == "query" ]]; then
    shift 1
    set -x
    docker run -it --network=host \
        -v ${RUNTIME}:/app \
        $DOCKER_IMAGE \
        query --node=http://127.0.0.1:$HOST_PORT \
        $@
else
    set -x
    docker run -it --network=host \
        -v ${RUNTIME}:/app \
        $DOCKER_IMAGE \
        $@
fi
