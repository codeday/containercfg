class site::nomad {
  $nomad_version = "0.12.0"

  class { "site::host_volumes": }

  class { "docker":
    ensure => present,
  }

  cron { "docker prune nightly":
    command => "/usr/bin/docker image prune -a --force",
    user    => "root",
    hour    => 2,
    minute  => 0,
    require => Class["docker"],
  }

  file { "/root/.docker":
    ensure => directory,
    owner => "root",
    group => "root",
    mode => "0770",
  }

  file { "/root/.docker/config.json":
    ensure => file,
    content => template("site/docker-config.json.erb"),
    owner => "root",
    group => "root",
    mode => "0660",
    require => File["/root/.docker"],
  }

  archive { "nomad":
    ensure => present,
    extract => true,
    source => "https://releases.hashicorp.com/nomad/${nomad_version}/nomad_${nomad_version}_linux_${::architecture}.zip",
    path => "/tmp/nomad.zip",
    extract_path => "/usr/local/bin",
    creates => "/usr/local/bin/nomad",
    cleanup => true,
  }
  ~> file { "nomad":
    path => "/usr/local/bin/nomad",
    mode => "0775",
  }

  file { "/etc/nomad.d":
    ensure => directory,
    owner => "root",
    group => "root",
    mode => "0770",
  }

  file { "/etc/nomad.d/nomad.hcl":
    ensure => file,
    owner => "root",
    group => "root",
    mode => "0660",
    content => template("site/nomad.hcl.erb"),
    require => [ File["/etc/nomad.d"], Class["site::host_volumes"] ],
    notify => Service["nomad"],
  }

  file { "/acme":
    ensure => directory,
    owner => "root",
    group => "root",
    mode => "0770",
  }

  systemd::unit_file { 'nomad.service':
    source => "puppet:///modules/site/nomad.service",
  }
  ~> service { "nomad":
    ensure => running,
    enable => true,
    require => [ File["nomad"], File["/etc/nomad.d/nomad.hcl"], File["/acme"], Class["site::host_volumes"], Class["docker"] ],
    subscribe => File["/etc/nomad.d/nomad.hcl"],
  }
}
