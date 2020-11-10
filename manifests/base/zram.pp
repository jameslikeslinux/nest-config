class nest::base::zram {
  $zram_disksize = $facts['memory']['system']['total_bytes'] * 3 / 1024 / 1024

  file { '/etc/modules-load.d/zram.conf':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => "zram\n",
  }

  file { '/etc/udev/rules.d/10-zram.rules':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => "KERNEL==\"zram0\", ATTR{comp_algorithm}=\"zstd\", ATTR{disksize}=\"${zram_disksize}M\", RUN+=\"/sbin/mkswap /dev/zram0\"\n",
  }

  # initramfs not really the place to initialize zram
  file { '/etc/dracut.conf.d/10-zram.conf':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => "omit_drivers+=\" zram \"\n",
    require =>  Class['nest::base::dracut'],
    notify  =>  Class['nest::base::bootloader'],
  }

  # Move pages to zram more opportunistically
  sysctl { 'vm.swappiness':
    value  => '100',
    target => '/etc/sysctl.d/zram.conf',
  }
}
