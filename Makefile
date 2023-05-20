# Arguments
CRYPTO_ORG_CHAIN_VERSION := 4.2.2
CRONOS_VERSION := 1.0.5
# WARNING: The following mnemonics is revealed to public and not safe
# NEVER use the following mnemonics in any enviornment with monetary value
MNEMONICS := "march tourist bless menu tenant element bid say pluck film fever tourist planet recycle hundred toe assist budget obvious citizen memory genius double float"
# Skip SSL verification. 1 to skip
INSECURE_SKIP_SSL_VERIFY := 1

# Constants
DOCKER = $(shell command -v docker)

CRYPTO_ORG_CHAIN_ID := cryptoorgchainlocal-1
CRONOS_CHAIN_ID := cronoslocal_65536-1

CRYPTO_ORG_CHAIN_MIN_GAS_PRICES := 0.025basecro
CRONOS_MIN_GAS_PRICES := 5000000000000000000000basecro

# TODO: Dynamic validator size

ASSETS_ROOT := ./assets
CRYPTO_ORG_CHAIN_ASSETS := $(ASSETS_ROOT)/crypto-org-chain
CRONOS_ASSETS := $(ASSETS_ROOT)/cronos
RUNTIME_ROOT := ./runtime
CRYPTO_ORG_CHAIN_RUNTIME := $(RUNTIME_ROOT)/crypto-org-chain
CRONOS_RUNTIME := $(RUNTIME_ROOT)/cronos
CRYPTO_ORG_CHAIN_VALIDATOR0_HOME := $(CRYPTO_ORG_CHAIN_RUNTIME)/validator0
CRYPTO_ORG_CHAIN_VALIDATOR1_HOME := $(CRYPTO_ORG_CHAIN_RUNTIME)/validator1
CRONOS_VALIDATOR0_HOME := $(CRONOS_RUNTIME)/validator0
CRONOS_VALIDATOR1_HOME := $(CRONOS_RUNTIME)/validator1

TOOLBOX_DOCKER_IMAGE := local-cro-chain/toolbox
CRYPTO_ORG_CHAIN_DOCKER_IMAGE := local-cro-chain/crypto-org-chain 
CRONOS_DOCKER_IMAGE := local-cro-chain/cronos

.PHONY: has-docker
has-docker:
ifndef DOCKER
	@echo "Docker not found. Please install docker and try again."
	@exit 1
endif

.PHONY: build-image
build-image: has-docker
	@docker build -t $(TOOLBOX_DOCKER_IMAGE) -f ./docker/toolbox.Dockerfile ./docker
	@docker build -t $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) -f ./crypto-org-chain/Dockerfile .
	@docker build -t $(CRONOS_DOCKER_IMAGE) -f ./cronos/Dockerfile .

.PHONY: download-binary
download-binary:
	@mkdir -p $(CRYPTO_ORG_CHAIN_ASSETS)
	@mkdir -p $(CRONOS_ASSETS)
	@if [[ $(INSECURE_SKIP_SSL_VERIFY) -eq 1 ]]; then \
		docker run -v $(CRYPTO_ORG_CHAIN_ASSETS)/chain:/app \
			$(TOOLBOX_DOCKER_IMAGE) \
			/scripts/download-binary.sh --insecure-skip-ssl-verify crypto-org-chain $(CRYPTO_ORG_CHAIN_VERSION); \
		echo; \
		docker run -v $(CRONOS_ASSETS)/chain:/app \
			$(TOOLBOX_DOCKER_IMAGE) \
			/scripts/download-binary.sh --insecure-skip-ssl-verify cronos $(CRONOS_VERSION); \
	else \
		docker run -v $(CRYPTO_ORG_CHAIN_ASSETS)/chain:/app \
			$(TOOLBOX_DOCKER_IMAGE) \
			/scripts/download-binary.sh crypto-org-chain $(CRYPTO_ORG_CHAIN_VERSION); \
		echo; \
		docker run -v $(CRONOS_ASSETS)/chain:/app \
			$(TOOLBOX_DOCKER_IMAGE) \
			/scripts/download-binary.sh cronos $(CRONOS_VERSION); \
	fi

# TODO
.PHONY: build-binary
build-binary: has-docker

.PHONY: init
init: init-docker init-home init-account init-config

.PHONY: init-docker
init-docker: has-docker

.PHONY: init-home
init-home:
	@./scripts/init-home.sh --chain-id $(CRYPTO_ORG_CHAIN_ID) $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) $(CRYPTO_ORG_CHAIN_ASSETS)
	@./scripts/init-home.sh --chain-id $(CRONOS_CHAIN_ID) $(CRONOS_DOCKER_IMAGE) $(CRONOS_ASSETS)

.PHONY: init-account
init-account: has-docker
	@echo "Importing Crypto.org Chain validator account";
	@yes $(MNEMONICS) | docker run -i --rm -v $(CRYPTO_ORG_CHAIN_ASSETS):/app $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) keys add validator0 --recover --keyring-backend=test > /dev/null
	@yes $(MNEMONICS) | docker run -i --rm -v $(CRYPTO_ORG_CHAIN_ASSETS):/app $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) keys add validator1 --index=1 --recover --keyring-backend=test > /dev/null
	@i=2; while [[ $$i -lt 10 ]]; do \
		echo "Importing Crypto.org Chain account$$i"; \
		yes $(MNEMONICS) | docker run -i --rm -v $(CRYPTO_ORG_CHAIN_ASSETS):/app $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) keys add account$$i --index=$$i --recover --keyring-backend=test > /dev/null; \
		((i = i + 1)); \
	done

	@echo "Importing Cronos validator account";
	@yes $(MNEMONICS) | docker run -i --rm -v $(CRONOS_ASSETS):/app $(CRONOS_DOCKER_IMAGE) keys add validator0 --recover --keyring-backend=test > /dev/null
	@yes $(MNEMONICS) | docker run -i --rm -v $(CRONOS_ASSETS):/app $(CRONOS_DOCKER_IMAGE) keys add validator1 --index=1 --recover --keyring-backend=test > /dev/null
	@i=2; while [[ $$i -lt 10 ]]; do \
		echo "Importing Cronos account$$i"; \
		yes $(MNEMONICS) | docker run -i --rm -v $(CRONOS_ASSETS):/app $(CRONOS_DOCKER_IMAGE) keys add account$$i --index=$$i --recover --keyring-backend=test > /dev/null; \
		((i = i + 1)); \
	done

.PHONY: list-account
list-account:
	@docker run -v $(CRONOS_ASSETS):/app $(CRONOS_DOCKER_IMAGE) keys list --keyring-backend=test --output=json | jq

.PHONY: init-config
init-config:
	@cp $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/app.toml $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/app.toml.bak
	@sed -i '' "s#^minimum-gas-prices *=.*#minimum-gas-prices = \"$(CRYPTO_ORG_CHAIN_MIN_GAS_PRICES)\"#" ${CRYPTO_ORG_CHAIN_ASSETS}/home/config/app.toml
	@cp $(CRONOS_ASSETS)/home/config/app.toml $(CRONOS_ASSETS)/home/config/app.toml.bak
	@sed -i '' "s#^minimum-gas-prices *=.*#minimum-gas-prices = \"$(CRONOS_MIN_GAS_PRICES)\"#" ${CRONOS_ASSETS}/home/config/app.toml

.PHONY: unsafe-clear-account
unsafe-clear-account:
	@rm -rf $(CRYPTO_ORG_CHAIN_ASSETS)/home/keyring-test
	@rm -rf $(CRONOS_ASSETS)/home/keyring-test

.PHONY: prepare
prepare: prepare-crypto-org-chain prepare-cronos

.PHONY: prepare-crypto-org-chain
prepare-crypto-org-chain:
	@echo "Crypto.org Chain"
	@./scripts/prepare-crypto-org-chain.sh --chain-id $(CRYPTO_ORG_CHAIN_ID) $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) $(CRYPTO_ORG_CHAIN_ASSETS) $(CRYPTO_ORG_CHAIN_RUNTIME)
	@echo "✅ Crypto.org Chain validators prepared"

.PHONY: prepare-cronos
prepare-cronos:
	@echo "Cronos"
	@./scripts/prepare-cronos.sh --chain-id $(CRONOS_CHAIN_ID) $(CRONOS_DOCKER_IMAGE) $(CRONOS_ASSETS) $(CRONOS_RUNTIME)
	@echo "✅ Cronos validators prepared"

.PHONY: start
start:

.PHONY: unsafe-clear-assets
unsafe-clear-assets:
	@rm -rf assets

.PHONY: unsafe-clear-runtime
unsafe-clear-runtime:
	@rm -rf runtime

.PHONY: tendermint-unsafe-reset-all
tendermint-unsafe-reset-all:
	@docker run -v $(CRYPTO_ORG_CHAIN_VALIDATOR0_HOME):/app $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) tendermint unsafe-reset-all > /dev/null
	@docker run -v $(CRYPTO_ORG_CHAIN_VALIDATOR1_HOME):/app $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) tendermint unsafe-reset-all > /dev/null
	@docker run -v $(CRONOS_VALIDATOR0_HOME):/app $(CRONOS_DOCKER_IMAGE) tendermint unsafe-reset-all > /dev/null
	@docker run -v $(CRONOS_VALIDATOR1_HOME):/app $(CRONOS_DOCKER_IMAGE) tendermint unsafe-reset-all > /dev/null
