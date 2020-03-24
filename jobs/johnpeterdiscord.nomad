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

  vault {
    policies = [
      "johnpeterdiscord"]

    change_mode = "signal"
    change_signal = "SIGHUP"
  }

  group "JohnPeterDiscord" {
    count = 1

    restart {
      attempts = 2
      interval = "5m"
      delay = "15s"
      mode = "fail"
    }

    task "DiscordBot" {
      driver = "docker"

      config {
        image = "srnd/johnpeter-discord:86aff91875d2f753567635e2f206d304a48dfe31"

        dns_servers = ["169.254.1.1"]
      }

      template {
        data = <<EOH
                {{- with secret "kv/data/johnpeterdiscord" -}}
                {{- .Data.data.serviceAccount -}}
                {{ end }}
                EOH

        destination = "/local/serviceAccount.json"
        change_mode = "restart"
      }

      env {
        GOOGLE_APPLICATION_CREDENTIALS = "/local/serviceAccount.json"
      }

      template {
        data = <<EOH
                {{- with secret "kv/data/johnpeterdiscord" -}}
                BOT_TOKEN={{ .Data.data.BOT_TOKEN }}
                CLEVERBOT_API_KEY={{ .Data.data.CLEVERBOT_API_KEY }}
                RAYGUN_KEY={{ .Data.data.RAYGUN_KEY }}
                {{ end }}
                EOH

        destination = "/local/env.env"
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
