job "link-shortener" {
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

  group "link-shortener" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "yourls" {
      driver = "docker"

      config {
      	image = "yourls:1.7.4-apache"
        port_map = {
          http = 80
        }
        dns_servers = ["169.254.1.1"]
      }

      vault {
        policies = ["yourls"]
      }

      template {
        data = <<EOF
{{- with secret "kv/data/yourls" -}}
YOURLS_DB_USER={{ .Data.data.db_user }}
YOURLS_DB_PASS={{ .Data.data.db_pass }}
YOURLS_USER={{ .Data.data.user }}
YOURLS_PASS={{ .Data.data.pass }}
{{ end }}
EOF
        destination = "local/file.env"
        env         = true
      }

      env {
      "YOURLS_DB_HOST"   = "mysql-server.service.consul"
      "YOURLS_SITE"      = "https://srnd.to",
      "YOURLS_DB_PREFIX" = "yourls_"
      }

      service {
        name = "link-shortener"
        port = "http"
        tags = [
          "traefik.tags=service",
          "traefik.frontend.rule=Host:srnd.to"
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
