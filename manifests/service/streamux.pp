class nest::service::streamux (
  String $ssid,
  Sensitive $password,
) {
  include nest::service::bluetooth

  #
  # Firewall
  #
  firewalld_zone { 'streamux':
    ensure     => present,
    interfaces => 'wlan0',
    target     => 'default',
  }

  Firewalld_policy <| title == 'nat' |> {
    ingress_zones +> 'streamux',
  }

  Firewalld_port {
    zone => 'streamux',
  }

  Firewalld_service {
    zone => 'streamux',
  }

  #
  # Hostapd
  #
  package { 'net-wireless/hostapd':
    ensure => installed,
  }
  ->
  file { '/etc/hostapd/hostapd.conf':
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    content => epp('nest/streamux/hostapd.conf.epp'),
  }
  ~>
  service { 'hostapd':
    enable => true,
  }

  #
  # Dnsmasq
  #
  class { 'nest::service::dnsmasq':
    interfaces => ['wlan0'],
  }

  # Hand out IPs in order, but start over every reboot
  $dnsmasq_conf = @(DNSMASQ)
    dhcp-leasefile=/run/dnsmasq.leases
    dhcp-range=172.22.100.100,172.22.100.199,infinite
    dhcp-sequential-ip
    | DNSMASQ

  file { '/etc/dnsmasq.d/streamux.conf':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => $dnsmasq_conf,
    notify  => Service['dnsmasq'],
  }

  firewalld_service { ['dhcp', 'dns']:
    ensure => present,
  }

  #
  # Nginx
  #
  nest::lib::package { 'www-servers/nginx':
    ensure => installed,
    use    => 'rtmp',
  }

  firewalld_port {
    'rtmp':
      ensure   => present,
      port     => 1935,
      protocol => 'tcp',
    ;

    'hls':
      ensure   => present,
      port     => 8080,
      protocol => 'tcp',
      zone     => 'external',
    ;
  }

  #
  # Gstreamer
  #
  nest::lib::package { [
    'media-libs/gst-plugins-bad',
    'media-libs/gst-plugins-good',
    'media-plugins/gst-plugins-rtmp',
    'media-plugins/gst-plugins-v4l2codecs',
    'media-plugins/gst-plugins-x264',
  ]:
    ensure => installed,
  }

  #
  # GoPro
  #
  package { 'dev-python/pip':
    ensure => installed,
  }
  ->
  file { '/home/james/bin/pip':
    mode    => '0755',
    owner   => 'james',
    group   => 'users',
    content => "#!/bin/bash\nexec sudo -u james /usr/bin/pip \"$@\"\n",
  }
  ->
  package { 'open-gopro':
    provider        => pip,
    command         => '/home/james/bin/pip',
    install_options => ['--user'],
    source          => 'open-gopro @ git+https://gitlab.james.tl/james/open-gopro.git@main#subdirectory=demos/python/sdk_wireless_camera_control&',
  }

  #
  # Streamux
  #
  vcsrepo { '/home/james/streamux':
    ensure   => latest,
    provider => git,
    source   => 'https://gitlab.james.tl/james/streamux.git',
    revision => 'main',
    user     => 'james',
  }

  # For speedometer
  package { 'dev-python/urwid':
    ensure => installed,
  }

  # For access to /dev/video0 hardware acceleration
  User <| title == 'james' |> {
    groups +> 'video',
  }
}
