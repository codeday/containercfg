job "statsd" {
    type = "system"
    datacenters = ["srnd"]
    region = "global"

    update {
        max_parallel = 1
        min_healthy_time = "10s"
        healthy_deadline = "3m"
        progress_deadline = "10m"
        auto_revert = true
        canary = 0
    }

    group "statsd-group" {
        count = 1

        restart {
            attempts = 2
            interval = "5m"
            delay = "15s"
            mode = "fail"
        }

        task "statsd-task" {
            driver = "docker"

            config {
                image = "statsd/statsd:latest"

                port_map {
                    statsd = 8125
                }

                dns_servers = ["169.254.1.1"]

                logging {
                    type = "journald"
                        config {
                            tag = "statsd_docker"
                        }
                }
            }

            resources {
                network {
                    port "statsd" {
                        static = 8125
                    }
                }
            }

            service {
                name = "statsd"
                port = "statsd"
            }
        }
    }
}
