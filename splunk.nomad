job "splunk" {
    region = "global"
    datacenters = ["srnd"]
    type = "service"

    vault {
        policies = ["splunk"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
    }

    update {
        max_parallel = 1
        min_healthy_time = "10s"
        healthy_deadline = "3m"
        progress_deadline = "10m"
        auto_revert = true
        canary = 0
    }

    group "splunk-group" {
        count = 1

        volume "splunk_data" {
            type = "host"
            read_only = false
            source = "splunk_data"
        }

        volume "ingest" {
            type = "host"
            read_only = false
            source = "splunk_ingest"
        }

        restart {
            attempts = 2
            interval = "5m"
            delay = "15s"
            mode = "fail"
        }

        task "splunk" {
            driver = "docker"

            config {
                image = "splunk/splunk:latest"

                port_map {
                    http = 8000
                }

                dns_servers = ["169.254.1.1"]
                
                logging {
                type = "journald"
                    config {
                        tag = "splunk_docker"
                    }
                }
            }

            template {
                data = <<EOH
                {{- with secret "kv/data/splunk" -}}
                SPLUNK_START_ARGS=--accept-license
                SPLUNK_PASSWORD={{ .Data.data.SPLUNK_PASSWORD }}
                {{ end }}
                EOH

                destination = "secrets/.env"
                env = true 
            }

            service {
                name = "spunk"
                port = "http"
                tags = [
                    "traefik.enable=true",
                    "traefik.http.routers.splunk-splunk-server-http.rule=Host(`splunk.srnd.org`)",
                    "traefik.http.routers.splunk-splunk-server.rule=Host(`splunk.srnd.org`)",
                    "traefik.http.routers.splunk-splunk-server.tls=true",
                    "traefik.http.routers.splunk-splunk-server.tls.certresolver=srnd-org",
                    "traefik.http.routers.splunk-splunk-server.tls.domains[0].main=*.srnd.org",
                    "traefik.http.routers.splunk-splunk-server.tls.domains[0].sans=srnd.org",
                    "traefik.http.services.splunk-splunk-server.loadbalancer.sticky=true",

                    "traefik.tags=service",
                    "traefik.frontend.rule=Host:splunk.srnd.org"
                ]
            }

            resources {
                cpu = 500
                memory = 512

                network {
                    port "http" {}
                }
            }

            volume_mount {
                volume      = "splunk_data"
                destination = "/opt/splunk/etc"
                read_only   = false
            }
            volume_mount {
                volume      = "splunk_data"
                destination = "/opt/splunk/var"
                read_only   = false
            }
            volume_mount {
                volume      = "ingest"
                destination = "/ingest"
                read_only   = false
            }
        }
    }
}
