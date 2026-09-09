# syntax=docker/dockerfile:1
FROM nousresearch/hermes-agent:main
# Main/Latest has an issue where it now uses s6 which is a dependency for our new process management and monitoring system.
# You can either move your configs to a POSIX compliant location or use the legacy Hermes Agent image which does not have S6.
# Fix. Apparently you just need to launch WSL and then sudo chown -R $USER:USER ~/.hermes and that could do the job.

USER root
ENV DOTNET_ROOT=/usr/share/dotnet

# Trust Zscaler root CA for apt, curl, dotnet, nuget, etc.
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
        build-essential; \
    curl -fsSL -o /tmp/ms.deb https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb; \
    dpkg -i /tmp/ms.deb; \
    rm -f /tmp/ms.deb; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        dotnet-sdk-10.0 \
        aspnetcore-runtime-10.0

ENV HERMES_HOME=/opt/data \
    DOTNET_ROOT=/usr/share/dotnet \
    DOTNETCLI=/opt/data/home \
    NUGET_CONFIG_FILE=/opt/data/home/.nuget/NuGet/NuGet.Config \
    NUGET_PACAKAGES=/opt/data/home/.nuget/packages \
    npm_config_cache=/opt/data/.npm \
    PATH=/home/hermes/.dotnet/tools:/home/hermes/.local/bin:/root/.local/bin:/usr/local/sbin/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

RUN install -d /opt/data/home/.nuget/Nuget \
            /opt/data/home/.nuget/packages \
            /opt/data/home/.dotnet/tools \
            /opt/data/.npm

RUN --mount=type=cache,target=/home/hermes/.nuget,sharing=locked \
    dotnet tool install --global roslyn-language-server --prerelease


# RUN UV_CACHE_DIR=/var/vache/uv \
#     UV_TOOL_DIR=/opt/uv/tools \
#     UV_TOOL_BIN_DIR=/usr/local/bin

# RUN install -d -m 0755 /var/cache/uv /opt/uv/tools

# RUN --mount=type=cache,target=/var/cache/uv,sharing=locked \
#     uv tool install graphify && graphify install --platform hermes

USER hermes
