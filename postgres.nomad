job "main-postgres" {
  type = "service"
  datacenters = ["srnd"]

  vault {
    policies = ["postgres"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "postgres-master" {
    count = 1

    volume "postgresql-master" {
      type      = "host"
      read_only = false
      source    = "postgresql-master"
    }

    task "master-db" {
      driver = "docker"
        template {
          data = <<EOH
            {{- with secret "kv/data/postgres" -}}
            POSTGRESQL_REPLICATION_MODE="master"
            POSTGRESQL_REPLICATION_USER="{{ .Data.data.POSTGRESQL_REPLICATION_USER }}"
            POSTGRESQL_REPLICATION_PASSWORD="{{ .Data.data.POSTGRESQL_REPLICATION_PASSWORD }}"
            POSTGRESQL_USERNAME="{{ .Data.data.POSTGRESQL_USERNAME }}"
            POSTGRESQL_PASSWORD="{{ .Data.data.POSTGRESQL_PASSWORD }}"
            POSTGRESQL_DATABASE="{{ .Data.data.POSTGRESQL_DATABASE }}"
            {{ end }}
          EOH

          destination = "secrets/.env"
          env = true
        }

        volume_mount {
          volume      = "postgresql-master"
          destination = "/bitnami/postgresql"
          read_only   = false
        }
      config {
        image = "bitnami/postgresql:12"

        port_map {
          pg = 5432
        }

        dns_servers = ["169.254.1.1"]
      }

      resources {
        memory = 1024
        cpu = 500

        network {
          port "pg" {
            static = 5432
          }
        }
      }

      service {
        name = "postgres-master"
        port = "pg"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }

  group "postgres-slave" {
    count = 1

    volume "postgresql-slave" {
      type      = "host"
      read_only = false
      source    = "postgresql-slave"
    }

    task "slave-db" {
      driver = "docker"
        template {
          data = <<EOH
            {{- with secret "kv/data/postgres" -}}
            POSTGRESQL_REPLICATION_MODE="slave"
            POSTGRESQL_REPLICATION_USER="{{ .Data.data.POSTGRESQL_REPLICATION_USER }}"
            POSTGRESQL_REPLICATION_PASSWORD="{{ .Data.data.POSTGRESQL_REPLICATION_PASSWORD }}"
            POSTGRESQL_USERNAME="{{ .Data.data.POSTGRESQL_USERNAME }}"
            POSTGRESQL_PASSWORD="{{ .Data.data.POSTGRESQL_PASSWORD }}"
            POSTGRESQL_MASTER_HOST="postgres-master.service.consul"
            POSTGRESQL_MASTER_PORT_NUMBER="5432"
            {{ end }}
          EOH
  
          destination = "secrets/.env"
          env = true
        }

        volume_mount {
          volume      = "postgresql-slave"
          destination = "/bitnami/postgresql"
          read_only   = false
        }
      config {
        image = "bitnami/postgresql:12"

        port_map {
          pg = 5432
        }

        dns_servers = ["169.254.1.1"]

        logging {
          type = "journald"
          config {
            tag = "pg_docker_slave"
          }
        }
      }

      resources {
        memory = 1024
        cpu = 500

        network {
          port "pg" {
            static = 5433
          }
        }
      }

      service {
        name = "postgres-slave"
        port = "pg"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
  
}
