class cups (
    $system_group = 'wheel',
    $kde          = false,
    $browse       = [],
) {
    portage::package { [
        'net-print/cups-filters',
        'net-print/cups',
        'net-print/foomatic-db',
    ]:
        ensure => installed,
    }

    file { '/etc/cups/cupsd.conf':
        mode    => '0640',
        owner   => 'root',
        group   => 'lp',
        source  => 'puppet:///modules/cups/cupsd.conf',
        require => Portage::Package['net-print/cups'],
        notify  => Openrc::Service['cupsd'],
    }

    file { '/etc/cups/cups-files.conf':
        mode    => '0640',
        owner   => 'root',
        group   => 'lp',
        content => template('cups/cups-files.conf.erb'),
        require => Portage::Package['net-print/cups'],
        notify  => Openrc::Service['cupsd'],
    }

    file { '/etc/cups/cups-browsed.conf':
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => template('cups/cups-browsed.conf.erb'),
        require => Portage::Package['net-print/cups-filters'],
        notify  => Openrc::Service['cups-browsed'],
    }

    openrc::service { 'cupsd':
        enable  => true,
        require => File['/etc/cups/cups-files.conf'],
    }

    openrc::service { 'cups-browsed':
        enable  => true,
        require => File['/etc/cups/cups-browsed.conf'],
    }

    if $kde {
        #
        # 'kde-base/print-manager' pulls in 'app-admin/system-config-printer-gnome'
        # which as of 07/30/2014 seems to require gtk and friends to use introspection
        #
        package_use { [
            'dev-libs/atk',
            'x11-libs/gtk+',
            'x11-libs/libnotify',
            'x11-libs/pango',
            'x11-libs/gdk-pixbuf',
        ]:
            use    => 'introspection',
            before => Portage::Package['kde-base/print-manager'],
        }

        portage::package { 'kde-base/print-manager':
            ensure => installed,
        }
    }
}
