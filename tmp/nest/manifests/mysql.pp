class nest::mysql {
  class { '::mysql::server':
    service_name     => 'mysqld',
    service_provider => 'systemd',
  }

  unless str2bool("$::chroot") {
    exec { 'mysql-tmpfiles-create':
      command => '/usr/bin/systemd-tmpfiles --create /usr/lib/tmpfiles.d/mysql.conf',
      creates => '/run/mysqld',
      require => Class['::mysql::server::install'],
      before  => Class['::mysql::server::service'],
    }
  }
}
