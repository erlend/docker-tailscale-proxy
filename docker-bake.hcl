target "default" {
  pull = true
  output = ["type=docker"]
  tags = ["erlend/tailscale-proxy:latest"]
}

target "release" {
  inherits = ["default"]
  output = ["type=registry"]
  platforms = ["linux/amd64", "linux/arm64"]
}
