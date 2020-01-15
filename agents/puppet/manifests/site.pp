include site::std
class { "site::fs": }
class { "site::users":
  require => Class["site::fs"],
}

if $::role == 'nomad-agent' {
  class { "site::nomad":
    require => Class["site::users"],
  }
  include site::consul
}
