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

        volume "splunk-db" {
            type = "host"
            read_only = false
            source = "splunk-db"
        }

        volume "splunk-etc" {
            type = "host"
            read_only = false
            source = "splunk-etc"
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
                    collector = 8088
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
                SPLUNK_PASSWORD={{ .Data.data.ADMIN_PASSWORD }}
                {{ end }}
                EOH

                destination = "secrets/.env"
                env = true
            }

            template {
                data = <<EOH
                {{- with secret "kv/data/splunk" -}}
                {{- .Data.data.LICENSE -}}
                {{ end }}
                EOH

                destination = "/opt/splunk/Splunk.License"
                change_mode   = "restart"
            }

            service {
                name = "splunk"
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

            service {
                name = "splunk-collector"
                port = "collector"
                tags = [
                    "traefik.enable=true",
                    "traefik.http.routers.splunk-splunk-collector-http.rule=Host(`splunk-collect.srnd.org`)",
                    "traefik.http.routers.splunk-splunk-collector.rule=Host(`splunk-collect.srnd.org`)",
                    "traefik.http.routers.splunk-splunk-collector.tls=true",
                    "traefik.http.routers.splunk-splunk-collector.tls.certresolver=srnd-org",
                    "traefik.http.routers.splunk-splunk-collector.tls.domains[0].main=*.srnd.org",
                    "traefik.http.routers.splunk-splunk-collector.tls.domains[0].sans=srnd.org",
                    "traefik.http.services.splunk-splunk-collector.loadbalancer.sticky=false",

                    "traefik.tags=service",
                    "traefik.frontend.rule=Host:splunk-collect.srnd.org"
                ]
            }

            resources {
                cpu = 800
                memory = 700

                network {
                    port "http" {}
                    port "collector" {}
                }
            }

            volume_mount {
                volume      = "splunk-db"
                destination = "/opt/splunk/var"
                read_only   = false
            }

            volume_mount {
                volume      = "splunk-etc"
                destination = "/opt/splunk/etc"
                read_only   = false
            }
        }
    }
}
