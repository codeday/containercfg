job "graphql" {
  datacenters = ["srnd"]

  type = "service"

  reschedule {
    delay          = "30s"
    delay_function = "constant"
    unlimited      = true
  }

  update {
    max_parallel      = 1
    health_check      = "checks"
    min_healthy_time  = "10s"
    healthy_deadline  = "5m"
    progress_deadline = "10m"
    auto_revert       = true
    canary            = 0
    stagger           = "30s"
  }

  group "graphql-server" {
    count = 1

    restart {
      interval = "10m"
      attempts = 2
      delay    = "15s"
      mode     = "fail"
    }

    task "graphql-server" {
      driver = "docker"

      config {
        image = "srnd/gql-server:latest"

        port_map = {
          http = 4000
        }
      }

      env {
        NODE_ENV = "production"
      }

      service {
        name = "graphql-server"
        port = "http"
        tags = [
          "traefik.tags=service",
          "traefik.frontend.rule=Host:graph.srnd.org",
        ]

        check {
          name     = "graphql health using test query"
          port     = "http"
          type     = "http"
          path     = "/?query={__schema{types{name}}}"
          method   = "GET"
          interval = "10s"
          timeout  = "2s"
        }

        check_restart {
          limit = 3
          grace = "10s"
          ignore_warnings = false
        }
      }

      resources {
        network {
          port "http" {}
        }
      }
    }
  }
}
