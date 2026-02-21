# --- Stage 1: Builder ---
FROM golang:1.26 AS builder

ENV CGO_ENABLED=0
WORKDIR /build

# main.go: Caddy + plugin
RUN cat << 'EOF' > main.go
package main

import (
    caddycmd "github.com/caddyserver/caddy/v2/cmd"
    _ "github.com/caddyserver/caddy/v2/modules/standard"
    _ "github.com/caddy-dns/cloudflare"
    _ "github.com/porech/caddy-maxmind-geolocation"
    _ "github.com/hslatman/caddy-crowdsec-bouncer"
    _ "github.com/mholt/caddy-dynamicdns"
)

func main() {
    caddycmd.Main()
}
EOF

RUN go mod init dhi-caddy-cloudflare

# download caddy and modules @latest
RUN go get \
    github.com/caddyserver/caddy/v2@latest \
    github.com/caddy-dns/cloudflare@latest \
    github.com/porech/caddy-maxmind-geolocation@latest \
    github.com/hslatman/caddy-crowdsec-bouncer@latest \
    github.com/mholt/caddy-dynamicdns@latest

# FIX CVE: Using nebula v1.9.7
RUN go mod edit -replace github.com/smallstep/certificates=github.com/smallstep/certificates@v0.29.0 \
    && go mod edit -replace github.com/slackhq/nebula=github.com/slackhq/nebula@v1.9.7 \
    && go mod edit -replace github.com/expr-lang/expr=github.com/expr-lang/expr@v1.17.7 \
    && go mod edit -replace github.com/quic-go/quic-go=github.com/quic-go/quic-go@v0.57.0 \
    && go mod edit -replace github.com/golang-jwt/jwt/v4=github.com/golang-jwt/jwt/v4@v4.5.2 \
    && go mod edit -replace golang.org/x/crypto=golang.org/x/crypto@v0.47.0 \
    && go mod edit -replace github.com/go-chi/chi/v5=github.com/go-chi/chi/v5@v5.2.4

RUN go mod tidy
RUN go build -o /build/caddy main.go

# --- Stage 2: Runtime (DHI Hardened) ---
FROM dhi.io/caddy:2

COPY --from=builder /build/caddy /usr/local/bin/caddy
USER root
RUN mkdir -p /var/log/caddy /data /config /etc/caddy
RUN chown -R 65532:65532 /var/log/caddy /data /config /etc/caddy
VOLUME ["/var/log/caddy", "/data", "/config"]
USER 65532:65532

CMD ["run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
