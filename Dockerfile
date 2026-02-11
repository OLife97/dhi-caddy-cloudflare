FROM dhi.io/golang:1.26-bookworm-dev AS builder
ENV CGO_ENABLED=0

# Installa xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

WORKDIR /build
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/porech/caddy-maxmind-geolocation \
    --with github.com/hslatman/caddy-crowdsec-bouncer

FROM dhi.io/caddy:2
COPY --from=builder /build/caddy /usr/local/bin/caddy
USER 65532:65532
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
