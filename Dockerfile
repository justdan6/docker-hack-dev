# syntax=docker/dockerfile:1
# HHVM's last published distro package requires Ubuntu 20.04 libraries.
FROM ubuntu:20.04

ARG TARGETARCH
ARG COMPOSER_VERSION=2.11.1
ARG COMPOSER_SHA256=6f1b891e1d4927d62740276c540fb490e47689e19e102c49e8da849794882f8c

ENV HHVM_DISABLE_NUMA=true \
    HHVM_DISABLE_PERSONALITY=true \
    COMPOSER_NO_INTERACTION=1

RUN test "$TARGETARCH" = amd64 \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates curl git lsof php-cli php-curl php-mbstring php-xml unzip \
    && rm -rf /var/lib/apt/lists/*

# dl.hhvm.com's HTTPS certificate has expired. Verify the frozen package by
# its published SHA-256 instead of disabling TLS verification for downloads.
RUN curl -fL --retry 3 \
        http://dl.hhvm.com/ubuntu/pool/main/h/hhvm/hhvm_4.172.1-1~focal_amd64.deb \
        -o /tmp/hhvm.deb \
    && echo 'ee567aa0f7eee3c00a73e9265fdd3998c9b3c40b60028c236ed93933abe67763  /tmp/hhvm.deb' | sha256sum -c - \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends /tmp/hhvm.deb \
    && rm -rf /tmp/hhvm.deb /var/lib/apt/lists/*

ARG HACK_UID=1000
RUN curl -fL --retry 3 "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar" \
        -o /usr/local/bin/composer \
    && echo "${COMPOSER_SHA256}  /usr/local/bin/composer" | sha256sum -c - \
    && chmod +x /usr/local/bin/composer \
    && useradd --create-home --uid "$HACK_UID" --shell /bin/bash hack \
    && mkdir /app \
    && chown hack:hack /app

COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint
COPY docker/hhvm.ini /etc/hhvm/php.ini
RUN chmod +x /usr/local/bin/docker-entrypoint

WORKDIR /app
COPY --chown=hack:hack . /app
USER hack
EXPOSE 8080
ENTRYPOINT ["docker-entrypoint"]
CMD ["hhvm", "-m", "server", "-p", "8080", "-d", "hhvm.server.source_root=/app/src"]
