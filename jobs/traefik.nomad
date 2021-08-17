job "traefik" {
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

  constraint {
    attribute = "${meta.speed}"
    value     = "gbps"
  }

  group "traefik" {
    count = 1

    volume "acme" {
      type      = "host"
      read_only = false
      source    = "acme"
    }

    ephemeral_disk {
      migrate = true
      size    = "25"
      sticky  = true
    }

    task "traefik" {
      driver = "docker"

      logs {
        max_files     = 2
        max_file_size = 5
      }

      volume_mount {
        volume      = "acme"
        destination = "/acme"
        read_only   = false
      }

      config {
        image        = "traefik:2.1"
        network_mode = "host"
        dns_servers = ["169.254.1.1"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
          "local/providers.toml:/etc/traefik/providers.toml"
        ]
      }

      vault {
        policies = ["acme", "traefik"]
      }

      template {
        data = <<EOF
{{- with secret "kv/data/cloudflare" -}}
CF_DNS_API_TOKEN={{ .Data.data.dns_api_key }}
CLOUDFLARE_EMAIL={{ .Data.data.email }}
CLOUDFLARE_API_KEY={{ .Data.data.api_key }}
{{ end }}
{{- with secret "kv/data/ns1" -}}
NS1_API_KEY={{ .Data.data.api_key }}
{{ end }}
EOF
        destination = "local/file.env"
        env         = true
      }

      resources {
        cpu = 100
        memory = 128
        network {
          port "http" {
            static = 80
          }

          port "https" {
            static = 443
          }

          port "api" {
            static = 8080
          }
        }
      }

      service {
        name = "traefik"
        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
        tags = [
          "traefik.http.routers.http-catchall.rule=hostregexp(`{host:.+}`)",
          "traefik.http.routers.http-catchall.entrypoints=http",
          "traefik.http.routers.http-catchall.middlewares=redirect-to-https@consulcatalog",
          "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
        ]
      }

      template {
        data = <<EOF
          {{- with secret "kv/data/traefik" -}}
            [http.routers]
              [http.routers.nomad-ci-get]
                service = "nomad"
                middlewares = ["strip-nomad-ci-prefix"]
                rule = "Method(`GET`) && Host(`nomad-ci.codeday.cloud`) && Path(`/{{ .Data.data.nomad_ci_key_get }}/v1/job/{job:[a-zA-Z0-9\\-_]+}`)"
              [http.routers.nomad-ci-plan]
                service = "nomad"
                middlewares = ["strip-nomad-ci-prefix"]
                rule = "Method(`POST`) && Host(`nomad-ci.codeday.cloud`) && Path(`/{{ .Data.data.nomad_ci_key_get }}/v1/job/{job:[a-zA-Z0-9\\-_]+}/plan`)"
              [http.routers.nomad-ci-post]
                service = "nomad"
                middlewares = ["strip-nomad-ci-prefix"]
                rule = "Host(`nomad-ci.codeday.cloud`) && Path(`/{{ .Data.data.nomad_ci_key_post }}/v1/job/{job:[a-zA-Z0-9\\-_]+}{plan:(/plan)?}`)"
              [http.routers.nomad]
                service = "nomad"
                middlewares = ["internal-ip"]
                rule = "Host(`nomad.codeday.cloud`)"
              [http.routers.vault]
                service = "vault"
                middlewares = ["internal-ip"]
                rule = "Host(`vault-ui.codeday.cloud`)"
              [http.routers.consul]
                service = "consul"
                middlewares = ["internal-ip"]
                rule = "Host(`consul.codeday.cloud`)"

            [http.services]
              [[http.services.nomad.loadBalancer.servers]]
                url = "http://m.codeday.cloud:4646/"
              [[http.services.consul.loadBalancer.servers]]
                url = "http://m.codeday.cloud:8500/"
              [[http.services.vault.loadBalancer.servers]]
                url = "http://m.codeday.cloud:8200/"

            [http.middlewares]
              [http.middlewares.redirect-scheme.redirectScheme]
                scheme = "https"
              [http.middlewares.strip-nomad-ci-prefix.stripPrefix]
                prefixes = ["/{{ .Data.data.nomad_ci_key_get }}", "/{{ .Data.data.nomad_ci_key_post }}"]
              [http.middlewares.internal-ip.ipWhiteList]
                sourceRange = ["10.0.0.0/8", "157.245.248.45", "172.17.0.1/16", "100.64.0.0/10"]
              [http.middlewares.strip-headers.headers.customResponseHeaders]
                Server = "Apache Tomcat"
                X-Powered-By = "Code"
              [http.middlewares.cache-forever.headers.customResponseHeaders]
                Cache-Control = "public,max-age=31557600,immutable"
          {{ end }}
        EOF
        destination = "local/providers.toml"
      }

      template {
        data = <<EOF
          [providers.consulCatalog]
            exposedByDefault = false
            [providers.consulCatalog.endpoint]
              address = "m.srnd.cloud:8500"
              scheme = "http"
          [providers.file]
            filename = "/etc/traefik/providers.toml"

          [entryPoints]
            [entryPoints.http]
              address = ":80"
              [entryPoints.http.forwardedHeaders]
                trustedIPs = ["173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20", "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/12", "172.64.0.0/13", "131.0.72.0/22"]
            [entryPoints.https]
              address = ":443"

          [api]
            insecure = true
            dashboard = true

          [certificatesResolvers.srnd-org.acme]
            storage = "/acme/srnd-org.json"
            email = "team@srnd.org"
            [certificatesResolvers.srnd-org.acme.dnsChallenge]
              provider = "cloudflare"

          [certificatesresolvers.srnd-to.acme]
            storage = "/acme/srnd-to.json"
            email = "team@srnd.org"
            [certificatesresolvers.srnd-to.acme.dnschallenge]
              provider = "cloudflare"

          [certificatesResolvers.codeday-org.acme]
            storage = "/acme/codeday-org.json"
            email = "team@srnd.org"
            [certificatesResolvers.codeday-org.acme.dnsChallenge]
              provider = "ns1"

          [certificatesResolvers.srnd-cloud.acme]
            storage = "/acme/srnd-cloud.json"
            email = "team@srnd.org"
            [certificatesResolvers.srnd-cloud.acme.dnsChallenge]
              provider = "ns1"

          [certificatesResolvers.codeday-to.acme]
            storage = "/acme/codeday-to.json"
            email = "team@srnd.org"
            [certificatesResolvers.codeday-to.acme.dnsChallenge]
              provider = "ns1"

          [certificatesResolvers.codeday-cloud.acme]
            storage = "/acme/codeday-cloud.json"
            email = "team@srnd.org"
            [certificatesResolvers.codeday-cloud.acme.dnsChallenge]
              provider = "ns1"

          [certificatesResolvers.codeday-xyz.acme]
            storage = "/acme/codeday-xyz.json"
            email = "team@srnd.org"
            [certificatesResolvers.codeday-xyz.acme.dnsChallenge]
              provider = "ns1"

          [certificatesresolvers.codeday-vip.acme]
            storage = "/acme/codeday-vip.json"
            email = "team@srnd.org"
            [certificatesresolvers.codeday-vip.acme.dnschallenge]
              provider = "cloudflare"

          [certificatesResolvers.playcodecup-com.acme]
            storage = "/acme/playcodecup-com.json"
            email = "team@srnd.org"
            [certificatesResolvers.playcodecup-com.acme.dnsChallenge]
              provider = "ns1"

          [certificatesresolvers.codecupchallenge-com.acme]
            storage = "/acme/codecupchallenge-com.json"
            email = "team@srnd.org"
            [certificatesresolvers.codecupchallenge-com.acme.dnschallenge]
              provider = "ns1"

          [certificatesresolvers.codeday-sh.acme]
            storage = "/acme/codeday-sh.json"
            email = "team@srnd.org"
            [certificatesresolvers.codeday-sh.acme.dnschallenge]
              provider = "ns1"

          [certificatesresolvers.bigdatachallenge-org.acme]
            storage = "/acme/bigdatachallenge-org.json"
            email = "team@srnd.org"
            [certificatesresolvers.bigdatachallenge-org.acme.dnschallenge]
              provider = "ns1"
EOF

        destination = "local/traefik.toml"
      }
    }
  }
}
