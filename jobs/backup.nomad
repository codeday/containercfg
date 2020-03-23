job "backup" {
  datacenters = ["srnd"]
  type        = "service"

  group "restic_fileshare" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "restic_fileshare" {
      driver = "docker"

      vault {
        policies = ["backup"]
      }

      template {
        data = <<EOF
          {{- with secret "kv/data/backup" -}}
          RESTIC_REPOSITORY={{ .Data.data.restic_repository }}/fileshare
          RESTIC_PASSWORD={{ .Data.data.restic_password }}
          AWS_ACCESS_KEY_ID={{ .Data.data.aws_access_key_id }}
          AWS_SECRET_ACCESS_KEY={{ .Data.data.aws_access_key }}
          MAILX_ARGS={{ .Data.data.mailx }}
          {{ end }}
        EOF
        destination = "local/file.env"
        env         = true
      }

      env {
        BACKUP_CRON = "30 7 * * *"
        RESTIC_FORGET_ARGS = "--prune --keep-last 10 --keep-hourly 24 --keep-daily 7 --keep-weekly 52 --keep-monthly 120 --keep-yearly 100"
      }

      config {
        image = "lobaro/restic-backup-docker:1.2-0.9.4"
        dns_servers = ["169.254.1.1"]
        volumes = [
          "/fileshare:/data"
        ]
      }

      resources {
        cpu    = 400
        memory = 128
      }
    }
  }

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
          TIME_SPEC=0 7 * * *
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
          TIME_SPEC=0 7 * * *
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
