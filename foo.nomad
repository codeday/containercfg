job "logspout" {
  region      = "global"
  datacenters = [
    
    "srnd"
    
  ]

  ##########
  # Placement Options
  ##########

  
    type = "service"
  


  ##########
  # Deployment Options
  ##########

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = true
    canary = 0
    auto_promote = false
  }


  group "logspout" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    ##########
    # Volumes
    ##########

    
        
    

    ##########
    # Tasks
    ##########

    
      task "logspout" {
        driver = "docker"

        config {
          dns_servers = [ "169.254.1.1" ]
          image = "gliderlabs/logspout:latest"
          command = "syslog://splunk-syslog.service.consul:8514"
          userns_mode = "host"

          # Docker Ports
          port_map = {
            
              status = 8980
            
          }

          volumes = [
            
            
              "/var/run/docker.sock:/var/run/docker.sock"
            
          ]

          
        }

        

        resources {
          cpu = 100
          memory = 128

          # External Port Mapping
          network {
            
              port "status" {
                
              }
            
          }
        }

        

        # Environment Variables
        
          env {
            
              PORT = "8980"
            
          }
        

        

        # Consul Service Registration
        
          service {
            name = "logspout-status"
            port = "status"
            tags = [
              
            ]
          }
        
      }
    
  }
}
