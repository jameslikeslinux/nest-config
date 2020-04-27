class nest::role::workstation::firefox {
  case $facts['osfamily'] {
    'Gentoo': {
      nest::lib::portage::package_use { 'www-client/firefox':
        use => 'hwaccel',
      }

      package { 'www-client/firefox':
        ensure => installed,
      }

      file { '/usr/lib64/firefox/defaults/pref/all-nest.js':
        ensure => absent,
      }

      $scaling_prefs = "pref(\"layout.css.devPixelsPerPx\", \"${::nest::gui_scaling_factor}\");"
      $scaling_prefs_quoted = shellquote($scaling_prefs)
      $scaling_prefs_echo_cmd = shellquote("echo ${scaling_prefs_quoted} > /usr/lib64/firefox/defaults/pref/all-scaling.js")

      $webrender = $::nest::video_card ? {
        'intel'  => 1,
        'nvidia' => 1,
        default  => 0,
      }

      $xdg_session_type = '$XDG_SESSION_TYPE'
      $firefox_wrapper_content = @("EOT")
        #!/bin/bash

        if [[ $xdg_session_type == 'x11' ]]; then
            sudo sh -c $scaling_prefs_echo_cmd
            export GTK_USE_PORTAL=1 MOZ_USE_XINPUT2=1
        else
            sudo rm -f /usr/lib64/firefox/defaults/pref/all-scaling.js
            export MOZ_ENABLE_WAYLAND=1
        fi

        MOZ_WEBRENDER=${webrender} MOZ_DBUS_REMOTE=1 exec /usr/lib64/firefox/firefox "$@"
        | EOT

      file { '/usr/bin/firefox':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => $firefox_wrapper_content,
        require => Package['www-client/firefox'],
      }
    }

    'windows': {
      package { 'firefox':
        ensure => installed,
      }

      file {
        default:
          owner => 'james',
        ;

        'C:/Users/james/AppData/Roaming/Mozilla':
          ensure => directory,
        ;

        'C:/Users/james/AppData/Roaming/Mozilla/Firefox':
          ensure => link,
          target => 'C:/tools/cygwin/home/james/.mozilla/firefox',
        ;
      }
    }
  }
}
