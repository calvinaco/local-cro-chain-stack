FROM local-cro-chain/buildpack

WORKDIR /app

ENV HOME=/app

ENTRYPOINT [ "/app/bin/hermes" ]
