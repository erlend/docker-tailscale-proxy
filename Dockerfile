FROM caddy:2.7.6-alpine as caddy
FROM tailscale/tailscale:v1.58.2 as tailscale

# Build tailscale.nginx-auth
FROM golang:1.22-alpine as build

# Copy Tailscale into image so we can get the current version
COPY --from=tailscale /usr/local/bin/tailscale /usr/local/bin/

# Download Tailscale source code
RUN VERSION=$(tailscale --version | head -n1) \
 && wget -qO- "https://github.com/tailscale/tailscale/archive/refs/tags/v${VERSION}.tar.gz" \
  | tar -zx \
 && mv "tailscale-${VERSION}" /build
WORKDIR /build/cmd/nginx-auth

# Build tailscale.nginx-auth
ARG TARGETARCH="amd64"
ARG TARGETOS="linux"
RUN CGO_ENABLED=0 GOARCH="$TARGETARCH" GOOS="$TARGETOS" go build -o tailscale.nginx-auth .

# Create release image
FROM alpine:3.19
RUN apk add --no-cache s6-overlay
COPY --from=caddy /usr/bin/caddy /usr/local/bin/
COPY --from=tailscale /usr/local/bin/* /usr/local/bin/
COPY --from=build /build/cmd/nginx-auth/tailscale.nginx-auth /usr/local/bin/
COPY ./etc /etc
ENV TS_AUTH_ONCE="true" \
    TS_STATE_DIR="/var/lib/tailscale" \
    TS_SOCKET="/var/run/tailscale/tailscaled.sock"
ENTRYPOINT ["/init"]
