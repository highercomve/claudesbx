FROM alpine:latest

RUN apk add --no-cache curl bash ca-certificates git nodejs npm \
    gcc musl-dev linux-headers su-exec shadow

RUN mkdir -p /opt/tools && \
    HOME=/opt/tools XDG_BIN_HOME=/opt/tools/bin sh -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

WORKDIR /app

RUN HOME=/opt/tools sh -c 'curl -fsSL https://claude.ai/install.sh | bash'

ENV PATH="/root/.local/bin:/opt/tools/.local/bin:/opt/tools/bin:${PATH}"

RUN apk add --no-cache \
    jq yq python3 py3-pip ripgrep fd bat fzf tree less \
    wget openssh-client make vim tmux sqlite shellcheck shfmt \
    coreutils findutils grep sed gawk tar gzip unzip \
    go docker-cli docker-cli-buildx docker-cli-compose

ENV GOPATH=/root/go
ENV PATH="${GOPATH}/bin:${PATH}"
ENV HOME=/root

COPY entrypoint.sh /usr/local/bin/claudesbx-entrypoint
RUN chmod +x /usr/local/bin/claudesbx-entrypoint

ENTRYPOINT ["/usr/local/bin/claudesbx-entrypoint"]
