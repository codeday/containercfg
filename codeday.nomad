job "codeday" {
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

  group "codeday-posters" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "posters" {
      driver = "docker"
      config {
        image = "docker.pkg.github.com/srnd/posters/posters:1.3.1"

        port_map = {
          http = 8000
        }
      }

      service {
        name = "posters-api"
        port = "http"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.posters-api-http.rule=Host(`posters.codeday.org`)",
          "traefik.http.routers.posters-api.rule=Host(`posters.codeday.org`)",
          "traefik.http.routers.posters-api.tls=true",
          "traefik.http.routers.posters-api.tls.certresolver=codeday-org",
          "traefik.http.routers.posters-api.tls.domains[0].main=*.codeday.org",
          "traefik.http.routers.posters-api.tls.domains[0].sans=codeday.org",
          "traefik.http.services.posters-api.loadbalancer.sticky=true",

          "traefik.tags=service",
          "traefik.frontend.rule=Host:posters.srnd.org",
        ]
      }
      resources {
        cpu = 200
        memory = 400

        network {
          port "http" {}
        }
      }
    }
  }

  group "codeday-present" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "present" {
      driver = "docker"

      config {
        image = "https://docker.pkg.github.com/srnd/codeday-present/codeday-present:latest"
        port_map = {
          http = 8000
        }
        dns_servers = ["169.254.1.1"]
      }

      vault {
        policies = ["codeday-present"]
      }

      template {
        data = <<EOF
{{- with secret "kv/data/codeday-present" -}}
CLEAR_PUBLIC={{ .Data.data.CLEAR_PUBLIC }}
CLEAR_PRIVATE={{ .Data.data.CLEAR_PRIVATE }}
CONTENTFUL_SPACE={{ .Data.data.CONTENTFUL_SPACE }}
CONTENTFUL_TOKEN={{ .Data.data.CONTENTFUL_TOKEN }}
{{ end }}
EOF
        destination = "local/file.env"
        env         = true
      }

      env {
        "PORT" = "8000",

      }

      service {
        name = "codeday-present"
        port = "http"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.codeday-present-http.rule=Host(`present.codeday.org`)",
          "traefik.http.routers.codeday-present.rule=Host(`present.codeday.org`)",
          "traefik.http.routers.codeday-present.tls=true",
          "traefik.http.routers.codeday-present.tls.certresolver=codeday-org",
          "traefik.http.routers.codeday-present.tls.domains[0].main=*.codeday.org",
          "traefik.http.routers.codeday-present.tls.domains[0].sans=codeday.org",

          "traefik.tags=service",
          "traefik.frontend.rule=Host:present.codeday.org"
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
