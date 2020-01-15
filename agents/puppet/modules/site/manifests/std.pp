class site::std {
  exec { "/usr/bin/apt-get update": }

  package { "zsh":
    ensure => latest,
    require => Exec["/usr/bin/apt-get update"],
  }

  package { ["zip", "unzip"]:
    ensure => latest,
  }
}
