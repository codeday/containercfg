class site::fs {
  package { "cifs-utils":
    ensure => latest,
    require => Exec["/usr/bin/apt-get update"],
  }

  file { "/etc/smbcredentials/nomadfs.cred":
    ensure => file,
    content => "username=$::vault_fs_username\npassword=$::vault_fs_password",
    owner => "root",
    group => "root",
    mode => "0600",
  }

  file { "/etc/fileshare":
    ensure => directory,
  }

  fstab { "nomadfs":
    source => "$::vault_fs_url",
    dest => "/fileshare",
    type => "cifs",
    opts => "nofail,vers=3.0,credentials=/etc/smbcredentials/nomadfs.cred,dir_mode=0777,file_mode=0777,serverino",
    require => [
      Package["cifs-utils"],
      File["/etc/fileshare"],
      File["/etc/smbcredentials/nomadfs.cred"]
    ],
    notify => Exec["/bin/mount /fileshare"],
  }

  exec { "/bin/mount /fileshare":
    require => Fstab["nomadfs"],
  }
}
