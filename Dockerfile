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

# FIX FOR CVE-2026-33186 and CVE-2026-30836 , disabled some replace dependencies, keeped for reference. 
 RUN go mod edit -replace google.golang.org/grpc=google.golang.org/grpc@v1.79.3 \
     && go mod edit -replace github.com/smallstep/certificates=github.com/smallstep/certificates@v0.30.0
#     && go mod edit -replace

RUN go mod tidy
RUN go build -o /build/caddy main.go

RUN mkdir -p /target_fs/var/log/caddy \
             /target_fs/data \
             /target_fs/config \
             /target_fs/etc/caddy \
    && chown -R 65532:65532 /target_fs
    
# --- Stage 2: Runtime (DHI Hardened) ---
FROM dhi.io/caddy:2
COPY --chown=65532:65532 --from=builder /target_fs /
COPY --from=builder /build/caddy /usr/local/bin/caddy

VOLUME ["/var/log/caddy", "/data", "/config"]
USER 65532:65532

CMD ["run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
