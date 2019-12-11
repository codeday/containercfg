job "email" {
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

  group "email" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "sendy" {
      driver = "docker"

      config {
      	image = "https://docker.pkg.github.com/srnd/sendy/sendy:latest"
        port_map = {
          http = 80
        }
        dns_servers = ["169.254.1.1"]
      }

      vault {
        policies = ["sendy"]
      }

      template {
        data = <<EOF
{{- with secret "kv/data/sendy" -}}
MYSQL_USER={{ .Data.data.mysql_user }}
MYSQL_PASS={{ .Data.data.mysql_pass }}
{{ end }}
EOF
        destination = "local/file.env"
        env         = true
      }

      env {
        "MYSQL_HOST" = "mysql-server.service.consul",
        "MYSQL_DB" = "sendy"
      }

      service {
        name = "sendy"
        port = "http"
        tags = [
          "traefik.tags=service",
          "traefik.frontend.rule=Host:email.srnd.org"
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
