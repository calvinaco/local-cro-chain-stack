FROM alpine:3.18.0 AS builder

WORKDIR /app

RUN apk add --no-cache curl bash

COPY ./scripts /scripts
