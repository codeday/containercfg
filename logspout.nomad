job "logspout" {
  datacenters = ["srnd"]
  type        = "system"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = true
    canary = 0
  }

  group "logspout" {
    count = 1

    task "logspout" {
      driver = "docker"

      config {
        image        = "gliderlabs/logspout:latest"
        network_mode = "host"
        userns_mode = "host"
        dns_servers = ["169.254.1.1"]
        command = "syslog://splunk-syslog.service.consul:8514"

        port_map {
          status = 8980
        }

        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }

      env {
        "PORT" = "8980"
      }

      service {
        name = "logspout"
        port = "status"
      }

      resources {
        cpu = 100
        memory = 128
        network {
          port "status" {}
        }
      }
    }
  }
}
