#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
set +x

echoerr() {
    echo "❌ $@" 1>&2;
    echo 1>&2;
    helpFunction 1>&2;
    exit 1;
}

helpFunction() {
    cat << EOF
Usage: $0 docker-image assets-folder

Arguments:
    docker-image:       The chain docker image to use to initialize the home folder.
    assets-folder:      The working folder for assets.

Flags:
    --output-folder:    The folder to output the home folder to. Default is the same as assets folder
    --moniker:          The moniker of the node. Default: "node"
    --chain-id:         The chain ID to initialize the home. Default: "local_65536-1"
    --help:             Show this help message
EOF
    exit 1
}

MONIKER=node
CHAIN_ID=local_65536-1
while [[ $# > 0 ]]; do
    case "$1" in
        --help)
            helpFunction
        ;;
        --moniker)
            MONIKER=$2
            shift 2
        ;;
        --chain-id)
            CHAIN_ID=$2
            shift 2
        ;;
        --output-folder)
            OUTPUT_FOLDER=$2
            shift 2
        ;;
        *)
            if [[ $# -ne 2 ]]; then
                echoerr "Missing output-folder argument"
            fi
            DOCKER_IMAGE=$1
            ASSETS_ROOTDIR=$2
            shift 2
        ;;
    esac
done
if [[ -z ${OUTPUT_FOLDER+x} ]]; then
    OUTPUT_FOLDER=$ASSETS_ROOTDIR
fi

if [[ -z ${DOCKER_IMAGE+x} ]]; then
    echoerr "Missing docker-image argument"
fi
if [[ -z ${ASSETS_ROOTDIR+x} ]]; then
    echoerr "Missing assets-folder argument"
fi

docker run \
    -v ${ASSETS_ROOTDIR}/chain:/app/chain \
    -v ${OUTPUT_FOLDER}/home:/app/home \
    $DOCKER_IMAGE init $MONIKER --chain-id=$CHAIN_ID

echo "✅ moniker $MONIKER initialized with Chain ID $CHAIN_ID at $OUTPUT_FOLDER"
