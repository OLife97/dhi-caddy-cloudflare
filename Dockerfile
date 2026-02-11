# ARG to get last version
ARG CADDY_VERSION

FROM dhi.io/golang:1.25-debian13-dev AS builder
ARG CADDY_VERSION 

# install xcaddy
RUN CGO_ENABLED=0 go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

WORKDIR /build

# xcaddy Builds
# Build Caddy with added modules AND forced dependency upgrades
RUN xcaddy build \
    # Moduli standard
    --with github.com/caddy-dns/cloudflare \
    --with github.com/porech/caddy-maxmind-geolocation \
    --with github.com/hslatman/caddy-crowdsec-bouncer \
    # FIX VULNERABILITY:
    # CVE-2025-44005, CVE-2025-66406 (Smallstep Certificates)
    --with github.com/smallstep/certificates@v0.29.0 \
    # CVE-2025-59530, CVE-2025-64702 (QUIC-Go)
    --with github.com/quic-go/quic-go@v0.57.0 \
    # CVE-2025-30204 (JWT)
    --with github.com/golang-jwt/jwt/v4@v4.5.2 \
    # CVE-2025-29786, CVE-2025-68156 (Expr Lang)
    --with github.com/expr-lang/expr@v1.17.7 \
    # CVE-2025-47914 (Go Crypto)
    --with golang.org/x/crypto@v0.45.0 \
    # CVE-2026-25793 (Nebula)
    --with github.com/slackhq/nebula@v1.10.3

# Make the image
FROM dhi.io/caddy:2
COPY --from=builder /build/caddy /usr/local/bin/caddy
USER 65532:65532
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
