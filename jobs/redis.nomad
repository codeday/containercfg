job "redis" {
  datacenters = ["srnd"]
  type        = "service"

  group "redis" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis"
        port_map {
          db = 6379
        }
        command = "sh"
        args = ["-c", "rm -f /data/dump.rdb && redis-server --save ''"]
        volumes = [
          "/fileshare/redis:/data"
        ]
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
