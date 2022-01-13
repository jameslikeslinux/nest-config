class nest::role::workstation::cursor {
  file {
    default:
      ensure    => directory,
      mode      => '0644',
      owner     => 'root',
      group     => 'root',
      recurse   => true,
      purge     => true,
      backup    => false,
      show_diff => false;

    '/usr/share/icons/breeze_cursors':
      source => 'puppet:///modules/nest/cursors/Breeze';

    '/usr/share/icons/Breeze_Snow':
      source => 'puppet:///modules/nest/cursors/Breeze_Snow';
  }

  file {
    default:
      mode  => '0644',
      owner => 'root',
      group => 'root';

    '/etc/X11/Xresources':
      content => "Xcursor.size: ${::nest::cursor_size}\n";

    # Prevent Plasma from changing these settings
    '/usr/share/kservices5/mouse.desktop':
      ensure => absent,
  }

  file_line { 'sddm-load-xresources':
    path => '/usr/share/sddm/scripts/Xsetup',
    line => 'xrdb -merge /etc/X11/Xresources',
  }
}
