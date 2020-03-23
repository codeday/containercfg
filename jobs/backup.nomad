job "backup" {
  datacenters = ["srnd"]
  type        = "service"

  group "backup_mysql" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "backup_mysql" {
      driver = "docker"

      vault {
        policies = ["backup"]
      }

      template {
        data = <<EOF
          {{- with secret "kv/data/backup" -}}
          MYSQLDUMP_OPTIONS=-h mysql-server.service.consul -u {{ .Data.data.mysql_username }} --password="{{ .Data.data.mysql_password }}" --skip-lock-tables --quick --databases
          DATABASE_NAME=clear ctfd fathom sendy yourls
          OUTPUT_COMMAND=cat - > /dump/mysql-$(date +%Y-%m-%d-%H-%M).sql
          {{ end }}
        EOF
        destination = "local/file.env"
        env         = true
      }

      config {
        image = "bigtruedata/mysqldump:latest"
        dns_servers = ["169.254.1.1"]
        volumes = [
          "/fileshare/db_backup:/dump"
        ]
      }

      resources {
        cpu    = 400
        memory = 128
      }
    }
  }

  group "backup_pgsql" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "backup_pgsql" {
      driver = "docker"

      vault {
        policies = ["backup"]
      }

      template {
        data = <<EOF
          {{- with secret "kv/data/backup" -}}
          PGSQLDUMP_OPTIONS=-h postgres-master-pg.service.consul -U {{ .Data.data.pgsql_username }}
          PASSWORD={{ .Data.data.pgsql_password }}
          DATABASE_ALL=y
          OUTPUT_COMMAND=cat - > /dump/pgsql-$(date +%Y-%m-%d-%H-%M).sql
          TIME_SPEC=0 * * * *
          {{ end }}
        EOF
        destination = "local/file.env"
        env         = true
      }

      config {
        image = "srnd/docker-pgsqldump:latest"
        dns_servers = ["169.254.1.1"]
        volumes = [
          "/fileshare/db_backup:/dump"
        ]
      }

      resources {
        cpu    = 400
        memory = 128
      }
    }
  }
}
