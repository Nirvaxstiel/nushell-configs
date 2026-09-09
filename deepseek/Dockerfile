FROM node:22-bookworm

RUN corepack enable \
    && corepack prepare pnpm@latest --activate

RUN apt-get update && apt-get install -y \
    git \
    curl \
    ripgrep \
    fd-find \
    jq \
    python3 \
    build-essential \
    socat \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# TODO: pin this to a known-good commit.
RUN git clone https://github.com/deepseek-ai/deepseek-harness.git \
    && cd deepseek-harness \
    && pnpm install \
    && pnpm run build

COPY docker/dsh-entrypoint.sh /usr/local/bin/dsh-entrypoint
RUN chmod +x /usr/local/bin/dsh-entrypoint

WORKDIR /workspace

# 3081 is the externally reachable container-side proxy.
EXPOSE 3081

ENTRYPOINT ["/usr/local/bin/dsh-entrypoint"]
