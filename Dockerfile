FROM alpine:latest

RUN apk add --no-cache curl bash ca-certificates git nodejs npm \
    gcc musl-dev linux-headers

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

WORKDIR /app

RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/root/.local/bin:${PATH}"

RUN apk add --no-cache \
    jq yq python3 py3-pip ripgrep fd bat fzf tree less \
    wget openssh-client make vim tmux sqlite \
    coreutils findutils grep sed gawk tar gzip unzip \
    go docker-cli docker-cli-buildx docker-cli-compose
