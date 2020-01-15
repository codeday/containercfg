include site::std

if $::role == 'nomad-agent' {
  include site::fs
  include site::consul
  include site::nomad
}
