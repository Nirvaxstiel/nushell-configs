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

ARG DSH_COMMIT

WORKDIR /opt

RUN test -n "$DSH_COMMIT" \
    && git clone --filter=blob:none --no-checkout \
        https://github.com/deepseek-ai/deepseek-harness.git \
        deepseek-harness \
    && cd deepseek-harness \
    && git checkout "$DSH_COMMIT" \
    && pnpm install --frozen-lockfile \
    && pnpm run build

COPY docker/dsh-entrypoint.sh /usr/local/bin/dsh-entrypoint

RUN chmod +x /usr/local/bin/dsh-entrypoint

WORKDIR /workspace

EXPOSE 3081

ENTRYPOINT ["/usr/local/bin/dsh-entrypoint"]
