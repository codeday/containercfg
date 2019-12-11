job "codecup" {
  region      = "global"
  datacenters = ["srnd"]
  type        = "service"
  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  constraint {
    operator  = "distinct_hosts"
    value     = "true"
  }

  group "codecup" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "ctfd" {
      driver = "docker"
      config {
        image = "https://docker.pkg.github.com/srnd/ctfd/ctfd:latest"

        port_map = {
          http = 8000
        }

        dns_servers = ["169.254.1.1"]
        mounts = [
          {
            type = "tmpfs",
            target = "/var/uploads",
            readonly = false
          },
          {
            type = "tmpfs",
            target = "/var/log/CTFd",
            readonly = false
          },
          {
            type = "tmpfs",
            target = "/opt/CTFd/logs",
            readonly = false
          }
        ]
      }

      vault {
        policies = ["codecup"]
      }

      template {
        data = <<EOF
{{- with secret "kv/data/codecup" -}}
DATABASE_URL={{ .Data.data.DATABASE_URL }}
MAILGUN_KEY={{ .Data.data.MAILGUN_KEY }}
PUBNUB_SUB={{ .Data.data.PUBNUB_SUB }}
SECRET={{ .Data.data.SECRET }}
{{ end }}
EOF
        destination = "local/file.env"
        env         = true
      }


      env {
        "UPLOAD_FOLDER" = "/var/uploads"
        "REDIS_URL" = "redis://redis.service.consul:6379"
        "WORKERS" = "1"
        "ACCESS_LOG" = "-"
        "ERROR_LOG" = "-"
      }

      service {
        name = "ctfd"
        port = "http"
        tags = [
          "traefik.tags=service",
          "traefik.frontend.rule=Host:playcodecup.com",
          "traefik.backend.loadbalancer.sticky=true"
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
