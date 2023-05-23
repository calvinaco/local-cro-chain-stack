# Arguments
CRYPTO_ORG_CHAIN_VERSION := 4.2.2
CRONOS_VERSION := 1.0.5
# WARNING: The following mnemonics is revealed to public and not safe
# NEVER use the following mnemonics in any enviornment with monetary value
MNEMONICS := "march tourist bless menu tenant element bid say pluck film fever tourist planet recycle hundred toe assist budget obvious citizen memory genius double float"
# Skip SSL verification. 1 to skip
INSECURE_SKIP_SSL_VERIFY := 1
# TODO: Dynamic validator size
CRYPTO_ORG_CHAIN_VALIDATOR_SIZE := 2
CRONOS_VALIDATOR_SIZE := 2

# Constants
DOCKER = $(shell command -v docker)

CRYPTO_ORG_CHAIN_ID := cryptoorgchainlocal-1
CRONOS_CHAIN_ID := cronoslocal_65536-1

CRYPTO_ORG_CHAIN_MIN_GAS_PRICES := 0.025basecro
CRONOS_MIN_GAS_PRICES := 5000000000000000000000basecro

ASSETS_ROOT := ./assets
CRYPTO_ORG_CHAIN_ASSETS := $(ASSETS_ROOT)/crypto-org-chain
CRONOS_ASSETS := $(ASSETS_ROOT)/cronos
RUNTIME_ROOT := ./runtime
CRYPTO_ORG_CHAIN_RUNTIME := $(RUNTIME_ROOT)/crypto-org-chain
CRONOS_RUNTIME := $(RUNTIME_ROOT)/cronos

TOOLBOX_DOCKER_IMAGE := local-cro-chain/toolbox
CRYPTO_ORG_CHAIN_DOCKER_IMAGE := local-cro-chain/crypto-org-chain 
CRONOS_DOCKER_IMAGE := local-cro-chain/cronos

ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

.PHONY: all
all: build-image download-binary init prepare generate-docker-compose

.PHONY: has-docker
has-docker:
ifndef DOCKER
	@echo "Docker not found. Please install docker and try again."
	@exit 1
endif

.PHONY: build-image
build-image: build-toolbox-image build-chain-image

.PHONY: build-toolbox-image
build-toolbox-image: has-docker 
	@docker build -t $(TOOLBOX_DOCKER_IMAGE) -f ./docker/toolbox.Dockerfile ./docker
	@echo "✅ Toolbox docker image built"

.PHONY: build-chain-image
build-chain-image:
	@docker build -t $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) -f ./crypto-org-chain/Dockerfile .
	@echo "✅ Crypto.org Chain docker image built"
	@docker build -t $(CRONOS_DOCKER_IMAGE) -f ./cronos/Dockerfile .
	@echo "✅ Cronos docker image built"

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
init: init-home init-account init-config

.PHONY: init-home
init-home:
	@./scripts/init-home.sh --chain-id $(CRYPTO_ORG_CHAIN_ID) $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) $(CRYPTO_ORG_CHAIN_ASSETS)
	@./scripts/init-home.sh --chain-id $(CRONOS_CHAIN_ID) $(CRONOS_DOCKER_IMAGE) $(CRONOS_ASSETS)

.PHONY: init-account
init-account: has-docker
	@i=0; while [[ $$i -lt $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) ]]; do \
		yes $(MNEMONICS) | docker run -i --rm -v $(CRYPTO_ORG_CHAIN_ASSETS):/app $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) keys add validator$$i --index=$$i --recover --keyring-backend=test; \
		echo "✅ Imported Crypto.org Chain validator$$i"; \
		((i = i + 1)); \
	done

	@i=$(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE); \
	((l = $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) + 10)); \
	while [[ $$i -lt $$l ]]; do \
		yes $(MNEMONICS) | docker run -i --rm -v $(CRYPTO_ORG_CHAIN_ASSETS):/app $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) keys add account$$i --index=$$i --recover --keyring-backend=test; \
		echo "✅ Imported Crypto.org Chain account$$i"; \
		((i = i + 1)); \
	done

	@i=0; while [[ $$i -lt $(CRONOS_VALIDATOR_SIZE) ]]; do \
		yes $(MNEMONICS) | docker run -i --rm -v $(CRONOS_ASSETS):/app $(CRONOS_DOCKER_IMAGE) keys add validator$$i --index=$$i --recover --keyring-backend=test; \
		echo "✅ Imported Cronos validator$$i"; \
		((i = i + 1)); \
	done

	@i=$(CRONOS_VALIDATOR_SIZE); \
	((l = $(CRONOS_VALIDATOR_SIZE) + 10)); \
	while [[ $$i -lt $$l ]]; do \
		yes $(MNEMONICS) | docker run -i --rm -v $(CRONOS_ASSETS):/app $(CRONOS_DOCKER_IMAGE) keys add account$$i --index=$$i --recover --keyring-backend=test; \
		echo "✅ Imported Cronos account$$i"; \
		((i = i + 1)); \
	done

.PHONY: list-account
list-account:
	@docker run -v $(CRONOS_ASSETS):/app $(CRONOS_DOCKER_IMAGE) keys list --keyring-backend=test --output=json | jq

.PHONY: init-config
init-config:
	@cp $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/app.toml $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/app.toml.bak
	@cp $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/config.toml $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/config.toml.bak
	@sed -i '' "s#^minimum-gas-prices *=.*#minimum-gas-prices = \"$(CRYPTO_ORG_CHAIN_MIN_GAS_PRICES)\"#" ${CRYPTO_ORG_CHAIN_ASSETS}/home/config/app.toml
	@sed -i '' "s#tcp:\/\/127\.0\.0\.1:26657#tcp:\/\/0\.0\.0\.0:26657#" ${CRYPTO_ORG_CHAIN_ASSETS}/home/config/config.toml
	@echo "✅ Crypto.org Chain config initialized"; \

	@cp $(CRONOS_ASSETS)/home/config/app.toml $(CRONOS_ASSETS)/home/config/app.toml.bak
	@cp $(CRONOS_ASSETS)/home/config/config.toml $(CRONOS_ASSETS)/home/config/config.toml.bak
	@sed -i '' "s#^minimum-gas-prices *=.*#minimum-gas-prices = \"$(CRONOS_MIN_GAS_PRICES)\"#" ${CRONOS_ASSETS}/home/config/app.toml
	@sed -i '' "s#tcp://127\.0\.0\.1:26657#tcp://0\.0\.0\.0:26657#" ${CRONOS_ASSETS}/home/config/config.toml
	@echo "✅ Cronos config initialized"; \

.PHONY: unsafe-clear-account
unsafe-clear-account:
	@rm -rf $(CRYPTO_ORG_CHAIN_ASSETS)/home/keyring-test
	@rm -rf $(CRONOS_ASSETS)/home/keyring-test

.PHONY: prepare
prepare: prepare-crypto-org-chain prepare-cronos genereate-docker-compose

.PHONY: prepare-crypto-org-chain
prepare-crypto-org-chain:
	@./scripts/prepare-crypto-org-chain.sh \
		--chain-id $(CRYPTO_ORG_CHAIN_ID) \
		--validator-count $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) \
		$(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) $(CRYPTO_ORG_CHAIN_ASSETS) $(CRYPTO_ORG_CHAIN_RUNTIME)
	@echo "✅ Crypto.org Chain validators prepared"

.PHONY: prepare-cronos
prepare-cronos:
	@./scripts/prepare-cronos.sh \
		--chain-id $(CRONOS_CHAIN_ID) \
		--validator-count $(CRONOS_VALIDATOR_SIZE) \
		$(CRONOS_DOCKER_IMAGE) $(CRONOS_ASSETS) $(CRONOS_RUNTIME)
	@echo "✅ Cronos validators prepared"

.PHONY: genereate-docker-compose
generate-docker-compose:
	@cp docker-compose.yml docker-compose.yml.bak
	@echo "version: '3.8'" > docker-compose.yml
	@echo "services:" >> docker-compose.yml
	@i=0; while [[ $$i -lt $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) ]]; do \
		echo "  crypto-org-chain-validator$$i:" >> docker-compose.yml; \
		echo "    image: local-cro-chain/crypto-org-chain" >> docker-compose.yml; \
		echo "    container_name: local-cro-chain-crypto-org-chain-validator$$i" >> docker-compose.yml; \
		echo "    ports:" >> docker-compose.yml; \
		echo "      - \"$$((26650 + $$i)):26657\"" >> docker-compose.yml; \
		echo "      - \"$$((1310 + $$i)):1317\"" >> docker-compose.yml; \
		echo "      - \"$$((9090 + $$i)):9090\"" >> docker-compose.yml; \
		echo "      - \"$$((8090 + $$i)):26660\"" >> docker-compose.yml; \
		echo "    command: [\"start\"]" >> docker-compose.yml; \
		echo "    volumes:" >> docker-compose.yml; \
		echo "      - ./runtime/crypto-org-chain/validator$$i:/app" >> docker-compose.yml; \
		((i = i + 1)); \
	done
	@i=0; while [[ $$i -lt $(CRONOS_VALIDATOR_SIZE) ]]; do \
		echo "  cronos-validator$$i:" >> docker-compose.yml; \
		echo "    image: local-cro-chain/cronos" >> docker-compose.yml; \
		echo "    container_name: local-cro-chain-cronos-validator$$i" >> docker-compose.yml; \
		echo "    ports:" >> docker-compose.yml; \
		echo "      - \"$$((26650 + $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) + $$i)):26657\"" >> docker-compose.yml; \
		echo "      - \"$$((1310 + $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) + $$i)):1317\"" >> docker-compose.yml; \
		echo "      - \"$$((9090 + $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) +  $$i)):9090\"" >> docker-compose.yml; \
		echo "      - \"$$((8090 + $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) + $$i)):26660\"" >> docker-compose.yml; \
		echo "      - \"$$((8540 + $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) + $$i)):8545\"" >> docker-compose.yml; \
		echo "    command: [\"start\"]" >> docker-compose.yml; \
		echo "    volumes:" >> docker-compose.yml; \
		echo "      - ./runtime/cronos/validator$$i:/app" >> docker-compose.yml; \
		((i = i + 1)); \
	done
	@echo "✅ docker-compose.yml generated"

.PHONY: start
start:
	@docker-compose up -d

.PHONY: logs
logs:
	@docker-compose logs -f

.PHONY: stop
stop:
	@docker-compose down

.PHONY: restart
restart: stop start

.PHONY: chain-maind-easy-tx
chain-maind-easy-tx:
	docker run -it --network=host \
		-v ./assets/crypto-org-chain:/app \
		local-cro-chain/crypto-org-chain tx \
		--gas-prices=0.025basecro --gas=auto  --gas-adjustment=1.5 --keyring-backend=test --node=http://127.0.0.1:26650 \
		$(filter-out $@,$(MAKECMDGOALS))

.PHONY: tendermint-unsafe-reset-all
tendermint-unsafe-reset-all:
	@i=0; while [[ $$i -lt $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) ]]; do \
		HOME=$(CRYPTO_ORG_CHAIN_RUNTIME)/validator$$i; \
		echo $$HOME; \
		docker run -v $$HOME:/app $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) tendermint unsafe-reset-all; \
		echo "✅ Crypto.org Chain validator$$i reset successfully"; \
		((i = i + 1)); \
	done
	@i=0; while [[ $$i -lt $(CRONOS_VALIDATOR_SIZE) ]]; do \
		HOME=$(CRONOS_RUNTIME)/validator$$i; \
		docker run -v $$HOME:/app $(CRONOS_DOCKER_IMAGE) tendermint unsafe-reset-all; \
		echo "✅ Cronos validator$$i reset successfully"; \
		((i = i + 1)); \
	done

.PHONY: unsafe-clear-all
unsafe-clear-all: unsafe-clear-assets unsafe-clear-runtime

.PHONY: unsafe-clear-assets
unsafe-clear-assets:
	@rm -rf assets

.PHONY: unsafe-clear-runtime
unsafe-clear-runtime:
	@rm -rf runtime
