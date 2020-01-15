class site::nomad {
  $nomad_version = "0.10.2"

  class { 'docker':
    ensure => present,
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
    require => File["/etc/nomad.d"],
  }

  systemd::unit_file { 'nomad.service':
    source => "puppet:///modules/site/nomad.service",
  }
  ~> service { "nomad":
    ensure => running,
    enable => true,
    require => [ File["nomad"], File["/etc/nomad.d/nomad.hcl"], Class["docker"] ],
    subscribe => File["/etc/nomad.d/nomad.hcl"],
  }
}
