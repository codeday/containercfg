job "JohnPeterDiscord" {
  region = "global"
  datacenters = ["srnd"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = true
    canary = 0
  }

  restart {
    attempts = 2
    interval = "5m"
    delay = "15s"
    mode = "fail"
  }

  vault {
    policies = [
      "johnpeterdiscord"]

    change_mode = "signal"
    change_signal = "SIGHUP"
  }

  group "JohnPeterDiscord" {
    count = 1

    task "DiscordBot" {
      driver = "docker"

      config {
        image = "srnd/johnpeter-discord:1.3"

        dns_servers = ["169.254.1.1"]
      }

      template {
        data = <<EOH
                {{- with secret "kv/data/johnpeterdiscord" -}}
                {{- .Data.data.serviceAccount -}}
                {{ end }}
                EOH

        destination = "/app/secrets/serviceAccount.json"
        change_mode = "restart"
      }

      template {
        data = <<EOH
                {{- with secret "kv/data/johnpeterdiscord" -}}
                BOT_TOKEN={{- .Data.data.BOT_TOKEN -}}
                GOOGLE_APPLICATION_CREDENTIALS={{- .Data.data.GOOGLE_APPLICATION_CREDENTIALS -}}
                {{ end }}
                EOH

        destination = "/app/secrets/env.env"
        change_mode = "restart"
        env = true
      }

      resources {
        cpu = 100
        memory = 100
      }
    }
  }
}