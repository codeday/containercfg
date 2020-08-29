class site::host_volumes {
  file { "/data-disks":
    ensure => directory,
  }

  $::host_volumes.each |String $tag, String $block| {
    $partition = "${block}-part1"
    $mountpoint = "/data-disks/${tag}"

    exec { "partition-${block}":
      command => "echo 'type=83' | sudo sfdisk '${block}'; sleep 3",
      creates => $partition,
      provider => shell,
      notify => Exec["format-${partition}"],
    }
    exec { "format-${partition}":
      command => "/sbin/mkfs.ext4 ${partition}",
      unless => "/sbin/blkid -t TYPE=ext4 ${partition}",
      require => Exec["partition-${block}"]
    }

    fstab { "${partition}":
      source => $partition,
      dest => $mountpoint,
      type => "ext4",
      require => Exec["format-${partition}"],
      notify => Exec["/bin/mount ${mountpoint}"],
    }
    file { "${mountpoint}":
      ensure => directory,
      require => File["/data-disks"],
    }
    exec { "/bin/mount ${mountpoint}":
      require => [ Fstab[$partition], File["${mountpoint}"] ],
      refreshonly => true,
    }
  }

  $::custom_volumes.each |String $tag, String $dir| {
    file { "$dir":
      ensure => directory,
    }
  }
}
