class site::consul {
  $consul_version = "1.8.0"

  archive { "consul":
    ensure => present,
    extract => true,
    source => "https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_${::architecture}.zip",
    path => "/tmp/consul.zip",
    extract_path => "/usr/local/bin",
    creates => "/usr/local/bin/consul",
    cleanup => true,
  }
  ~> file { "consul":
    mode => "0775",
    path => "/usr/local/bin/consul",
  }

  group { "consul":
    ensure => present,
  }

  user { "consul":
    ensure => present,
    gid => "consul",
    home => "/etc/consul.d",
    shell => "/bin/false",
    require => Group["consul"],
  }

  file { "/opt/consul":
    ensure => directory,
    owner => "consul",
    group => "consul",
    mode => "0770",
  }

  file { "/etc/consul.d":
    ensure => directory,
    owner => "consul",
    group => "consul",
    mode => "0770",
    require => [ User["consul"], Group["consul"] ],
  }

  file { "/etc/consul.d/consul.hcl":
    ensure => file,
    owner => "consul",
    group => "consul",
    mode => "0660",
    content => template("site/consul.hcl.erb"),
    require => [ File["/etc/consul.d"], User["consul"], Group["consul"] ],
  }

  systemd::unit_file { 'consul.service':
    content => template('site/consul.service.erb'),
    require => [ File["consul"], File["/etc/consul.d/consul.hcl"], File["/opt/consul"] ],
  }
  ~> service { "consul":
    ensure => running,
    enable => true,
    subscribe => File["/etc/consul.d/consul.hcl"],
  }

  # Network Interface
  file { "/etc/systemd/network/dummy0.netdev":
    ensure => file,
    content => file('site/dummy0.netdev'),
    notify => Exec["dummy0-restart-networking"],
  }
  file { "/etc/systemd/network/dummy0.network":
    ensure => file,
    content => file('site/dummy0.network'),
    notify => Exec["dummy0-restart-networking"],
  }
  exec { "dummy0-restart-networking":
    command => "/bin/systemctl restart systemd-networkd",
    refreshonly => true,
  }

  # DNS Masq
  package { "dnsmasq":
    ensure => latest,
    require => [ Exec["/usr/bin/apt-get update"], File["/etc/systemd/network/dummy0.network"], File["/etc/systemd/network/dummy0.netdev"] ],
  }

  service { 'dnsmasq':
    ensure => running,
    enable => true,
    require => Package["dnsmasq"],
  }

  file { "/etc/dnsmasq.d":
    ensure => directory,
    require => Package["dnsmasq"],
  }

  file { "/etc/dnsmasq.d/consul.conf":
    ensure => file,
    content => file("site/consul.conf"),
    notify => Service["dnsmasq"],
  }
}
