
# Hardened Caddy (Cloudflare + GeoIP)

Automated community build of Caddy v2 based on **DHI Hardened Images**.
Includes `xcaddy` modules for **Cloudflare DNS** validation and **MaxMind GeoIP**.
Not affiliated with the official Caddy or DHI projects.

Builds automatically on the 1st of every month to pull the latest upstream Caddy version and Go dependencies.

## Modules Included
*   [`caddy-dns/cloudflare`](https://github.com/caddy-dns/cloudflare) - For DNS-01 challenges and solving TLS behind Cloudflare proxy.
*   [`porech/caddy-maxmind-geolocation`](https://github.com/porech/caddy-maxmind-geolocation) - For country-based blocking/allowlisting.

*Base image documentation:* [DHI Caddy Guides](https://hub.docker.com/hardened-images/catalog/dhi/caddy/guides)

## Usage

### Docker Compose
**Note:** Since this is based on DHI hardened images, it runs as non-root user `65532`. You cannot bind to ports `< 1024` inside the container. Map external 80/443 to internal **8080/8443**.
It is highly recommended to use an `.env` file for your Cloudflare API token instead of hardcoding it in the compose file.

```yaml
services:
  caddy:
    image: ghcr.io/olife97/dhi-caddy-cloudflare:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:8080"
      - "443:8443"
      - "443:8443/udp" # HTTP/3
    environment:
      # Pass the variable from your .env file
      - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./data:/data
      - ./config:/config
      - ./db:/db:ro # path for MaxMind GeoLite2.mmdb file

    # Optional: If you need to write to volumes or use UNRAID, ensure permissions are set for uid 65532
    # user: "65532:65532"
```
