class nest::networking {
    #
    # Uses DHCPCD to manage network interface (unless I'm a desktop)
    #
#    unless desktop in $nest::roles {
#        openrc::service { 'dhcpcd':
#            enable => true,
#        }
#    }


    #
    # Is a VPN client (if it's not also a server)
    #
    unless vpn_server in $nest::roles {
        class { 'openvpn::client':
            server      => 'vpn.thestaticvoid.com',
            ca_cert     => "${settings::ssldir}/certs/ca.pem",
            client_cert => "${settings::ssldir}/certs/${clientcert}.pem",
            client_key  => "${settings::ssldir}/private_keys/${clientcert}.pem",
        }
    }


    #
    # Has a hostname
    #
    class { 'hostname':
        hostname => "${clientcert}.vpn",
    }


    #
    # and knows about everyone else's...
    #
    class { 'openvpn::hosts': }


    #
    # Is firewalled.
    #
    class { 'iptables': }

    iptables::accept { 'vpn-old':
        device => 'tap0',
    }

    iptables::accept { 'vpn':
        device => 'tun0',
    }


    #
    # Uses NFS
    #
    class { 'nfs': }
    class { 'nfs::idmapd':
        domain => 'thestaticvoid.com',
    }


    unless nest_server in $nest::roles {
        class { 'nest::role::nest_client': }
    }


    portage::package { 'net-misc/iperf':
        ensure    => installed,
        use       => 'threads',
        mask_slot => '3',
    }

    portage::package { 'net-analyzer/traceroute':
        ensure => installed,
    }
}
