job "traefik" {
  datacenters = ["srnd"]
  type        = "system"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = true
    canary = 0
  }

  group "traefik" {
    count = 1

    volume "acme" {
      type      = "host"
      read_only = false
      source    = "acme"
    }

    task "traefik" {
      driver = "docker"

      volume_mount {
        volume      = "acme"
        destination = "/acme"
        read_only   = false
      }

      config {
        image        = "traefik:2.1"
        network_mode = "host"
        dns_servers = ["169.254.1.1"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml"
        ]
      }

      vault {
        policies = ["acme"]
      }

      template {
        data = <<EOF
{{- with secret "kv/data/cloudflare" -}}
CF_DNS_API_TOKEN={{ .Data.data.dns_api_key }}
CLOUDFLARE_EMAIL={{ .Data.data.email }}
CLOUDFLARE_API_KEY={{ .Data.data.api_key }}
{{ end }}
{{- with secret "kv/data/ns1" -}}
NS1_API_KEY={{ .Data.data.api_key }}
{{ end }}
EOF
        destination = "local/file.env"
        env         = true
      }

      resources {
        cpu = 100
        memory = 128
        network {
          port "http" {
            static = 80
          }

          port "https" {
            static = 443
          }

          port "api" {
            static = 8080
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
        tags = [
          "traefik.http.routers.http-catchall.rule=hostregexp(`{host:.+}`)",
          "traefik.http.routers.http-catchall.entrypoints=http",
          "traefik.http.routers.http-catchall.middlewares=redirect-to-https@consulcatalog",
          "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
        ]
      }

      template {
        data = <<EOF
          [providers.consulCatalog]
            exposedByDefault = false
            [providers.consulCatalog.endpoint]
              address = "m.srnd.cloud:8500"
              scheme = "http"

          [accessLog]

          [entryPoints]
            [entryPoints.http]
              address = ":80"
              [entryPoints.http.forwardedHeaders]
                trustedIPs = ["173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20", "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/12", "172.64.0.0/13", "131.0.72.0/22"]
            [entryPoints.https]
              address = ":443"

          [api]
            insecure = true
            dashboard = true

          [certificatesResolvers.srnd-org.acme]
            storage = "/acme/srnd-org.json"
            email = "team@srnd.org"
            [certificatesResolvers.srnd-org.acme.dnsChallenge]
              provider = "cloudflare"

          [certificatesresolvers.srnd-to.acme]
            storage = "/acme/srnd-to.json"
            email = "team@srnd.org"
            [certificatesresolvers.srnd-to.acme.dnschallenge]
              provider = "cloudflare"

          [certificatesResolvers.codeday-org.acme]
            storage = "/acme/codeday-org.json"
            email = "team@srnd.org"
            [certificatesResolvers.codeday-org.acme.dnsChallenge]
              provider = "ns1"

          [certificatesresolvers.codeday-vip.acme]
            storage = "/acme/codeday-vip.json"
            email = "team@srnd.org"
            [certificatesresolvers.codeday-vip.acme.dnschallenge]
              provider = "cloudflare"

          [certificatesResolvers.playcodecup-com.acme]
            storage = "/acme/playcodecup-com.json"
            email = "team@srnd.org"
            [certificatesResolvers.playcodecup-com.acme.dnsChallenge]
              provider = "cloudflare"

          [certificatesresolvers.codecupchallenge-com.acme]
            storage = "/acme/codecupchallenge-com.json"
            email = "team@srnd.org"
            [certificatesresolvers.codecupchallenge-com.acme.dnschallenge]
              provider = "cloudflare"
EOF

        destination = "local/traefik.toml"
      }
    }
  }
}
