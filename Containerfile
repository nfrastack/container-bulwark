# SPDX-FileCopyrightText: © 2026 Nfrastack <code@nfrastack.com>
#
# SPDX-License-Identifier: MIT

ARG \
    BASE_IMAGE

FROM ${BASE_IMAGE}

LABEL \
        org.opencontainers.image.title="Bulwark" \
        org.opencontainers.image.description="Webmail Client" \
        org.opencontainers.image.url="https://hub.docker.com/r/nfrastack/bulwark" \
        org.opencontainers.image.documentation="https://github.com/nfrastack/container-bulwark/blob/main/README.md" \
        org.opencontainers.image.source="https://github.com/nfrastack/container-bulwark.git" \
        org.opencontainers.image.authors="Nfrastack <code@nfrastack.com>" \
        org.opencontainers.image.vendor="Nfrastack <https://www.nfrastack.com>" \
        org.opencontainers.image.licenses="AGPL-3.0-only"

ARG \
    BULWARK_VERSION="1.12.0" \
    BULWARK_REPO_URL="https://github.com/bulwarkmail/webmail" \
    BULWARK_RELAY_VERSION="main" \
    BULWARK_RELAY_REPO_URL="https://github.com/bulwarkmail/relay" \
    GIT_COMMIT="unknown" \
    NEXT_PUBLIC_BASE_PATH="" \
    NEXT_PUBLIC_DEFAULT_LOCALE=""

COPY CHANGELOG.md /usr/src/container/CHANGELOG.md
COPY LICENSE /usr/src/container/LICENSE
COPY README.md /usr/src/container/README.md
COPY build-assets /build-assets

ENV \
    CONTAINER_ENABLE_MESSAGING=FALSE \
    IMAGE_NAME="nfrastack/bulwark" \
    IMAGE_REPO_URL="https://github.com/nfrastack/container-bulwark/"

RUN echo "" && \
    BUILD_ENV=" \
                    10-nginx/BULWARK_MODE=FULL \
                    10-nginx/BULWARK_LISTEN_PORT=3000 \
                    10-nginx/ENABLE_NGINX=FALSE \
                    10-nginx/NGINX_CREATE_SAMPLE_HTML=FALSE \
                    10-nginx/NGINX_SITE_ENABLED=bulwark \
                    10-nginx/NGINX_PROXY_URL="http://localhost:[env:BULWARK_LISTEN_PORT]" \
               " && \
    BULWARK_BUILD_DEPS_ALPINE=" \
                                git \
                                nodejs \
                                npm \
                             " && \
    BULWARK_RUN_DEPS_ALPINE=" \
                                jq \
                                moreutils \
                                nodejs \
                             " && \
    BULWARK_BUILD_DEPS_DEBIAN=" \
                                git \
                                nodejs \
                                npm \
                             " && \
    BULWARK_RUN_DEPS_DEBIAN=" \
                                moreutils \
                                nodejs \
                             " && \
    source /container/base/functions/container/build && \
    container_build_log image && \
    \
    create_user bulwark 2525 bulwark 2525 /dev/null && \
    create_user relay 2526 relay 2526 /dev/null && \
    package update && \
    package upgrade && \
    package install \
                        BULWARK_BUILD_DEPS \
                        BULWARK_RUN_DEPS \
                        && \
    \
    clone_git_repo "${BULWARK_REPO_URL}" "${BULWARK_VERSION}" /usr/src/bulwark && \
    cd /usr/src/bulwark && \
    build_assets src /usr/src/bulwark && \
    build_assets scripts && \
    export NEXT_TELEMETRY_DISABLED=1 && \
    export GIT_COMMIT="${GIT_COMMIT}" && \
    export NEXT_PUBLIC_BASE_PATH="${NEXT_PUBLIC_BASE_PATH}" && \
    export NEXT_PUBLIC_DEFAULT_LOCALE="${NEXT_PUBLIC_DEFAULT_LOCALE}" && \
    npm ci && \
    rm -rf "app/api/dev-jmap" && \
    find . -path ./node_modules -prune -o \
        \( -name __tests__ -o -name "*.test.ts" -o -name "*.test.tsx" \) \
        -prune -exec rm -rf {} + && \
    \
    npx next build --webpack && \
    mkdir -p /app && \
    cp -aR public /app/ && \
    cp -aR .next/standalone/. /app/ && \
    mkdir -p /app/.next && \
    cp -aR .next/static /app/.next/static && \
    echo "${BULWARK_VERSION}" > /app/.bulwark-version && \
    mkdir -p /container/data/bulwark && \
    cp -a .env.example /container/data/bulwark/env.example && \
    chown -R bulwark:bulwark /app && \
    \
    export CI=true && \
    LITE_TARGET=static npm run build:lite && \
    mkdir -p /www/html && \
    cp -aR out/. /www/html/ && \
    rm -f /www/html/config.json && \
    echo "${BULWARK_VERSION}" > /www/html/.bulwark-version && \
    chown -R nginx:www-data /www/html && \
    \
    clone_git_repo "${BULWARK_RELAY_REPO_URL}" "${BULWARK_RELAY_VERSION}" /usr/src/relay && \
    cd /usr/src/relay && \
    build_assets src /usr/src/relay && \
    npm ci --no-audit --no-fund && \
    npx tsc && \
    mkdir -p /opt/relay && \
    cp -aR dist package.json package-lock.json /opt/relay/ && \
    cd /opt/relay && \
    npm ci --omit=dev --no-audit --no-fund && \
    npm cache clean --force && \
    echo "${BULWARK_RELAY_VERSION}" > /opt/relay/.relay-version && \
    chown -R relay:relay /opt/relay && \
    cd /usr/src/bulwark && \
    container_build_log add "Bulwark Webmail" "${BULWARK_VERSION}" "${BULWARK_REPO_URL}" && \
    container_build_log add "Bulwark Relay" "${BULWARK_RELAY_VERSION}" "${BULWARK_RELAY_REPO_URL}" && \
    package remove \
                    BULWARK_BUILD_DEPS \
                    && \
    package cleanup

COPY rootfs /
