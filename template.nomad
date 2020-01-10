job "[[ .job ]]" {
  region      = "[[ or .region "global" ]]"
  datacenters = [
    [[ if .datacenters ]]
      [[ range $index, $value := .datacenters ]]
        [[ if ne $index 0 ]], [[ end ]]"[[ $value ]]"
      [[ end ]]
    [[ else ]]
      "srnd"
    [[ end ]]
  ]

  ##########
  # Placement Options
  ##########

  [[ if .placement ]]
    [[ if eq .placement.type "all" ]]
      type = "system"
    [[ else if eq .placement.type "batch" ]]
      type = "batch"
    [[ else ]]
      type = "service"
      [[ if eq .placement.type "unique" ]]
        constraint {
          operator  = "distinct_hosts"
          value     = "true"
        }
      [[ end ]]
    [[ end ]]

    [[ if .placement.os_type ]]
      constraint {
        attribute = "${attr.kernel.name}"
        value = "[[ .placement.os_type ]]"
      }
    [[ end ]]

    [[ if .placement.os ]]
      constraint {
        attribute = "${attr.os.name}"
        value = "[[ .placement.os ]]"
      }
    [[ end ]]

    [[ if .placement.os_version ]]
      constraint {
        attribute = "${attr.os.version}"
        value = "[[ .placement.os_version ]]"
      }
    [[ end ]]
  [[ else ]]
    type = "service"
  [[ end ]]


  ##########
  # Deployment Options
  ##########

  update {
    max_parallel = [[ if .deployment ]][[ or .deployment.max_parallel 1 ]][[ else ]]1[[ end ]]
    min_healthy_time = "10s"
    healthy_deadline = [[ if .deployment ]]"[[ or .deployment.healthy_deadline "3m" ]]"[[ else ]]"3m"[[ end ]]
    progress_deadline = "10m"
    auto_revert = [[ if .deployment ]][[ if .deployment.no_revert_on_failure ]]false[[ else ]]true[[ end ]][[ else ]]true[[ end ]]
    canary = [[ if .deployment ]][[ or .deployment.canaries 0 ]][[ else ]]0[[ end ]]
    auto_promote = [[ if .deployment ]][[ if gt .deployment.canaries 0 ]]true[[ else ]]false[[ end ]][[ else ]]false[[ end ]]
  }


  group "[[ .job ]]" {
    count = [[ if .deployment ]][[ or .deployment.initial_count 1 ]][[ else ]]1[[ end ]]

    restart {
      attempts = [[ if .deployment ]][[ or .deployment.attempts 2 ]][[ else ]]2[[ end ]]
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    ##########
    # Volumes
    ##########

    [[ range $taskName, $task := .tasks ]]
        [[ if .volumes ]]
          [[ range $index, $config := .volumes.host ]]
            volume "[[ $taskName ]]-[[ .volume ]]" {
              type      = "host"
              source    = "[[ .volume ]]"
              read_only = false
            }
        [[ end ]]
      [[ end ]]
    [[ end ]]

    ##########
    # Tasks
    ##########

    [[ range $taskName, $task := .tasks ]]
      task "[[ $taskName ]]" {
        driver = "docker"

        config {
          dns_servers = [ "169.254.1.1" ]
          image = "[[ .image ]]:[[ or .version "latest" ]]"

          # Docker Ports
          port_map = {
            [[ range $name, $port := .ports ]]
              [[ $name ]] = [[ .inner ]]
            [[ end ]]
          }

          volumes = [
            [[ if .volumes ]]
              [[ range $index, $config := .volumes.share ]]
                [[ if ne $index 0 ]],[[ end ]] "/fileshare/[[ .fileshare ]]:[[ .mountpoint ]]"
              [[ end ]]
              [[ if .allow_docker_sock ]],[[ end ]]
            [[ end ]]
            [[ if .allow_docker_sock ]]
              "/var/run/docker.sock:/var/run/docker.sock"
            [[ end ]]
          ]
        }

        [[ if .volumes ]]
          [[ range $index, $config := .volumes.host ]]
            volume_mount {
              volume = "[[ $taskName ]]-[[ .volume ]]"
              mount = "[[ .mountpoint ]]"
              read_only = [[ if .read_only ]]true[[ else ]]false[[ end ]]
            }
          [[ end ]]
        [[ end ]]

        resources {
          # External Port Mapping
          network {
            [[ range $name, $port := .ports ]]
              port "[[ $name ]]" {
                [[ if .outer ]]
                  static = [[ .outer ]]
                [[ end ]]
              }
            [[ end ]]
          }
        }

        [[ if .vault ]]
          [[ if .vault.policies ]]
            vault {
              policies = [
                [[ range $index, $value := .vault.policies ]]
                  [[ if ne $index 0 ]], [[ end ]]"[[ $value ]]"
                [[ end ]]
              ]
              change_mode   = "signal"
              change_signal = "SIGHUP"
            }
          [[ end ]]

          # Secrets
          [[ if .vault.env ]]
            template {
              data = <<EOF
                [[ range $vaultKey, $vaultSecrets := .vault.env ]]
                  {{- with secret "kv/data/[[ $vaultKey ]]" -}}
                    [[ range $envKey, $secretKey := $vaultSecrets ]]
                      [[ $envKey ]]={{ .Data.data.[[ $secretKey ]] }}
                    [[ end ]]
                  {{ end }}
                [[ end ]]
              EOF
              destination = "local/secrets.env"
              env         = true
            }
          [[ end ]]
        [[ end ]]

        # Environment Variables
        [[ if .env ]]
          env {
            [[ range $envKey, $value := .env ]]
              [[ $envKey ]] = "[[ $value ]]"
            [[ end ]]
          }
        [[ end ]]

        [[ if .files ]]
          [[ range $file, $template := .files ]]
            template {
              destination = "[[ $file ]]"
              env = [[ if .env ]]true[[ else ]]false[[ end ]]
              data = <<EOF
[[ .data ]]
EOF
            }
          [[ end ]]
        [[ end ]]

        # Consul Service Registration
        [[ range $portName, $port := .ports ]]
          service {
            name = "[[ $portName ]]"
            port = "[[ $portName ]]"
            tags = [
              [[ if .lb ]]
                "traefik.enable=true",
                "traefik.http.routers.[[ $.job ]]-[[ $taskName ]]-[[ $portName ]].rule=Host(`[[ .lb.domain ]]`)",
                "traefik.http.routers.[[ $.job ]]-[[ $taskName ]]-[[ $portName ]]-tls.rule=Host(`[[ .lb.domain ]]`)",
                "traefik.http.routers.[[ $.job ]]-[[ $taskName ]]-[[ $portName ]]-tls.tls=true",
                "traefik.http.routers.[[ $.job ]]-[[ $taskName ]]-[[ $portName ]]-tls.tls.certresolver=[[ replace .lb.cert "." "-" ]]",
                "traefik.http.routers.[[ $.job ]]-[[ $taskName ]]-[[ $portName ]]-tls.tls.domains[0].main=*.[[ .lb.cert ]]",
                "traefik.http.routers.[[ $.job ]]-[[ $taskName ]]-[[ $portName ]]-tls.tls.domains[0].sans=[[ .lb.cert ]]",
                "traefik.http.services.[[ $.job ]]-[[ $taskName ]]-[[ $portName ]].loadbalancer.sticky=false",
              [[ end ]]
            ]
          }
        [[ end ]]
      }
    [[ end ]]
  }
}
