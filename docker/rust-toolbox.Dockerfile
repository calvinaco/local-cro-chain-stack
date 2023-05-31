FROM rust:1.69-slim-bullseye

WORKDIR /app

ENV SSL_CERT_FILE=/certificates.pem

RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY ./scripts /scripts
COPY ./certificates.pem* /certificates.pem
