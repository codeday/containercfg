class site::fs {
  $fs_url = $::vault['fs_url']
  $username = $::vault['fs_username']
  $password = $::vault['fs_password']

  package { "cifs-utils":
    ensure => latest,
    require => Exec["/usr/bin/apt-get update"],
  }

  file { "/etc/smbcredentials":
    ensure => directory,
    owner => "root",
    group => "root",
    mode => "0600",
  }

  file { "/etc/smbcredentials/nomadfs.cred":
    ensure => file,
    content => "username=${username}\npassword=${password}",
    owner => "root",
    group => "root",
    mode => "0600",
    require => File["/etc/smbcredentials"],
  }

  file { "/fileshare":
    ensure => directory,
  }

  fstab { "nomadfs":
    source => $fs_url,
    dest => "/fileshare",
    type => "cifs",
    opts => "nofail,vers=3.0,credentials=/etc/smbcredentials/nomadfs.cred,dir_mode=0777,file_mode=0777,serverino",
    require => [
      Package["cifs-utils"],
      File["/fileshare"],
      File["/etc/smbcredentials/nomadfs.cred"]
    ],
    notify => Exec["/bin/mount /fileshare"],
  }

  exec { "/bin/mount /fileshare":
    require => Fstab["nomadfs"],
    refreshonly => true,
  }
}
