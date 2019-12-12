job "data" {
  region      = "global"
  datacenters = ["srnd"]
  type        = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = true
    canary = 0
  }

  constraint {
    operator  = "distinct_hosts"
    value     = "true"
  }

  group "data" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "fathom" {
      driver = "docker"

      config {
      	image = "usefathom/fathom:latest"
        port_map = {
          http = 8080
        }
        dns_servers = ["169.254.1.1"]
      }

      vault {
        policies = ["fathom"]
      }

      template {
        data = <<EOF
{{- with secret "kv/data/fathom" -}}
FATHOM_DATABASE_USER={{ .Data.data.mysql_user }}
FATHOM_DATABASE_PASSWORD={{ .Data.data.mysql_pass }}
FATHOM_SECRET={{ .Data.data.secret }}
{{ end }}
EOF
        destination = "local/file.env"
        env         = true
      }

      env {
        "FATHOM_GZIP" = "true",
        "FATHOM_DEBUG" = "false",
        "FATHOM_SERVER_ADDR" = ":8080",
        "FATHOM_DATABASE_DRIVER" = "mysql",
        "FATHOM_DATABASE_NAME" = "fathom",
        "FATHOM_DATABASE_HOST" = "mysql-server.service.consul",
        "FATHOM_DATABASE_SSLMODE" = ""
      }

      service {
        name = "fathom"
        port = "http"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.data-fathom-http.rule=Host(`data.srnd.org`)",
          "traefik.http.routers.data-fathom.rule=Host(`data.srnd.org`)",
          "traefik.http.routers.data-fathom.tls=true",
          "traefik.http.routers.data-fathom.tls.certresolver=srnd-org",
          "traefik.http.routers.data-fathom.tls.domains[0].main=*.srnd.org",
          "traefik.http.routers.data-fathom.tls.domains[0].sans=srnd.org",
          "traefik.http.services.data-fathom.loadbalancer.sticky=true",

          "traefik.tags=service",
          "traefik.frontend.rule=Host:data.srnd.org"
        ]
      }

      resources {
        network {
          port "http" {}
        }
      }
    }
  }
}
