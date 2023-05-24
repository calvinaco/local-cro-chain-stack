FROM ubuntu:22.04

WORKDIR /app

ENV HOME=/app

ENTRYPOINT [ "/app/bin/hermes" ]
