class kernel::initrd (
    $kernel_name,
    $kernel_version,
) {
    $initrd = "/boot/initramfs-${kernel_name}-${kernel::arch}-${kernel_version}"

    exec { 'remove-old-initrd':
        command     => "/bin/rm -f ${initrd}",
        refreshonly => true,
    }

    exec { "dracut":
        command     => "/usr/bin/dracut --force --hostonly --no-hostonly-cmdline --add crypt ${initrd} ${kernel_version}",
        require     => [Class['dracut'], Class['kernel'], Exec['remove-old-initrd']],
        creates     => $initrd,
        timeout     => 0,
    }
}
