job "mysql-server" {
  datacenters = ["srnd"]
  type        = "service"

  group "mysql-server" {
    count = 1

    volume "mysql" {
      type      = "host"
      read_only = false
      source    = "mysql"
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "mysql-server" {
      driver = "docker"

      volume_mount {
        volume      = "mysql"
        destination = "/var/lib/mysql"
        read_only   = false
      }

      vault {
        policies = ["mysql-server"]
      }

      template {
        data = <<EOF
{{- with secret "kv/data/mysql-server" -}}
MYSQL_ROOT_PASSWORD={{ .Data.data.root_password }}
{{ end }}
EOF
        destination = "local/file.env"
        env         = true
      }

      config {
        image = "mysql"
        port_map {
          db = 3306
        }
      }

      resources {
        cpu    = 500
        memory = 1024

        network {
          port "db" {
            static = 3306
          }
        }
      }

      service {
        name = "mysql-server"
        port = "db"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
