moduledir '.modules'

# Required by everything
mod 'puppetlabs-stdlib', '9.4.0'
mod 'puppetlabs-concat', '9.0.0'

# Core types and providers
mod 'puppetlabs-augeas_core', '1.4.1'
mod 'puppetlabs-chocolatey', '8.0.0'
mod 'puppetlabs-host_core', '1.2.0'
mod 'puppetlabs-sshkeys_core', '2.4.0'
mod 'puppetlabs-zfs_core', '1.4.0'

# Bolt modules
mod 'reboot', :git => 'git@gitlab.james.tl:nest/forks/puppet-reboot.git', :branch => 'main'

# My modules
mod 'nest', :git => 'git@gitlab.james.tl:nest/puppet.git', :branch => :control_branch, :default_branch => 'main'
mod 'private', :git => 'git@gitlab.james.tl:nest/private.git', :branch => 'main'

# Required by nest
mod 'puppet-dnsquery', '5.0.1'
mod 'puppet-augeasproviders_sysctl', '3.1.0'
mod 'puppetlabs-apache', '11.1.0'
mod 'puppetlabs-inifile', '6.1.0'
mod 'puppetlabs-mysql', '15.0.0'
mod 'puppetlabs-powershell', '6.0.0'
mod 'puppetlabs-vcsrepo', :git => 'git@gitlab.james.tl:nest/forks/puppet-vcsrepo.git', :branch => 'main'
mod 'puppet-firewalld', :git => 'git@gitlab.james.tl:nest/forks/puppet-firewalld.git', :branch => 'feature-policy-objects'
mod 'puppet-nodejs', '10.0.0'
mod 'puppet-python', :git => 'git@gitlab.james.tl:nest/forks/puppet-python.git', :branch => 'fix-gentoo-pip-install'
mod 'puppetlabs-windows_env', '5.0.0'
mod 'puppet-windows_firewall', '4.1.0'
mod 'theforeman-puppet', '18.0.0'
mod 'portage', :git => 'git@gitlab.james.tl:nest/forks/puppet-portage.git', :branch => 'main'

# Required by puppetlabs-chocolatey and puppet-windows_firewall
mod 'puppetlabs-registry', '5.0.1'

# Required by puppetlabs-powershell
mod 'puppetlabs-pwshlib', '1.0.0'

# Required by theforeman-puppet
mod 'puppet-extlib', '7.0.0'
mod 'puppet-systemd', '6.0.0'

# Required by augeasproviders_sysctl
mod 'puppet-augeasproviders_core', '4.0.1'
