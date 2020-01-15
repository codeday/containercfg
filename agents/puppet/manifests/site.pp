include site::std

if $::role == 'nomad-agent' {
  include site::consul
  include site::nomad
}
