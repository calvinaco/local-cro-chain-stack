#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
set +x

echoerr() {
    echo "$@" 1>&2;
    echo 1>&2;
    helpFunction 1>&2;
    exit 1;
}

helpFunction()
{
    cat << EOF
Usage: $0 blockchain version

Arguments:
    blockchain:                 The blockchain to download the binary for. Supported values: "crypto-org-chain", "cronos".
    version:                    The version of the binary to download. e.g. 1.0.5
Flags:
    --insecure-skip-ssl-verify: Skip SSL verification when downloading the binary. Default false.
    --network:                  Specify the network. Supported values: "testnet", "mainnet". Default: "mainnet"
    --help:                     Show this help message
EOF
    exit 1 
}

if [[ ! -x "$(command -v curl)" ]]; then
    echoerr "curl is required. Please install curl first."
fi

NETWORK="mainnet"
INSECURE_SKIP_SSL_VERIFY=0
while [[ $# > 0 ]]; do
    case "$1" in
        --help)
            helpFunction
        ;;
        --insecure-skip-ssl-verify)
            INSECURE_SKIP_SSL_VERIFY=1
            shift 1
        ;;
        --network)
            NETWORK=$2
            shift 2
        ;;
        *)
            if [[ $# -gt 2 ]]; then
                echoerr "Too many arguments"
            fi
            BLOCKCHAIN=$1
            VERSION=$2
            shift 2
        ;;
    esac
done

if [[ -z ${BLOCKCHAIN+x} ]]; then
    echoerr "Missing blockchain argument"
fi
if [[ -z ${VERSION+x} ]]; then
    echoerr "Missing version argument"
fi

if [[ $(uname -s | grep -i darwin | wc -l | xargs) -eq 1 ]]; then
    OS="Darwin"
elif [[ $(uname -s | grep -i linux | wc -l | xargs) -eq 1 ]]; then
    OS="Linux"
else
    echoerr "Unsupported OS $(uname -s)"
fi

ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]] && [[ "$ARCH" != "arm64" ]]; then
    echoerr "Unsupported architecture $ARCH"
fi

if [[ "$NETWORK" != "mainnet" ]] && [[ "$NETWORK" != "testnet" ]]; then
    echoerr "Unsupported network $NETWORK"
fi

if [[ $BLOCKCHAIN == "crypto-org-chain" ]]; then
    if [[ $NETWORK == "testnet" ]]; then
        VERSION="${VERSION}-croeseid"
    fi
    FILE="chain-main_${VERSION}_${OS}_${ARCH}.tar.gz"
    URL="https://github.com/crypto-org-chain/chain-main/releases/download/v${VERSION}/${FILE}"
elif [[ $BLOCKCHAIN == "cronos" ]]; then
    if [[ $NETWORK == "testnet" ]]; then
        VERSION="${VERSION}-testnet"
    fi
    FILE="cronos_${VERSION}_${OS}_${ARCH}.tar.gz"
    URL="https://github.com/crypto-org-chain/cronos/releases/download/v${VERSION}/${FILE}"
else
    echoerr "Unsupported blockchain $BLOCKCHAIN"
fi

cat << EOF
Blockchain: $BLOCKCHAIN
Network: $NETWORK
Version: $VERSION
Download URL: $URL
Skip SSL Verify: $INSECURE_SKIP_SSL_VERIFY
Working directory: $(pwd)
EOF

if [[ $INSECURE_SKIP_SSL_VERIFY -eq 1 ]]; then \
    curl --insecure -sLO --fail --show-error $URL; \
else \
    curl -sLO --fail --show-error $URL; \
fi || echoerr "Failed to download binary"
tar -zxvf $FILE > /dev/null 2>&1 || echoerr "Failed to extract binary"
if [[ -z "./bin" ]]; then 
    echoerr "Missing binary from extracted files"
fi
echo "✅ $BLOCKCHAIN $NETWORK v$VERSION binary is ready"
rm -f $FILE CHANGELOG.md LICENSE README.md
