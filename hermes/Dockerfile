FROM ubuntu:22.04

WORKDIR /app

ENV HOME=/app
ENV CRYPTO_ORG_CHAIN_ID=
ENV CRONOS_CHAIN_ID=

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY ./scripts /scripts
ENTRYPOINT [ "/scripts/entrypoint.sh" ]
