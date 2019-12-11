job "traefik" {
  datacenters = ["srnd"]
  type        = "system"

  group "traefik" {
    count = 1

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:1.7"
        network_mode = "host"

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
    [entryPoints.http]
    address = ":80"
    [entryPoints.traefik]
    address = ":8081"

[api]
    dashboard = true
    insecure = true

[consulCatalog]
endpoint = "127.0.0.1:8500"
domain = "consul.localhost"
prefix = "traefik"
constraints = ["tag==service"]
EOF

        destination = "local/traefik.toml"
      }

      resources {
        network {
          port "http" {
            static = 80
          }

          port "api" {
            static = 8081
          }
        }
      }

      service {
        name = "traefik"
        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
