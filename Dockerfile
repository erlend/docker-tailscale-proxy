FROM caddy:2.7.6-alpine as caddy
FROM tailscale/tailscale:v1.62.1 as tailscale
FROM alpine:3.19 as base

# Build tailscale.nginx-auth
FROM base as build

# Install Go
RUN apk add --no-cache go

# Copy Tailscale into image so we can get the current version
COPY --from=tailscale /usr/local/bin/tailscale /usr/local/bin/

# Download Tailscale source code
RUN VERSION=$(tailscale --version | head -n1) \
 && wget -qO- "https://github.com/tailscale/tailscale/archive/refs/tags/v${VERSION}.tar.gz" \
  | tar -zx \
 && mv "tailscale-${VERSION}" /build
WORKDIR /build/cmd/nginx-auth

# Build tailscale.nginx-auth
RUN CGO_ENABLED=0 go build -o tailscale.nginx-auth .

# Create release image
FROM base
RUN apk add --no-cache s6-overlay \
 && mkdir -p /etc/caddy /var/lib/tailscale/ /var/run/tailscale
COPY --from=caddy /usr/bin/caddy /usr/local/bin/
COPY --from=tailscale /usr/local/bin/* /usr/local/bin/
COPY --from=build /build/cmd/nginx-auth/tailscale.nginx-auth /usr/local/bin/
COPY ./s6-rc.d /etc/s6-overlay/s6-rc.d
ENV TS_AUTH_ONCE="true" \
    TS_STATE_DIR="/var/lib/tailscale" \
    TS_SOCKET="/var/run/tailscale/tailscaled.sock"
ENTRYPOINT ["/init"]
