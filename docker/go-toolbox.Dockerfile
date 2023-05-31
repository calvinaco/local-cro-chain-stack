FROM golang:1.20.4-bullseye

WORKDIR /app

ENV SSL_CERT_FILE=/certificates.pem
ENV GOPATH=/go

RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY ./scripts /scripts
COPY ./certificates.pem* /certificates.pem
