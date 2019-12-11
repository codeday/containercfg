job "mattermost" {
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

  group "mattermost-bots" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "johnpeter-mattermost" {
      driver = "docker"

      config {
        image = "https://docker.pkg.github.com/srnd/johnpeter-mattermost/johnpeter-mattermost:latest"
      }

      vault {
        policies = ["mattermost-bots"]
      }

      template {
        data = <<EOF
{{- with secret "kv/data/mattermost-bots" -}}
MATTERMOST_BOT_TOKEN={{ .Data.data.johnpeter_mm_token }}
MATTERMOST_BOT_LOGIN={{ .Data.data.johnpeter_mm_user }}
MATTERMOST_BOT_PASSWORD={{ .Data.data.johnpeter_mm_password }}
CLEVERBOT_API_KEY={{ .Data.data.cleverbot_token }}
{{ end }}
EOF
        destination = "local/file.env"
        env         = true
      }

      env {
        "MATTERMOST_BOT_URL"      = "https://chat.srnd.org/api/v4"
      }
    }
  }
}
