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
    require => Exec["/usr/bin/apt-get update"],
  }

  package { ["zip", "unzip"]:
    ensure => latest,
  }

  package { "apt-transport-https":
    ensure => latest,
  }

  $dd_key = "A2923DFF56EDA6E76E55E492D3A80E30382E94DE"
  exec { "apt-key datadog":
    command => "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key ${dd_key}",
    unless  => "apt-key list | grep '${dd_key}' | grep -v expired",
  }

  file { "apt-repo datadog":
    path    => "/etc/apt/sources.list.d/datadog.list",
    ensure  => "file",
    content => "deb https://apt.datadoghq.com/ stable 7",
    notify  => Exec["apt-get update"],
    require => Exec["apt-key datadog"],
  }

  package { "datadog-agent":
    ensure => latest,
    require => File["apt-repo datadog"],
  }
}
