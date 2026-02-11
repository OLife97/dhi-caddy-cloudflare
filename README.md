![Build Status](https://github.com/OLife97/dhi-caddy-cloudflare/actions/workflows/docker-image.yml/badge.svg)
![Last Commit](https://img.shields.io/github/last-commit/OLife97/dhi-caddy-cloudflare)
![License](https://img.shields.io/github/license/OLife97/dhi-caddy-cloudflare)
[![Docker Pull](https://img.shields.io/badge/docker%20pull-ghcr.io%2Folife97%2Fdhi--caddy--cloudflare-blue)](https://github.com/OLife97/dhi-caddy-cloudflare/pkgs/container/dhi-caddy-cloudflare)
# Hardened Caddy (Cloudflare + GeoIP + Crowdsec bouncer)

Automated community build of Caddy v2 based on **DHI Hardened Images**.
Includes essential modules for **DNS validation**, **Geo-blocking** and **CrowdSec integration**.

Not affiliated with the official Caddy or DHI projects.

Builds automatically on the 1st of every month to pull the latest upstream Caddy version and Go dependencies.

## Why Hardened?

This image is based on **DHI (Docker Hardened Images)**, offering significantly higher security compared to standard Docker images.

*   **Non-Root by Default:** Runs as user `65532`, preventing potential container breakout attacks from gaining root access to your host.
*   **Minimal Attack Surface:** Based on a "distroless-like" environment. No shell (`sh`, `bash`), no package managers (`apt`, `apk`), and no unnecessary binaries. Even if an attacker compromises Caddy, they have no tools to expand their foothold.
*   **Software Bill of Materials (SBOM):** DHI images are strictly monitored for vulnerabilities and dependencies.
*   **Production Ready:** Designed for environments where security compliance and stability are critical.

To keep the image reasonably safe, I scan it with Docker Scout and other tools, I override a few Go dependencies that were pulling older vulnerable versions via transitive deps.

### Current scan (Feb 2026)

Docker Scout summary:
- Critical: 0
- High: 1 (nebula)
- Unspecified: 1 (go-chi)

Details (from `docker scout cves`):
- `github.com/slackhq/nebula@1.9.7` → HIGH CVE-2026-25793 (fixed upstream in 1.10.3, but using 1.10.3 currently breaks compatibility in this build)
- `github.com/go-chi/chi/v5@5.2.3` → GHSA-mqqf-5wvp-8fh8 (fixed in 5.2.4)

Instead of relying on xcaddy, the Dockerfile uses `go mod edit -replace` to force a few libraries to patched versions when possible.
Verify locally docker scout cves `dhi-caddy-cloudflare:latest`

## Modules Included
| Module | Description | Link |
| :--- | :--- | :--- |
| **Cloudflare DNS** | DNS-01 challenge support for TLS (essential for wildcard certs or internal services). | [Repo](https://github.com/caddy-dns/cloudflare) |
| **MaxMind GeoIP** | Filter traffic by country (e.g., block CN, RU, etc.). | [Repo](https://github.com/porech/caddy-maxmind-geolocation) |
| **CrowdSec Bouncer** | Block malicious IPs using CrowdSec's collaborative threat intelligence. | [Repo](https://github.com/hslatman/caddy-crowdsec-bouncer) |

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
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    ports:
      - "80:8080"
      - "443:8443"
      - "443:8443/udp" # HTTP/3
    environment:
      # Always pass the variables from your .env file
      - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
      - CROWDSEC_API_KEY=${CROWDSEC_API_KEY} # If using CrowdSec - Requires a running CrowdSec agent (in another container or on host).
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./data:/data
      - ./config:/config
      - ./GeoLite2-Country.mmdb:/config/GeoLite2-Country.mmdb:ro # path for MaxMind GeoLite2.mmdb file

    # Optional: If you need to write to volumes or use UNRAID, ensure permissions are set for uid 65532
    # user: "65532:65532"
```
## Licenses & Acknowledgements

This project builds upon the work of several open-source projects.

*   **Caddy**: Licensed under [Apache 2.0](https://github.com/caddyserver/caddy/blob/master/LICENSE).
*   **Docker Hardened Images (DHI)**: Base images provided by Docker, Inc. under [Apache 2.0](https://hub.docker.com/hardened-images).
*   **caddy-dns/cloudflare**: Licensed under [Apache 2.0](https://github.com/caddy-dns/cloudflare/blob/master/LICENSE).
*   **porech/caddy-maxmind-geolocation**: Licensed under [Apache 2.0](https://github.com/porech/caddy-maxmind-geolocation/blob/master/LICENSE).

This repository itself is licensed under the **Apache 2.0 License**.

**Note on MaxMind GeoIP:**
This product includes GeoLite2 data created by MaxMind, available from [https://www.maxmind.com](https://www.maxmind.com).
If you use the GeoIP module, you must comply with the MaxMind End User License Agreement (EULA).
