job "posters" {
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

  group "posters" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "api" {
      driver = "docker"
      config {
        image = "docker.pkg.github.com/srnd/posters/posters:0.10.1"

        port_map = {
          http = 8000
        }
      }

      service {
        name = "posters-api"
        port = "http"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.posters-api-http.rule=Host(`posters.srnd.org`)",
          "traefik.http.routers.posters-api.rule=Host(`posters.srnd.org`)",
          "traefik.http.routers.posters-api.tls=true",
          "traefik.http.routers.posters-api.tls.certresolver=srnd-org",
          "traefik.http.routers.posters-api.tls.domains[0].main=*.srnd.org",
          "traefik.http.routers.posters-api.tls.domains[0].sans=srnd.org",
          "traefik.http.services.posters-api.loadbalancer.sticky=true",

          "traefik.tags=service",
          "traefik.frontend.rule=Host:posters.srnd.org",
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
