class site::std {
  exec { "/usr/bin/apt-get update": }

  exec { "apt-key tailscale":
    command => "curl https://pkgs.tailscale.com/stable/${os['name'].downcase}/${os['distro']['codename']}.gpg | apt-key add -",
    path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    unless => "apt-key list | grep Tailscale",
  }

  file { "tailscale.list":
    path => "/etc/apt/sources.list.d/tailscale.list",
    source => "https://pkgs.tailscale.com/stable/${::os['name'].downcase}/${::os['distro']['codename']}.list",
    require => Exec['apt-key tailscale'],
    notify => Exec['/usr/bin/apt-get update'],
  }

  package { "tailscale":
    ensure => latest,
    require => File["tailscale.list"],
  }

  service { "tailscaled":
    ensure => "running",
    enable => true,
    require => Package["tailscale"],
  }

  exec { "tailscale up":
    command => "tailscale up -authkey ${::vault['tailscale_key']} -advertise-routes ${::private_interface['ip']}/32 --accept-dns=false",
    path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    unless => "ip addr | grep tailscale | grep inet",
    require => Service["tailscaled"],
  }

  class { "sudo": }
  sudo::conf { 'sudo':
    priority => 10,
    content  => '%sudo ALL=(ALL) NOPASSWD: ALL',
  }

  service { "puppet":
    ensure => stopped,
    enable => false,
  }

  package { "zsh":
    ensure => latest,
    require => Exec["/usr/bin/apt-get update"],
  }

  package { ["zip", "unzip"]:
    ensure => latest,
  }


  class { "datadog_agent":
      api_key => $::vault['dd_license_key'],
  }
}
