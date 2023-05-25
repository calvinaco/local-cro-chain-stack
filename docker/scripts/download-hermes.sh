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
Usage: $0 version target

Arguments:
    version:                    The version of the binary to download. e.g. 1.2.0
    target:                     The target to download the binary for. Supported values: "source","binary".
Flags:
    --insecure-skip-ssl-verify: Skip SSL verification when downloading the binary. Default false.
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
        *)
            if [[ $# -gt 2 ]]; then
                echoerr "Too many arguments"
            fi
            VERSION=$1
            TARGET=$2
            shift 2
        ;;
    esac
done

if [[ -z ${VERSION+x} ]]; then
    echoerr "Missing version argument"
fi
if [[ -z ${TARGET+x} ]]; then
    echoerr "Missing target argument"
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

if [[ $TARGET == "source" ]]; then
    FILE=v${VERSION}.tar.gz
    URL=https://github.com/informalsystems/hermes/archive/refs/tags/${FILE}
elif [[ $TARGET == "binary" ]]; then
    FILE=hermes-v${VERSION}-${ARCH}-unknown-linux-gnu.tar.gz
    URL=https://github.com/informalsystems/hermes/releases/download/v${VERSION}/${FILE}
else
    echoerr "Unsupported target $TARGET"
fi

cat << EOF
Version: $VERSION
Target: $TARGET
Download URL: $URL
Skip SSL Verify: $INSECURE_SKIP_SSL_VERIFY
Working directory: $(pwd)
EOF

if [[ $INSECURE_SKIP_SSL_VERIFY -eq 1 ]]; then \
    curl --insecure -sLO --fail --show-error $URL; \
else \
    curl -sLO --fail --show-error $URL; \
fi || echoerr "Failed to download file"
tar -zxvf $FILE > /dev/null 2>&1 || echoerr "Failed to extract $TARGET"
if [[ $TARGET == "source" ]]; then
    if [[ ! -d ./hermes-${VERSION} ]]; then 
        echoerr "Missing source code from extracted files"
    fi
    mv ./hermes-${VERSION}/* .
else
    if [[ ! -f "./hermes" ]]; then 
        echoerr "Missing binary from extracted files"
    fi
fi
echo "✅ hermes v$VERSION $TARGET is ready"
rm -f $FILE
