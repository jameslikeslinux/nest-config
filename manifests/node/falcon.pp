class nest::node::falcon {
  include '::nest'

  nest::lib::srv { [
    'nzbget',
    'nzbget/downloads',
    'ombi',
    'plex',
    'radarr',
    'sonarr',
  ]: }

  file {
    default:
      ensure => directory,
      mode   => '0755',
      owner  => 'nzbget',
      group  => 'media',
    ;

    '/srv/nzbget':
      require => Nest::Lib::Srv['nzbget'],
    ;

    [
      '/srv/nzbget/config',
      '/srv/nzbget/downloads',
    ]:
      # use defaults
    ;

    '/srv/nzbget/downloads/completed':
      mode    => '0775',
    ;
  }

  file {
    default:
      ensure => directory,
      mode   => '0755',
      owner  => 'ombi',
      group  => 'media',
    ;

    '/srv/ombi':
      require => Nest::Lib::Srv['ombi'],
    ;

    '/srv/ombi/config':
      # use defaults
    ;
  }

  file {
    default:
      ensure => directory,
      mode   => '0755',
      owner  => 'plex',
      group  => 'media',
    ;

    '/srv/plex':
      require => Nest::Lib::Srv['plex'],
    ;

    '/srv/plex/config':
      # use defaults
    ;
  }

  file {
    default:
      ensure => directory,
      mode   => '0755',
      owner  => 'radarr',
      group  => 'media',
    ;

    '/srv/radarr':
      require => Nest::Lib::Srv['radarr'],
    ;

    '/srv/radarr/config':
      # use defaults
    ;
  }

  file {
    default:
      ensure => directory,
      mode   => '0755',
      owner  => 'sonarr',
      group  => 'media',
    ;

    '/srv/sonarr':
      require => Nest::Lib::Srv['sonarr'],
    ;

    '/srv/sonarr/config':
      # use defaults
    ;
  }

  $cpuset = $::nest::availcpus_expanded.join(',')
  $cpuset_param = "--cpuset-cpus ${cpuset}"

  Docker::Run {
    dns                               => '172.22.0.1',
    dns_search                        => 'nest',
    extra_parameters                  => $cpuset_param,

    # XXX: These should be added to site.pp after docker -> podman switch
    docker_service                    => false,
    restart_service_on_docker_refresh => false,
    service_provider                  => 'systemd',
  }

  nest::lib::podman_container { 'nzbget':
    image       => 'linuxserver/nzbget',
    cpuset_cpus => $cpuset,
    dns         => '172.22.0.1',
    dns_search  => 'nest',
    env         => ['PUID=6789', 'PGID=1001', 'TZ=America/New_York'],
    publish     => ['6789:6789'],
    volumes     => [
      '/srv/nzbget/config:/config',
      '/srv/nzbget/downloads:/downloads',
      '/nest/downloads/nzbget/watch:/downloads/nzb',
    ],
    require     => [
      File['/srv/nzbget/config'],
      File['/srv/nzbget/downloads'],
    ],
  }

  nest::lib::podman_container { 'ombi':
    image       => 'linuxserver/ombi',
    cpuset_cpus => $cpuset,
    dns         => '172.22.0.1',
    dns_search  => 'nest',
    env         => ['PUID=3579', 'PGID=1001', 'TZ=America/New_York'],
    publish     => ['3579:3579'],
    volumes     => ['/srv/ombi/config:/config'],
    require     => File['/srv/ombi'],
  }

  nest::lib::podman_container { 'plex':
    image            => 'plexinc/pms-docker',
    cpuset_cpus      => $cpuset,
    dns              => '172.22.0.1',
    dns_search       => 'nest',
    env              => ['PLEX_UID=32400', 'PLEX_GID=1001', 'TZ=America/New_York'],
    network          => 'host',
    tmpfs            => ['/transcode'],
    volumes          => [
      '/srv/plex/config:/config',
      '/nest/movies:/movies',
      '/nest/tv:/tv',
    ],
    require          => File['/srv/plex/config'],
  }

  docker::run { 'radarr':
    ensure => absent,
    image  => 'linuxserver/ombi',
  }
  ->
  nest::lib::podman_container { 'radarr':
    image       => 'linuxserver/radarr',
    cpuset_cpus => $cpuset,
    dns         => '172.22.0.1',
    dns_search  => 'nest',
    env         => ['PUID=7878', 'PGID=1001', 'TZ=America/New_York'],
    publish     => ['7878:7878'],
    volumes     => [
      '/srv/radarr/config:/config',
      '/srv/nzbget/downloads:/downloads',
      '/nest/movies:/movies',
    ],
    require     => [
      File['/srv/radarr/config'],
      File['/srv/nzbget/downloads/completed'],
    ],
  }

  docker::run { 'sonarr':
    ensure => absent,
    image  => 'linuxserver/ombi',
  }
  ->
  nest::lib::podman_container { 'sonarr':
    image       => 'linuxserver/sonarr',
    cpuset_cpus => $cpuset,
    dns         => '172.22.0.1',
    dns_search  => 'nest',
    env         => ['PUID=8989', 'PGID=1001', 'TZ=America/New_York'],
    publish     => ['8989:8989'],
    volumes     => [
      '/srv/sonarr/config:/config',
      '/srv/nzbget/downloads:/downloads',
      '/nest/tv:/tv',
    ],
    require     => [
      File['/srv/sonarr/config'],
      File['/srv/nzbget/downloads/completed'],
    ],
  }

  nest::lib::reverse_proxy {
    default:
      ssl => false,
      ip  => '172.22.0.1',
    ;

    'nzbget.nest':
      destination => 'localhost:6789',
    ;

    'ombi.nest':
      destination => 'localhost:3579',
    ;

    'plex.nest':
      destination => 'localhost:32400',
      websockets  => true,
    ;

    'radarr.nest':
      destination => 'localhost:7878',
    ;

    'sonarr.nest':
      destination => 'localhost:8989',
    ;
  }

  firewall { '012 multicast':
    proto   => udp,
    pkttype => 'multicast',
    action  => accept,
  }

  firewall { '100 podman to apache':
    iniface => 'cni-podman0',
    proto   => tcp,
    dport   => 80,
    state   => 'NEW',
    action  => accept,
  }

  firewall { '100 podman to dnsmasq':
    iniface => 'cni-podman0',
    proto   => udp,
    dport   => 53,
    state   => 'NEW',
    action  => accept,
  }

  firewall { '100 plex':
    proto  => tcp,
    dport  => 32400,
    state  => 'NEW',
    action => accept,
  }

  sysctl { 'fs.inotify.max_user_watches':
    value  => '1048576',
    target => '/etc/sysctl.d/nest.conf',
  }

  nest::service::gitlab_runner {
    default:
      host               => 'gitlab.james.tl',
      registration_token => $::nest::gitlab_runner_token,
    ;

    'gitlab.james.tl':
      # use defaults
    ;

    'gitlab.james.tl-podman':
      docker_volumes => ['/var/run/docker.sock:/run/podman/podman.sock'],
      tag_list       => ['podman'],
    ;
  }
}
