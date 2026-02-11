FROM caddy:builder AS builder
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/porech/caddy-maxmind-geolocation

FROM dhi.io/caddy:2-debian13-dev AS hardener
USER 0

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
RUN setcap cap_net_bind_service=+ep /usr/bin/caddy

FROM dhi.io/caddy:2
USER 0
COPY --from=hardener /usr/bin/caddy /usr/bin/caddy
USER 65532

WORKDIR /var/lib/caddy
ENTRYPOINT ["/usr/bin/caddy"]
CMD ["docker-proxy"]
