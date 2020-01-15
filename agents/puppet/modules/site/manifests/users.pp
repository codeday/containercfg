class site::users {
  class { "site::fs": }

  file { "/fileshare/_home":
    ensure => directory,
  }

  $::vault_ssh_users.each |String $username, String $ssh_key| {
    $home_dir = "/fileshare/_home/${username}"

    group { "${username}":
      ensure => present,
    }

    user { "${username}":
      ensure => present,
      home => $home_dir,
      shell => "/usr/bin/zsh",
      gid => $username,
      groups => "sudo",
      require => Group[$username],
    }

    file { ["${home_dir}", "${home_dir}/.ssh"]:
      ensure => directory,
      owner => $username,
      group => $username,
      mode => "0770",
      require => [ User[$username], Group[$username], Class["site::fs"], File["/fileshare/_home"] ],
    }

    file { "${home_dir}/.ssh/authorized_keys":
      ensure => present,
      content => $ssh_key,
      owner => $username,
      group => $username,
      mode => "0770",
      require => [ User[$username], Group[$username], File["${home_dir}/.ssh"] ],
    }
  }
}
