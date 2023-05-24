for i in $(echo $account | jq -r ".[].account")
  do
    echo echo $i 
  done

.PHONY: list-chain-account
list-chain-account:
	@docker run -v $(CRONOS_ASSETS):/app \
		$(CRONOS_DOCKER_IMAGE) \
		keys list --keyring-backend=test --output=json | jq '[.[] | .= { \
	
    "@type": "/ethermint.types.v1.EthAccount",
    base_account: {
        address: .address,
        pub_key: null,
        account_number: "0",
        sequence: "0"
    },
    code_hash: "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
}]')
