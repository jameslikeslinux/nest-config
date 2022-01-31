class nest::base::systemd {
  # This exists to ensure other resources that expect to write into this
  # directory come after systemd is installed, which is guaranteed when
  # this class is evaluated because it comes after the portage configuration.
  # Complicated, I know, but it leads to cleaner code overall (without
  # dependencies on the systemd class everywhere).
  file { '/etc/systemd':
    ensure  => directory,
  }

  unless $facts['build'] {
    file { '/etc/hostname':
      content => "${::trusted['certname']}\n",
    }
  }

  # Remove container hostnames that break systemd-resolved
  if $facts['build'] == 'stage3' {
    file_line { 'etc-hosts-container-entries':
      ensure            => absent,
      path              => '/etc/hosts',
      match             => '^10\.88\.',
      match_for_absence => true,
      multiple          => true,
    }
  }

  # /etc/localtime is just a regular file in the Gentoo stage tarballs.  In
  # that case, remove it and allow it to be set by the File['/etc/localtime']
  # resource; otherwise, this lets me set the timezone manually when I travel
  # without Puppet resetting it back.
  exec { '/bin/rm -f /etc/localtime':
    unless => '/usr/bin/test -L /etc/localtime',
    before => File['/etc/localtime'],
  }

  file { '/etc/localtime':
    ensure  => link,
    target  => '/usr/share/zoneinfo/America/New_York',
    replace => false,
  }

  $nsswitch_changes = [
    'rm database[. = "hosts"]/*',
    'set database[. = "hosts"]/service[1] files',
    'set database[. = "hosts"]/service[2] resolve',
    'set database[. = "hosts"]/reaction/status UNAVAIL',
    'touch database[. = "hosts"]/reaction/status/negate',
    'set database[. = "hosts"]/reaction/status/action return',
    'set database[. = "hosts"]/service[3] dns',
    'set database[. = "hosts"]/service[4] myhostname',

    'rm database[. = "group"]/*',
    'set database[. = "group"]/service[1] files',
    'set database[. = "group"]/reaction/status SUCCESS',
    'set database[. = "group"]/reaction/status/action merge',
    'set database[. = "group"]/service[2] systemd',

    'rm database[. = "passwd"]/*',
    'set database[. = "passwd"]/service[1] files',
    'set database[. = "passwd"]/service[2] systemd',

    'rm database[. = "shadow"]/*',
    'set database[. = "shadow"]/service[1] files',
  ]

  augeas { 'nsswitch':
    context => '/files/etc/nsswitch.conf',
    changes => $nsswitch_changes,
  }

  unless $facts['is_container'] {
    file { '/etc/resolv.conf':
      ensure => link,
      target => '/run/systemd/resolve/stub-resolv.conf',
    }
  }

  file {
    default:
      mode  => '0644',
      owner => 'root',
      group => 'root',
    ;

    '/etc/dnssec-trust-anchors.d':
      ensure => directory,
    ;

    '/etc/dnssec-trust-anchors.d/local.negative':
      source => 'puppet:///modules/nest/systemd/dnssec-trust-anchors-local.negative',
      notify => Service['systemd-resolved'],
    ;
  }

  service { 'systemd-resolved':
    enable => true,
  }

  file { '/etc/issue':
    content => "\nThis is \\n (\\s \\m \\r) \\t\n\n",
  }

  if $::nest::isolate_smt {
    $allowed_cpus = "0-${facts['processorcount'] / 2 - 1}"

    file {
      default:
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        notify => Nest::Lib::Systemd_reload['systemd'],
      ;

      [
        '/etc/systemd/system/init.scope.d',
        '/etc/systemd/system/machine.slice.d',
        '/etc/systemd/system/system.slice.d',
        '/etc/systemd/system/user.slice.d',
      ]:
        ensure => directory,
      ;

      '/etc/systemd/system/init.scope.d/10-allowed-cpus.conf':
        content => "[Scope]\nAllowedCPUs=${allowed_cpus}\n",
      ;

      [
        '/etc/systemd/system/machine.slice.d/10-allowed-cpus.conf',
        '/etc/systemd/system/system.slice.d/10-allowed-cpus.conf',
        '/etc/systemd/system/user.slice.d/10-allowed-cpus.conf',
      ]:
        content => "[Slice]\nAllowedCPUs=${allowed_cpus}\n",
      ;
    }
  } else {
    file { [
      '/etc/systemd/system/init.scope.d',
      '/etc/systemd/system/machine.slice.d',
      '/etc/systemd/system/system.slice.d',
      '/etc/systemd/system/user.slice.d',
    ]:
      ensure => absent,
      force  => true,
      notify => Nest::Lib::Systemd_reload['systemd'],
    }
  }

  $suspend_state = $facts['profile']['platform'] ? {
    'pinebookpro' => 'SuspendState=freeze',   # TF-A doesn't support deep sleep yet
    default       => '#SuspendState=mem standby freeze',
  }

  file_line {
    default:
      notify => Nest::Lib::Systemd_reload['systemd'],
    ;

    # Kill all user processes at end of session.
    # This is the default in systemd-230.
    'logind.conf-KillUserProcesses':
      path  => '/etc/systemd/logind.conf',
      line  => 'KillUserProcesses=yes',
      match => '^#?KillUserProcesses=',
    ;

    # There's no real swap on which to hibernate
    'sleep.conf-DisallowHibernation':
      path  => '/etc/systemd/sleep.conf',
      line  => 'AllowHibernation=no',
      match => '^#?AllowHibernation=',
    ;

    'sleep.conf-SuspendState':
      path  => '/etc/systemd/sleep.conf',
      line  => $suspend_state,
      match => '^#?SuspendState',
    ;
  }

  nest::lib::systemd_reload { 'systemd': }

  # Keep james's systemd services (like tmux) running
  file {
    default:
      owner => 'root',
      group => 'root',
      mode  => '0644',
    ;

    '/var/lib/systemd/linger':
      ensure => directory,
    ;

    '/var/lib/systemd/linger/james':
      ensure => file,
    ;
  }
}
