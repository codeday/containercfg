job "subspace" {
    region      = "global"
    datacenters = ["srnd"]
    type        = "service"

    update {
        max_parallel = 1
        min_healthy_time = "10s"
        healthy_deadline = "3m"
        progress_deadline = "10m"
        auto_revert = true
        canary = 0
    }

    group "subspace-group" {
        count = 1

        volume "wg-data" {
            type      = "host"
            read_only = false
            source    = "wg-data"
        }

        volume "subspace-data" {
            type      = "host"
            read_only = false
            source    = "subspace-data"
        }

        restart {
            attempts = 2
            interval = "5m"
            delay = "15s"
            mode = "fail"
        }

        task "subspace-web-ui" {
            driver = "docker"

            template {
            data = <<EOH
                SUBSPACE_HTTP_HOST="subspace.srnd.org"
            EOH

            destination = "secrets/.env"
            env = true
            }

            config {
                image = "subspacecloud/subspace:latest"

                port_map {
                    http = 80
                }

                dns_servers = ["169.254.1.1"]
                
                logging {
                type = "journald"
                    config {
                        tag = "subspace_docker"
                    }
                }
            }

            service {
                name = "link-shortener"
                port = "http"
                // TODO: How does this work?
                # tags = [
                #     "traefik.enable=true",
                #     "traefik.http.routers.link-shortener-yourls-http.rule=Host(`srnd.to`)",
                #     "traefik.http.routers.link-shortener-yourls.rule=Host(`srnd.to`)",
                #     "traefik.http.routers.link-shortener-yourls.tls=true",
                #     "traefik.http.routers.link-shortener-yourls.tls.certresolver=srnd-to",
                #     "traefik.http.routers.link-shortener-yourls.tls.domains[0].main=*.srnd.to",
                #     "traefik.http.routers.link-shortener-yourls.tls.domains[0].sans=srnd.to",
                #     "traefik.http.services.link-shortener-yourls.loadbalancer.sticky=true",

                #     "traefik.tags=service",
                #     "traefik.frontend.rule=Host:srnd.to"
                # ]
            }

            network {
                port "http" {}
            }

            volume_mount {
                volume      = "wg-data"
                destination = "/usr/bin/wg"
                read_only   = false
            }
            volume_mount {
                volume      = "subspace-data"
                destination = "/data"
                read_only   = false
            }
        }
    }
}