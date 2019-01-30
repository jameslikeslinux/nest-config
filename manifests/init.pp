class nest (
  $nestfs_hostname,
  $openvpn_hostname,

  $nullmailer_config,
  $root_mail_alias,
  $ssh_private_key,
  $pw_hash,
  $lastfm_pw_hash      = undef,

  $cnames              = {},
  $distcc_hosts        = {},
  $extra_luks_disks    = {},
  $kernel_config       = {},
  $kernel_cmdline      = '',

  $dvorak              = false,
  $swap_alt_win        = false,
  $monitor_layout      = [],
  $mouse               = undef,
  $primary_monitor     = undef,
  $processorcount      = $::processorcount,
  $gui_scaling_factor  = 1.0,
  $text_scaling_factor = 1.0,
  $barrier_config      = undef,
  $video_card          = undef,

  $live                = $::nest['live'],
  $vm                  = ($::virtual == 'kvm'),

  $cflags              = $::portage_cflags,
  $cpu_flags_x86       = $::portage_cpu_flags_x86,
  $package_keywords    = {},
  $package_mask        = {},
  $package_use         = {},
  $use                 = [],

  $cups_servers        = [],
  $distcc_server       = false,
  $fileserver          = false,
  $libvirt             = false,
  $openvpn_server      = false,
  $puppet_server       = false,

  Optional[Pattern[/(\d+(-\d+)?)(,\d+(-\d+)?)*/]] $isolcpus = undef,
) {
  if $::nest['profile'] == 'workstation' {
    $gentoo_profile = 'default/linux/amd64/17.0/desktop/plasma/systemd'
    $input_devices  = 'libinput'
    $video_cards    = 'i965 intel nvidia'
    $use_defaults   = ['pulseaudio', 'vaapi', 'vdpau']
  } else {
    $gentoo_profile = 'default/linux/amd64/17.0/systemd'
    $input_devices  = undef
    $video_cards    = undef
    $use_defaults   = ['X']
  }

  $kernel_config_hiera = hiera_hash('nest::kernel_config', $kernel_config)
  $cups_servers_hiera = hiera_array('nest::cups_servers', $cups_servers)
  $package_keywords_hiera = hiera_hash('nest::package_keywords', $package_keywords)
  $package_mask_hiera = hiera_hash('nest::package_mask', $package_mask)
  $package_use_hiera = hiera_hash('nest::package_use', $package_use)
  $use_hiera = hiera_array('nest::use', $use)
  $use_combined = union($use_defaults, $use_hiera).sort

  $dpi = 0 + inline_template('<%= (@text_scaling_factor * 96.0).round %>')
  $gui_scaling_factor_rounded = 0 + inline_template('<%= @gui_scaling_factor.round %>')
  $text_scaling_factor_percent_of_gui = 0.0 + inline_template('<%= (@dpi / (@gui_scaling_factor * 96.0)).round(3) %>')
  $text_scaling_factor_percent_of_rounded_gui = 0.0 + inline_template('<%= (@dpi / (@gui_scaling_factor_rounded * 96.0)).round(3) %>')

  $console_font_sizes        = [14, 16, 18, 20, 22, 24, 28, 32]
  $console_font_size_ideal   = 16 * $::nest::text_scaling_factor
  $console_font_size_smaller = inline_template('<%= @console_font_sizes.reverse.find(16) { |size| size - @console_font_size_ideal.round <= 0 } %>')
  $console_font_size         = $console_font_size_smaller

  $cursor_sizes        = [24, 32, 36, 40, 48, 64, 96]
  $cursor_size_ideal   = 24 * $::nest::gui_scaling_factor
  $cursor_size_smaller = inline_template('<%= @cursor_sizes.reverse.find(24) { |size| size - @cursor_size_ideal.round <= 0 } %>')
  $cursor_size         = $cursor_size_smaller

  $luks_disks = $::partitions.reduce({}) |$memo, $value| {
    $partition  = $value[0]
    $attributes = $value[1]
    if $attributes['filesystem'] == 'crypto_LUKS' and "${::trusted['certname']}-" in $attributes['partlabel'] {
      merge($memo, { $attributes['partlabel'] => $attributes['uuid'] })
    } else {
      $memo
    }
  }.merge($extra_luks_disks)

  if $isolcpus {
    $isolcpus_expanded = $isolcpus.split(',').map |$cpuset| {
      if $cpuset =~ /-/ {
        $cpuset_split = $cpuset.split('-')
        range($cpuset_split[0], $cpuset_split[1])
      } else {
        $cpuset
      }
    }.flatten
  } else {
    $isolcpus_expanded = []
  }

  $availcpus_expanded = range(0, $facts['processors']['count'] - 1) - $isolcpus_expanded

  # Include standard profile
  contain '::nest::profile::base'

  if $::nest['profile'] == 'workstation' {
    contain '::nest::profile::workstation'
  }
}
