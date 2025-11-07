FROM ghcr.io/dojoengine/dojo:v1.7.1 AS dojo

RUN apt update && apt install curl jq -y

# Instala asdf y las herramientas de dojo (sozo, katana, torii)
RUN curl -L https://install.dojoengine.org | bash


FROM ghcr.io/dojoengine/katana:v1.7.0 AS katana


FROM ghcr.io/dojoengine/torii:v1.8.8 AS torii

RUN apt update && apt install jq -y
