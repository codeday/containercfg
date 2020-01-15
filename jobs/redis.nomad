job "redis" {
  datacenters = ["srnd"]
  type        = "service"

  group "redis" {
    count = 1

    volume "redis" {
      type      = "host"
      read_only = false
      source    = "redis"
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "redis" {
      driver = "docker"

      volume_mount {
        volume      = "redis"
        destination = "/data"
        read_only   = false
      }

      config {
        image = "redis"
        port_map {
          db = 6379
        }
      }

      resources {
        cpu    = 500
        memory = 512

        network {
          port "db" {
            static = 6379
          }
        }
      }

      service {
        name = "redis"
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
