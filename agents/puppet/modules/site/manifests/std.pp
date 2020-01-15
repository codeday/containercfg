class site::std {
  exec { "/usr/bin/apt-get update": }

  class { "sudo": }
  sudo::conf { 'sudo':
    priority => 10,
    content  => '%sudo ALL=(ALL) NOPASSWD: ALL',
  }

  package { "zsh":
    ensure => latest,
    require => Exec["/usr/bin/apt-get update"],
  }

  package { ["zip", "unzip"]:
    ensure => latest,
  }
}
