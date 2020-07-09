class site::std {
  exec { "apt-get update":
    command => "/usr/bin/apt-get update",
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
    require => Exec["apt-get update"],
  }

  package { ["zip", "unzip"]:
    ensure => latest,
  }


  class { "datadog_agent":
      api_key => $::vault['dd_license_key'],
  }
}
