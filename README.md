# Local Crypto.org Chain and Cronos Stack

### WARNING: All the accounts, keys and mnemonics in this repository are publicly exposed and must not be used in places with monetary value.


This project helps to quickly created a local CRO family chains stack using Docker with customizable configurations:
- Crypto.org Chain
- Cronos
- IBC-channel

This is useful for performing experiments without setting up from scratch nor to interact with the public networks.

## Prerequisites

- Docker

## Quick Start

```bash
make all
make start
# Enjoy!
```

## Custom Build and Configuration

`make all` command perform a series of make actions to create the default chain stack for you. Two of the major steps in the `make all` is `make init` and `make prepare` which are corresponding to the init and prepare Phases.

### Init Phase

`make init`

Init phase creates the default configurations that are commonly shared between all the nodes. i.e. Binary, Configurations, Default accounts and Consensus params. These configurations are usually propagated too all the nodes.

If you want to change the network params, you can modify the assets in `assets` folder accordingly.

### Prepare Phase

`make prepare`

Prepare phase propagates the assets and generate multiple validators and nodes depending on the setup. This phase are usually useful if you want to create distinctions between the nodes for your experiment.

## Common Makefile Targets

| Target | Phase | Description |
| --- | --- | --- |
| `make download-binary` | init | Download or build binary from a specific version. You can specify the chain and hermes versions as specified in the Makefile header. |
| `make init` | init | Initialize the chains and hermes in the assets folder. This can be used to bootstrap the assets and ten that you can customize the setup. |
| `make prepare` | prepare | Prepare the runtime environment including preparing the default accounts with balances and generate the validators details. |
| `make start` | runtime | Start the runtime by creating and running all the chain nodes and hermes. |
| `make stop` | runtime | Stop the runtime. |
| `make restart` | runtime | Restart the runtime. |
| `make logs` | runtime | Follow the runtime logs. |
| `make logs-crypto-org-chain` | runtime | Follow the Crypto.org Chain runtime logs. |
| `make logs-cronos` | runtime | Follow the Cronos runtime logs. |
| `make logs-hermes` | runtime | Follow the Hermes runtime logs. |
| `make tendermint-unsafe-reset-all` | N/A | This action is non-reversible. Reset chain runtime to initial state. |
| `make unsafe-clear-assets` | N/A | This action is non-reversible. Clear assets folder except `go/`, `shared/` and `src/` folders inside. |
| `make unsafe-clear-runtime` | N/A | This action is non-reversible. Clear runtime folder. |

## Commands

A few handy commands are provided to help you pre-fill the connections details such that you can interact with local chain stack without a hassell:

| Script Path | Description |
| --- | --- |
| ./cmd/chain-maind | Interact with Crypto.org Chain. Behaves similar to `chain-maind` with extra features |
| ./cmd/cronosd | Interact with Cronos. Behaves similar to `cronosd` with extra features |
| ./cmd/hermes | Interact with Hermes. Behaves the same as `hermes` |
| ./cmd/list-account | List all account address, balances and private key |

## System Design and Defaults

This section covers the system design highlights and some of default values that you may be interested to modify.

### Minimum Gas Prices

#### Defaults

The default minimum gas prices of each chain is configured as below

| Chain | Minimum Gas Prices |
| --- | --- |
| Crypto.org Chain | 0.025basecro |
| Cronos | 5000basecro,0stake |

#### How to change

To change the minimum gas prices, there are two places you have to modify:

- Chain configuration
  - `assets/crypto-org-chain/home/config/app.toml` and/or `assets/cronos/home/config/app.toml`
- Hermes configuration
  - `assets/hermes/.hermes/config.toml`

### Hermes

#### IBC Channel Keep Alive Cron Job

To keep the IBC client active, an IBC transfer cron job is executed every regular interval. This interval can be configured in the `docker-compose.yml`. Default is to run every 1 minute.

Two accounts named `relayer-keepalive` are created in the created Crypto.org Chain and Cronos. IBC transfer cron job make uses of these accounts and transfer CRO to each other and trigger the client updates to keep the channel alive.

## Project Structure

| Folder | Description |
| --- | --- |
| assets/ | Build time assets including source file, binaries and configuration before copying to runtime |
| assets/cronos | Cronos assets |
| assets/cronos/chain | Cronos binary |
| assets/cronos/home | Cronos initialized home folder. This will be copied to runtime on `make prepare` |
| assets/crypto-org-chain | Crypto.org Chain assets |
| assets/crypto-org-chain/chain | Crypto.org Chain binary |
| assets/crypto-org-chain/home | Crypto.org Chain initialized home folder. This will be copied to runtime on `make prepare` |
| assets/go | Cache folder for go build dependencies |
| assets/hermes | Hermes assets |
| assets/hermes/.hermes | Hermes initialized home folder. This will be copied to runtime on `make prepare` |
| assets/hermes/bin | Hermes binary |
| assets/shared | Shared folder that is mounted as `/shared` to the container when running `./cmd/chain-maind` and `./cmd/cronosd` |
| assets/src/cronos | Cronos source code for custom build |
| assets/src/crypto-org-chain | Crypto.org Chain source code for custom build |
| assets/src/hermes | Hermes source code for custom build |
| cmd/ | Contains commands to interact with the docker service as if running a local command |
| cmd/chain-maind | An easy chain-maind CLI that has access to the local network |
| cmd/cronosd | An easy cronods CLI that has access to the local network |
| cmd/hermes | An easy hermes CLI that has access to the local network |
| cmd/list-account | List all account address, balances and private key |
| cronos | Cronos docker resources |
| crypto-org-chain | Crypto.org Chain docker resources |
| docker | Build docker resources |
| docker/scripts | Scripts for build toolbox docker image |
| docker/buildpack.Dockerfile | Base image Dockerfile with necessary build dependencies for all the images |
| docker/toolbox.Dockerfile | Build toolbox Dockerfile |
| hermes | Hermes docker resources |
| runtime/ | Runtime environment of the chain services |
| scripts/ | Scripts used by Makefile |
| docker-compose.yml | docker-compose file generated by Makefile for the local network |

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
