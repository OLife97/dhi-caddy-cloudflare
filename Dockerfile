ARG BUILDER_IMAGE=dhi.io/golang:1.26-debian12-dev
ARG RUNTIME_IMAGE=dhi.io/caddy:2

FROM ${BUILDER_IMAGE} AS builder
ENV CGO_ENABLED=0

# Installa xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

WORKDIR /build

# Prova a compilare sperando che Go 1.26 risolva le dipendenze
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/porech/caddy-maxmind-geolocation \
    --with github.com/hslatman/caddy-crowdsec-bouncer

FROM ${RUNTIME_IMAGE}
COPY --from=builder /build/caddy /usr/local/bin/caddy
USER 65532:65532
CMD ["run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
