# Arguments
# TODO: Accept JSON config
ifndef $(CRYPTO_ORG_CHAIN_VERSION)
	CRYPTO_ORG_CHAIN_VERSION := 4.2.2
endif
ifndef $(CRONOS_VERSION)
	CRONOS_VERSION := 1.0.5
endif
ifndef $(HERMES_VERSION)
	HERMES_VERSION := 1.2.0
endif
# WARNING: The following mnemonics is revealed to public and not safe
# NEVER use the following mnemonics in any enviornment with monetary value
ifndef $(MNEMONICS)
	MNEMONICS := "march tourist bless menu tenant element bid say pluck film fever tourist planet recycle hundred toe assist budget obvious citizen memory genius double float"
endif
# Skip SSL verification. 1 to skip
ifndef $(INSECURE_SKIP_SSL_VERIFY)
	INSECURE_SKIP_SSL_VERIFY := 1
endif
ifndef $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE)
	CRYPTO_ORG_CHAIN_VALIDATOR_SIZE := 2
endif
ifndef $(CRONOS_VALIDATOR_SIZE)
	CRONOS_VALIDATOR_SIZE := 2
endif

# Constants
DOCKER = $(shell command -v docker)

CRYPTO_ORG_CHAIN_ID := cryptoorgchainlocal-1
CRONOS_CHAIN_ID := cronoslocal_65536-1

CRYPTO_ORG_CHAIN_MIN_GAS_PRICES := 0.025basecro
CRONOS_MIN_GAS_PRICES := 5000000000000basecro,0stake

ASSETS_ROOT := ./assets
GOPATH_ASSETS := $(ASSETS_ROOT)/go
SRC_ASSETS := $(ASSETS_ROOT)/src
CRYPTO_ORG_CHAIN_ASSETS := $(ASSETS_ROOT)/crypto-org-chain
CRONOS_ASSETS := $(ASSETS_ROOT)/cronos
HERMES_ASSETS := $(ASSETS_ROOT)/hermes
RUNTIME_ROOT := ./runtime
CRYPTO_ORG_CHAIN_RUNTIME := $(RUNTIME_ROOT)/crypto-org-chain
CRONOS_RUNTIME := $(RUNTIME_ROOT)/cronos
HERMES_RUNTIME := $(RUNTIME_ROOT)/hermes

BUILDPACK_DOCKER_IMAGE := local-cro-chain/buildpack
TOOLBOX_DOCKER_IMAGE := local-cro-chain/toolbox
CRYPTO_ORG_CHAIN_DOCKER_IMAGE := local-cro-chain/crypto-org-chain 
CRONOS_DOCKER_IMAGE := local-cro-chain/cronos
HERMES_DOCKER_IMAGE := local-cro-chain/hermes
HERMES_CLI_DOCKER_IMAGE := local-cro-chain/hermes-cli

CURL_SSL_FLAG := ""
ifeq ($(INSECURE_SKIP_SSL_VERIFY),1)
	CURL_SSL_FLAG := --insecure-skip-ssl-verify
endif

.PHONY: all
all: build-image download-binary init prepare generate-docker-compose

.PHONY: has-docker
has-docker:
ifndef DOCKER
	@echo "Docker not found. Please install docker and try again."
	@exit 1
endif

.PHONY: build-image
build-image: build-buildpack-image build-toolbox-image build-chain-image build-hermes-image

.PHONY: build-buildpack-image
build-buildpack-image:
	@docker build -t $(BUILDPACK_DOCKER_IMAGE) -f ./docker/buildpack.Dockerfile ./docker
	@echo "✅ buildpack docker image built"

.PHONY: build-toolbox-image
build-toolbox-image: has-docker 
	@docker build -t $(TOOLBOX_DOCKER_IMAGE) -f ./docker/toolbox.Dockerfile ./docker
	@echo "✅ toolbox docker image built"

.PHONY: build-chain-image
build-chain-image: build-crypto-org-chain-image build-cronos-image

.PHONY: build-crypto-org-chain-image
build-crypto-org-chain-image: has-docker
	@docker build -t $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) -f ./crypto-org-chain/Dockerfile .
	@echo "✅ Crypto.org Chain docker image built"

.PHONY: build-cronos-image
build-cronos-image: has-docker
	@docker build -t $(CRONOS_DOCKER_IMAGE) -f ./cronos/Dockerfile .
	@echo "✅ Cronos docker image built"

.PHONY: build-hermes-image
build-hermes-image:
	@docker build -t $(HERMES_DOCKER_IMAGE) -f ./hermes/Dockerfile ./hermes
	@docker build -t $(HERMES_CLI_DOCKER_IMAGE) -f ./hermes/cli.Dockerfile .
	@echo "✅ Hermes docker image built"

.PHONY: download-source
download-source: download-crypto-org-chain-source download-cronos-source download-hermes-source

.PHONY: download-crypto-org-chain-source
download-crypto-org-chain-source:
	@mkdir -p $(SRC_ASSETS)/ && \
		cd $(SRC_ASSETS) && \
		git clone https://github.com/crypto-org-chain/chain-main

.PHONY: download-cronos-source
download-cronos-source:
	@mkdir -p $(SRC_ASSETS)/ && \
		cd $(SRC_ASSETS) && \
		git clone https://github.com/crypto-org-chain/cronos

.PHONY: download-hermes-source
download-hermes-source:
	@mkdir -p $(SRC_ASSETS)
	docker run -v $(SRC_ASSETS):/app \
		$(TOOLBOX_DOCKER_IMAGE) \
		/scripts/download-hermes.sh $(CURL_SSL_FLAG) $(HERMES_VERSION) source

.PHONY: download-binary
download-binary: download-crypto-org-chain-binary download-cronos-binary download-hermes-binary

.PHONY: download-crypto-org-chain-binary
download-crypto-org-chain-binary:
	@mkdir -p $(CRYPTO_ORG_CHAIN_ASSETS)
	docker run -v $(CRYPTO_ORG_CHAIN_ASSETS)/chain:/app \
		$(TOOLBOX_DOCKER_IMAGE) \
		/scripts/download-chain.sh $(CURL_SSL_FLAG) crypto-org-chain $(CRYPTO_ORG_CHAIN_VERSION)
	@echo "✅ Crypto.org Chain source code downloaded"; \

.PHONY: download-cronos-binary
download-cronos-binary:
	@mkdir -p $(CRONOS_ASSETS)
	docker run -v $(CRONOS_ASSETS)/chain:/app \
		$(TOOLBOX_DOCKER_IMAGE) \
		/scripts/download-chain.sh $(CURL_SSL_FLAG) cronos $(CRONOS_VERSION)
	@echo "✅ Cronos source code downloaded"; \

.PHONY: download-hermes-binary
download-hermes-binary:
	@mkdir -p $(HERMES_ASSETS)
	docker run -v $(HERMES_ASSETS)/bin:/app \
		$(TOOLBOX_DOCKER_IMAGE) \
		/scripts/download-hermes.sh $(CURL_SSL_FLAG) $(HERMES_VERSION) binary
	@echo "✅ Hermes source code downloaded"; \

.PHONY: build-crypto-org-chain-binary
build-crypto-org-chain-binary: has-docker
	@mkdir -p $(GOPATH_ASSETS)
	@mkdir -p $(CRYPTO_ORG_CHAIN_ASSETS)/chain/bin
	@if [[ ! -d $(SRC_ASSETS)/chain-main ]]; then \
		echo "Crypto.org Chain source code not found in $(SRC_ASSETS)/chain-main"; \
	fi
	@docker run \
		-v $(SRC_ASSETS)/chain-main:/app \
		-v $(GOPATH_ASSETS):/go \
		$(TOOLBOX_DOCKER_IMAGE) \
		make build
	@cp $(SRC_ASSETS)/chain-main/build/chain-maind $(CRYPTO_ORG_CHAIN_ASSETS)/chain/bin/
	@echo "✅ Crypto.org Chain binary is built"
	
.PHONY: build-cronos-binary
build-cronos-binary: has-docker
	@mkdir -p $(GOPATH_ASSETS)
	@mkdir -p $(CRONOS_ASSETS)/chain/bin
	@if [[ ! -d $(SRC_ASSETS)/cronos ]]; then \
		echo "Cronos source code not found in $(SRC_ASSETS)/cronos"; \
	fi
	@docker run \
		-v $(SRC_ASSETS)/cronos:/app \
		-v $(GOPATH_ASSETS):/go \
		$(TOOLBOX_DOCKER_IMAGE) \
		make build
	@cp $(SRC_ASSETS)/cronos/build/cronosd $(CRONOS_ASSETS)/chain/bin/
	@echo "✅ Cronos binary is built"

.PHONY: build-hermes-binary
build-hermes-binary: has-docker
	@mkdir -p $(HERMES_ASSETS)/bin
	@if [[ ! -d $(SRC_ASSETS)/hermes ]]; then \
		echo "Hermes source code not found in $(SRC_ASSETS)/hermes"; \
	fi
	@docker run -v $(SRC_ASSETS)/hermes:/app \
		$(TOOLBOX_DOCKER_IMAGE) \
		cargo build --release --package=ibc-relayer-cli
	@cp $(SRC_ASSETS)/hermes/target/release/hermes $(HERMES_ASSETS)/bin/
	@echo "✅ Hermes binary is built"

.PHONY: init
init: init-chain-home init-hermes-home init-config init-chain-account init-hermes-key

.PHONY: init-chain-home
init-chain-home:
	@./scripts/init-chain-home.sh --chain-id $(CRYPTO_ORG_CHAIN_ID) $(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) $(CRYPTO_ORG_CHAIN_ASSETS)
	@./scripts/init-chain-home.sh --chain-id $(CRONOS_CHAIN_ID) $(CRONOS_DOCKER_IMAGE) $(CRONOS_ASSETS)

.PHONY: init-hermes-home
init-hermes-home:
	@mkdir -p $(HERMES_ASSETS)/.hermes
	@cp ./hermes/templates/config.toml $(HERMES_ASSETS)/.hermes/config.toml
	@echo "✅ Hermes config initialized"; \

.PHONY: init-config
init-config: init-crypto-org-chain-config init-cronos-config init-hermes-config

.PHONY: init-crypto-org-chain-config
init-crypto-org-chain-config:
	@cp $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/app.toml $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/app.toml.bak
	@cp $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/config.toml $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/config.toml.bak
	@cp $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/genesis.json $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/genesis.json.bak

	@sed -i '' "s#^minimum-gas-prices *=.*#minimum-gas-prices = \"$(CRYPTO_ORG_CHAIN_MIN_GAS_PRICES)\"#" ${CRYPTO_ORG_CHAIN_ASSETS}/home/config/app.toml
	@sed -i '' "s#^swagger *=.*#swagger = true#" ${CRYPTO_ORG_CHAIN_ASSETS}/home/config/app.toml
	@sed -i '' "s#127\.0\.0\.1:9090#0\.0\.0\.0:9090#" ${CRYPTO_ORG_CHAIN_ASSETS}/home/config/app.toml

	@sed -i '' "s#tcp:\/\/127\.0\.0\.1:26657#tcp:\/\/0\.0\.0\.0:26657#" ${CRYPTO_ORG_CHAIN_ASSETS}/home/config/config.toml

	@cat $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/genesis.json | jq '\
		.app_state.staking.params.unbonding_time = "5m" | \
		.app_state.gov.deposit_params.min_deposit[0].amount = "1000" | \
		.app_state.gov.deposit_params.max_deposit_period = "5m" | \
		.app_state.gov.voting_params.voting_period = "5m" | \
		.app_state.transfer.params.send_enabled = true | \
		.app_state.transfer.params.receive_enabled = true \
		' > $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/genesis.json.tmp
	@mv $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/genesis.json.tmp $(CRYPTO_ORG_CHAIN_ASSETS)/home/config/genesis.json

	@echo "✅ Crypto.org Chain config initialized";

.PHONY: init-cronos-config
init-cronos-config:
	@cp $(CRONOS_ASSETS)/home/config/app.toml $(CRONOS_ASSETS)/home/config/app.toml.bak
	@cp $(CRONOS_ASSETS)/home/config/config.toml $(CRONOS_ASSETS)/home/config/config.toml.bak
	@cp $(CRONOS_ASSETS)/home/config/genesis.json $(CRONOS_ASSETS)/home/config/genesis.json.bak

	@sed -i '' "s#^minimum-gas-prices *=.*#minimum-gas-prices = \"$(CRONOS_MIN_GAS_PRICES)\"#" ${CRONOS_ASSETS}/home/config/app.toml
	@sed -i '' "s#^swagger *=.*#swagger = true#" ${CRONOS_ASSETS}/home/config/app.toml
	@sed -i '' "s#127\.0\.0\.1:9090#0\.0\.0\.0:9090#" ${CRONOS_ASSETS}/home/config/app.toml

	@sed -i '' "s#tcp://127\.0\.0\.1:26657#tcp://0\.0\.0\.0:26657#" ${CRONOS_ASSETS}/home/config/config.toml

	@cat $(CRONOS_ASSETS)/home/config/genesis.json | jq '\
		.app_state.staking.params.unbonding_time = "5m" | \
		.app_state.gov.deposit_params.min_deposit[0].denom = "basecro" | \
		.app_state.gov.deposit_params.min_deposit[0].amount = "1000" | \
		.app_state.gov.deposit_params.max_deposit_period = "5m" | \
		.app_state.gov.voting_params.voting_period = "5m" | \
		.app_state.mint.params.inflation_rate_change = "0" | \
		.app_state.mint.params.inflation_max = "0" | \
		.app_state.mint.params.inflation_min = "0" | \
		.app_state.mint.params.goal_bonded = "1" | \
		.app_state.transfer.params.send_enabled = true | \
		.app_state.transfer.params.receive_enabled = true | \
		.app_state.evm.params.evm_denom = "basecro" | \
		.app_state.cronos.params.ibc_cro_denom = "ibc/6411AE2ADA1E73DB59DB151A8988F9B7D5E7E233D8414DB6817F8F1A01611F86" | \
		.app_state.feemarket.params.base_fee_change_denominator = 100000000 | \
		.app_state.feemarket.params.base_fee = "5000000000000" \
		' > $(CRONOS_ASSETS)/home/config/genesis.json.tmp
	@mv $(CRONOS_ASSETS)/home/config/genesis.json.tmp $(CRONOS_ASSETS)/home/config/genesis.json

	@echo "✅ Cronos config initialized"; \

.PHONY: init-hermes-config
init-hermes-config:
	@cp $(HERMES_ASSETS)/.hermes/config.toml $(HERMES_ASSETS)/.hermes/config.toml.bak

	@sed -i '' "s#{CRYPTO_ORG_CHAIN_ID}#$(CRYPTO_ORG_CHAIN_ID)#" $(HERMES_ASSETS)/.hermes/config.toml
	@sed -i '' "s#{CRYPTO_ORG_CHAIN_RPC}#http://crypto-org-chain-validator0:26657#" $(HERMES_ASSETS)/.hermes/config.toml
	@sed -i '' "s#{CRYPTO_ORG_CHAIN_GRPC}#http://crypto-org-chain-validator0:9090#" $(HERMES_ASSETS)/.hermes/config.toml
	@sed -i '' "s#{CRYPTO_ORG_CHAIN_WEBSOCKET}#ws://crypto-org-chain-validator0:26657/websocket#" $(HERMES_ASSETS)/.hermes/config.toml

	@sed -i '' "s#{CRONOS_CHAIN_ID}#$(CRONOS_CHAIN_ID)#" $(HERMES_ASSETS)/.hermes/config.toml
	@sed -i '' "s#{CRONOS_RPC}#http://cronos-validator0:26657#" $(HERMES_ASSETS)/.hermes/config.toml
	@sed -i '' "s#{CRONOS_GRPC}#http://cronos-validator0:9090#" $(HERMES_ASSETS)/.hermes/config.toml
	@sed -i '' "s#{CRONOS_WEBSOCKET}#ws://cronos-validator0:26657/websocket#" $(HERMES_ASSETS)/.hermes/config.toml

	@echo "✅ Hermes config initialized"; \

.PHONY: init-chain-account
init-chain-account: has-docker
	@i=0; while [[ $$i -lt $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) ]]; do \
		yes $(MNEMONICS) | docker run \
			-i --rm -v $(CRYPTO_ORG_CHAIN_ASSETS):/app \
			$(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) \
			keys add validator$$i \
			--index=$$i --recover --keyring-backend=test; \
		echo "✅ Imported Crypto.org Chain validator$$i"; \
		((i = i + 1)); \
	done

	@i=$(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE); \
	((l = $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) + 10)); \
	while [[ $$i -lt $$l ]]; do \
		yes $(MNEMONICS) | docker run \
			-i --rm -v $(CRYPTO_ORG_CHAIN_ASSETS):/app \
			$(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) \
			keys add account$$i --index=$$i \
			--recover --keyring-backend=test; \
		echo "✅ Imported Crypto.org Chain account$$i"; \
		((i = i + 1)); \
	done
	yes $(MNEMONICS) | docker run \
		-i --rm -v $(CRYPTO_ORG_CHAIN_ASSETS):/app \
		$(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) \
		keys add relayer0 --account=1 \
		--recover --keyring-backend=test; \
	yes $(MNEMONICS) | docker run \
		-i --rm -v $(CRYPTO_ORG_CHAIN_ASSETS):/app \
		$(CRYPTO_ORG_CHAIN_DOCKER_IMAGE) \
		keys add relayer-keepalive --account=2 \
		--recover --keyring-backend=test; \

	@i=0; while [[ $$i -lt $(CRONOS_VALIDATOR_SIZE) ]]; do \
		yes $(MNEMONICS) | docker run \
			-i --rm -v $(CRONOS_ASSETS):/app \
			$(CRONOS_DOCKER_IMAGE) \
			keys add validator$$i --index=$$i \
			--recover --keyring-backend=test; \
		echo "✅ Imported Cronos validator$$i"; \
		((i = i + 1)); \
	done

	@i=$(CRONOS_VALIDATOR_SIZE); \
	((l = $(CRONOS_VALIDATOR_SIZE) + 10)); \
	while [[ $$i -lt $$l ]]; do \
		yes $(MNEMONICS) | docker run \
			-i --rm -v $(CRONOS_ASSETS):/app \
			$(CRONOS_DOCKER_IMAGE) \
			keys add account$$i --index=$$i \
			--recover --keyring-backend=test; \
		echo "✅ Imported Cronos account$$i"; \
		((i = i + 1)); \
	done
	yes $(MNEMONICS) | docker run \
		-i --rm -v $(CRONOS_ASSETS):/app \
		$(CRONOS_DOCKER_IMAGE) \
		keys add relayer0 --account=1 \
		--recover --keyring-backend=test; \
	yes $(MNEMONICS) | docker run \
		-i --rm -v $(CRONOS_ASSETS):/app \
		$(CRONOS_DOCKER_IMAGE) \
		keys add relayer-keepalive --account=2 \
		--recover --keyring-backend=test; \

.PHONY: init-hermes-key
init-hermes-key:
	@echo $(MNEMONICS) > $(HERMES_ASSETS)/.temp_mnemonic
	@docker run -v $(HERMES_ASSETS):/app \
		$(HERMES_CLI_DOCKER_IMAGE) \
		keys add \
		--chain=$(CRYPTO_ORG_CHAIN_ID) \
		--mnemonic-file=/app/.temp_mnemonic \
		--hd-path "m/44'/394'/1'/0/0"
	echo "✅ Hermes Crypto.org Chain relayer account initialized"; \

	@docker run -v $(HERMES_ASSETS):/app \
		$(HERMES_CLI_DOCKER_IMAGE) \
		keys add \
		--chain=$(CRONOS_CHAIN_ID) \
		--mnemonic-file=/app/.temp_mnemonic \
		--hd-path "m/44'/60'/1'/0/0"
	echo "✅ Hermes Cronos relayer account initialized"; \

	@rm $(HERMES_ASSETS)/.temp_mnemonic

.PHONY: unsafe-clear-account
unsafe-clear-account:
	@rm -rf $(CRYPTO_ORG_CHAIN_ASSETS)/home/keyring-test
	@rm -rf $(CRONOS_ASSETS)/home/keyring-test

.PHONY: prepare
prepare: prepare-crypto-org-chain prepare-cronos prepare-hermes genereate-docker-compose

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

.PHONY: prepare-hermes
prepare-hermes:
	@mkdir -p $(HERMES_RUNTIME)/bin
	@mkdir -p $(HERMES_RUNTIME)/crypto-org-chain
	@mkdir -p $(HERMES_RUNTIME)/cronos
	@cp -r $(HERMES_ASSETS)/bin $(HERMES_RUNTIME)/
	@cp -r $(HERMES_ASSETS)/.hermes $(HERMES_RUNTIME)/
	@cp -r $(CRYPTO_ORG_CHAIN_ASSETS)/. $(HERMES_RUNTIME)/crypto-org-chain/
	@cp -r $(CRONOS_ASSETS)/. $(HERMES_RUNTIME)/cronos/
	@echo "✅ Hermes prepared"

.PHONY: genereate-docker-compose
generate-docker-compose:
	@cp docker-compose.yml docker-compose.yml.bak
	@echo "version: '3.8'" > docker-compose.yml
	@echo "networks:" >> docker-compose.yml
	@echo "  local-cro-chain-network:" >> docker-compose.yml
	@echo "    name: local-cro-chain-network" >> docker-compose.yml
	@echo "    driver: bridge" >> docker-compose.yml
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
		echo "    networks:" >> docker-compose.yml; \
		echo "      - local-cro-chain-network" >> docker-compose.yml; \
		echo "    healthcheck:" >> docker-compose.yml; \
		echo "      test: [\"CMD-SHELL\", \" netstat -an | grep -q 26657\"]" >> docker-compose.yml; \
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
		echo "    networks:" >> docker-compose.yml; \
		echo "      - local-cro-chain-network" >> docker-compose.yml; \
		echo "    healthcheck:" >> docker-compose.yml; \
		echo "      test: [\"CMD-SHELL\", \" netstat -an | grep -q 26657\"]" >> docker-compose.yml; \
		((i = i + 1)); \
	done
	@echo "  hermes:" >> docker-compose.yml
	@echo "    image: local-cro-chain/hermes" >> docker-compose.yml
	@echo "    container_name: local-cro-chain-hermes" >> docker-compose.yml
	@echo "    depends_on:" >> docker-compose.yml
	@echo "      crypto-org-chain-validator0:" >> docker-compose.yml
	@echo "        condition: service_healthy" >> docker-compose.yml
	@echo "      cronos-validator0:" >> docker-compose.yml
	@echo "        condition: service_healthy" >> docker-compose.yml
	@echo "    environment:" >> docker-compose.yml
	@echo "      - IBC_TRANSFER_CRON_SCHEDULE=*/1 * * * *" >> docker-compose.yml
	@echo "    volumes:" >> docker-compose.yml
	@echo "      - ./runtime/hermes:/app" >> docker-compose.yml
	@echo "    networks:" >> docker-compose.yml
	@echo "      - local-cro-chain-network" >> docker-compose.yml
	@echo "✅ docker-compose.yml generated"

.PHONY: start
start:
	@docker-compose up -d

.PHONY: create-ibc-channel
create-ibc-channel:
	@NETWORK_ID=$$(docker network ls | grep 'local-cro-chain-network' | awk '{ print $$1}'); \
	docker run --network=$$NETWORK_ID -v $(HERMES_RUNTIME):/app \
		$(HERMES_CLI_DOCKER_IMAGE) \
		create channel \
		--a-chain $(CRYPTO_ORG_CHAIN_ID) \
		--b-chain $(CRONOS_CHAIN_ID) \
		--a-port transfer \
		--b-port transfer \
		--new-client-connection --yes
	@echo "✅ IBC channel created"

.PHONY: logs
logs:
	@docker-compose logs -f

.PHONY: logs-crypto-org-chain
logs-crypto-org-chain:
	@i=0; service=(); while [[ $$i -lt $(CRYPTO_ORG_CHAIN_VALIDATOR_SIZE) ]]; do \
		service+=("crypto-org-chain-validator$$i"); \
		((i = i + 1)); \
	done; \
	docker-compose logs -f $${service[@]}

.PHONY: logs-cronos
logs-cronos:
	@i=0; service=(); while [[ $$i -lt $(CRONOS_VALIDATOR_SIZE) ]]; do \
		service+=("cronos-validator$$i"); \
		((i = i + 1)); \
	done; \
	docker-compose logs -f $${service[@]}

.PHONY: logs-hermes
logs-hermes:
	docker-compose logs -f hermes

.PHONY: stop
stop:
	@docker-compose down

.PHONY: restart
restart: stop start

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
	@rm -rf assets/crypto-org-chain
	@rm -rf assets/cronos
	@rm -rf assets/hermes

.PHONY: unsafe-clear-runtime
unsafe-clear-runtime:
	@rm -rf runtime/crypto-org-chain
	@rm -rf runtime/cronos
	@rm -rf runtime/hermes
