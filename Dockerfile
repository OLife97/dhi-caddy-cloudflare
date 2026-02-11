# ARG to get last version
ARG CADDY_VERSION

FROM dhi.io/golang:1.25-debian13-dev AS builder
ARG CADDY_VERSION 

# install xcaddy
RUN CGO_ENABLED=0 go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

WORKDIR /build

# xcaddy Builds
RUN xcaddy build v${CADDY_VERSION} \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/porech/caddy-maxmind-geolocation \
    --with github.com/hslatman/caddy-crowdsec-bouncer

# Make the image
FROM dhi.io/caddy:2
COPY --from=builder /build/caddy /usr/local/bin/caddy
USER 65532:65532
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
