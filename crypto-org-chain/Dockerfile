FROM debian:bullseye-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "/app/chain/bin/chain-maind", "--home=/app/home" ]
