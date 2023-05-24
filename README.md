# Local Crypto.org Chain and Cronos Stack

> WARNING: All the accounts, keys and mnemonics in this repository are publicly exposed and must not be used in places with monetary value.

This project helps to quickly created a local CRO family chains stack with customizable configurations:
- Crypto.org Chain
- Cronos
- IBC-channel

This is useful for performing experiments without setting up from scratch nor to interact with the public networks.

## Quick Start

```bash
make all
make start
# Enjoy!
```

## Custom Build and Configuration

Refer to the Makefile header for configurable options. Alternatively, you can run `make init` to initialize the asset and repace the binary and configurations to your desired setup.

## Makefile targets

| Target | Phase | Description |
| --- | --- | --- |
| `make download-binary` | init | Download or build binary from a specific version. You can specify the chain and hermes versions as specified in the Makefile header. |
| `make init` | init | Initialize the chains and hermes in the assets folder. This can be used to bootstrap the assets and ten that you can customize the setup. |
| `make prepare` | prepare | Prepare the runtime environment including preparing the default accounts with balances and generate the validators details. |
| `make start` | runtime | Start the runtime by creating and running all the chain nodes and hermes. |
| `make stop` | stop | Stop the runtime. |
| `make restart` | stop | Restart the runtime. |
| `make logs` | stop | Follow the runtime logs. |

## Commands

A few handy commands are provided to help you pre-fill the connections details such that you can interact with local chain stack without a hassell:

| Script Path | Description |
| --- | --- |
| ./cmd/chain-maind | Interact with Crypto.org Chain. Behaves similar to `chain-maind` with extra features |
| ./cmd/cronosd | Interact with Cronos. Behaves similar to `cronosd` with extra features |
| ./cmd/hermes | Interact with Hermes. Behaves the same as `hermes` |

### Crypto.org Chain and Hermes



## Project Structure

| Folder | Description |
| --- | --- |
| assets/ | Build time assets including source file, binaries and configuration before copying to runtime |
| assets/cronos | Cronos assets |
| assets/cronos/chain | Cronos binary |
| assets/cronos/home | Cronos initialized home folder. This will be copied to runtime on `make prepare` |
| assets/cronos/src | Cronos source code for custom build |
| assets/crypto-org-chain | Crypto.org Chain assets |
| assets/crypto-org-chain/chain | Crypto.org Chain binary |
| assets/crypto-org-chain/home | Crypto.org Chain initialized home folder. This will be copied to runtime on `make prepare` |
| assets/crypto-org-chain/src | Crypto.org Chain source code for custom build |
| assets/hermes | Hermes assets |
| assets/hermes/.hermes | Hermes initialized home folder. This will be copied to runtime on `make prepare` |
| assets/hermes/bin | Hermes binary |
| assets/hermes/src | Hermes source code for custom build |
| cmd/ | Contains commands to interact with the docker service as if running a local command |
| cronos | Cronos docker resources |
| crypto-org-chain | Crypto.org Chain docker resources |
| docker | Build docker resources |
| docker/scripts | Scripts for build toolbox docker image |
| docker/toolbox.Dockerfile | Build toolbox Dockerfile |

## List of Docker Images

`make build-image` creates the following Docker images:

| Image Name | Description |
| --- | --- |
| local-cro-chain/crypto-org-chain | Crypto.org Chain chain-maind CLI and runtime |
| local-cro-chain/cronos | Cronos chain-maind CLI and runtime |
| local-cro-chain/hermes | Hermes runtime docker. It will create IBC channel if it is not created yet. |
| local-cro-chain/hermes-cli | Hermes CLI |

## Docker Compose Architecture

### Network

A docker network named `local-cro-chain-network` is created upon docker compose creation. This allow you to run a docker container attaching to the network and interact with the services.

Example:
```bash
NETWORK_ID=$(docker network ls | grep 'local-cro-chain-network' | awk '{ print $1}')
docker run --network=$NETWORK_ID ...
```

### Host Port Exposure

Unique ports are assigned the following services of each nodes and exposed to the host network. For the exact port number assignments, refer to the generated `docker-compose.yml`.

| Service | Applicable Chain | Port Range |
| --- | --- | --- |
| Tendermint | Both | 26650+ |
| gRPC | Both | 9090+ |
| LCD | Both | 1310+ |
| Prometheus | Both | 8090+ |
| ETH JSON RPC | Cronos | 8540+ |

### Container Naming

Each docker compose service is assigned a unique name. This allow the host to retrieve the information of these services and interact programmatically. Refer to generated `docker-compose.yml` for the container name of your interest.

Example - Query Tendermint RPC of the 1st Crypto.org Chain validator:
```bash
HOST_PORT=$(docker inspect local-cro-chain-cronos-validator0 | jq -r '.[0].NetworkSettings.Ports."26657/tcp"[0].HostPort')
curl "http://127.0.0.1:${HOST_PORT}"
```


## Custom SSL Certificate

If your network is behind a proxy or has self-signed certificates, you can force the build process to skip SSL verification. There are two options to do so:

### 1. Provide INSECURE_SKIP_SSL_VERIFY to make target

Note this is only respected by certain commands such as `curl` but not the others

```bash
INSECURE_SKIP_SSL_VERIFY=1 make all
```

### 2. Provide an optional certificates

If you have the SSL certificate, this is usually the more reliable way to avoid any SSL certification error arose from self-signed certificate.

1. Copy your self-signed certificate to `./docker/certificates.pem`.
2. Run make target as normal.

Note `./docker/certificates.pem` will not be committed to Git.