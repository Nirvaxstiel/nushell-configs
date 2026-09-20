# syntax=docker/dockerfile:1
FROM nousresearch/hermes-agent:main

USER root
ENV DOTNET_ROOT=/usr/share/dotnet

# Trust supplied root CA for apt, curl, dotnet, nuget, etc.
COPY cloudflare.crt /usr/local/share/ca-certificates/cloudflare.crt

RUN --mount=type=cache,target=/var/cache/apt,sharing=shared \
    --mount=type=cache,target=/var/lib/apt,sharing=shared \
    set -eux; \
    update-ca-certificates; \
    rm -rf /etc/apt/apt.conf.d/docker-clean; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        make \
        g++ \
        build-essential \
        pandoc \
        libicu-dev; \
    curl -fsSL -o /tmp/ms.deb https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb; \
    dpkg -i /tmp/ms.deb; \
    rm -f /tmp/ms.deb; \
    apt-get update;
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y gh


RUN curl -fsSL https://dot.net/v1/dotnet-install.sh \
        -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh \
            --channel 10.0 \
            --install-dir /usr/share/dotnet \
    && /tmp/dotnet-install.sh \
            --channel 8.0 \
            --runtime aspnetcore \
            --install-dir /usr/share/dotnet \
    && rm -f /tmp/dotnet-install.sh

ENV HERMES_HOME=/opt/data \
    HOME=/opt/data/home \
    DOTNET_ROOT=/usr/share/dotnet \
    NUGET_PACKAGES=/opt/data/home/.nuget/packages \
    NUGET_CONFIG_FILE=/opt/data/home/.nuget/NuGet/NuGet.Config \
    PATH=/usr/share/dotnet:/opt/hermes/bin:/opt/data/.venv/bin:/opt/data/home/.dotnet/tools:/home/hermes/.local/bin:/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin

RUN install -d /opt/data/home/.nuget/NuGet \
            /opt/data/home/.nuget/packages \
            /opt/data/home/.dotnet/tools \
            /opt/data/.npm

RUN --mount=type=cache,target=/opt/data/home/.nuget/packages,sharing=locked \
    dotnet tool install roslyn-language-server --prerelease --tool-path /opt/data/home/.dotnet/tools

USER hermes
