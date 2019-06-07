class nest::bitwarden (
  Hash[String[1], String[1]] $env = {},
) {
  include '::nest'
  include '::nest::docker'

  package { 'app-emulation/docker-compose':
    ensure  => installed,
    require => Class['::nest::docker'],
  }

  nest::srv { 'bitwarden': }

  # A hack to include my manually-created ext4 volume for MSSQL in /etc/fstab
  Augeas <| title == 'fstab' |> {
    changes +> [
      "set 99/spec LABEL=bitwarden-mssql",
      'set 99/file /srv/bitwarden/bwdata/mssql/data',
      'set 99/vfstype ext4',
      'set 99/opt[1] defaults',
      'set 99/opt[2] discard',
      'set 99/opt[3] x-systemd.requires',
      'set 99/opt[3]/value zfs-mount.service',
      'set 99/dump 0',
      'set 99/passno 0',
    ]
  }

  file { '/srv/bitwarden':
    ensure  => directory,
    mode    => '0750',
    owner   => 'bitwarden',
    group   => 'bitwarden',
    require => Nest::Srv['bitwarden'],
  }

  vcsrepo { '/srv/bitwarden/core':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/bitwarden/core.git',
    revision => 'master',
    user     => 'bitwarden',
    require  => File['/srv/bitwarden'],
  }

  file { '/srv/bitwarden/bitwarden.sh':
    ensure  => symlink,
    target  => 'core/scripts/bitwarden.sh',
    owner   => 'bitwarden',
    group   => 'bitwarden',
    require => Vcsrepo['/srv/bitwarden/core'],
  }

  if $facts['bitwarden_installed'] {
    $env.each |$key, $value| {
      $key_escaped = regexpescape($key)

      file_line { "bitwarden-env-${key}":
        path   => '/srv/bitwarden/bwdata/env/global.override.env',
        line   => "${key}=${value}",
        match  => "^${key_escaped}=",
        notify => Exec['restart-bitwarden'],
      }
    }

    exec { 'restart-bitwarden':
      command     => '/srv/bitwarden/bitwarden.sh restart',
      user        => 'bitwarden',
      refreshonly => true,
    }
  }
}
