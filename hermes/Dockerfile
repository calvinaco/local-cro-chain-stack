FROM local-cro-chain/buildpack

WORKDIR /app

ENV HOME=/app

COPY ./scripts /scripts
ENTRYPOINT [ "/scripts/entrypoint.sh" ]
