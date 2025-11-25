FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/caddyserver/cache-handler

FROM caddy:latest AS base

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

FROM base AS cache

COPY Caddyfile.cache /etc/caddy/Caddyfile

FROM base AS nocache

COPY Caddyfile.nocache /etc/caddy/Caddyfile
