define nest::lib::wordpress (
  String                 $database_password,
  String                 $servername,
  Hash[String, Any]      $extra_vhost_params = {},
  Optional[Nest::IPList] $ip                 = undef,
  Optional[String]       $priority           = undef,
  Array[String]          $serveraliases      = [],
  Boolean                $ssl                = true,
) {
  include 'nest::service::apache'
  include 'nest::service::mysql'
  include 'nest::service::php'
  include 'apache::mod::proxy'
  include 'apache::mod::rewrite'
  ensure_resource('apache::mod', 'proxy_fcgi', { 'package' => 'www-servers/apache' })

  unless $facts['is_container'] {
    mysql::db { $name:
      user     => $name,
      password => $database_password,
    }
  }

  # See: https://wiki.apache.org/httpd/PHP-FPM#Proxy_via_handler
  $php_fpm_config = @(EOT)
    <Proxy "fcgi://127.0.0.1:9000/">
        ProxySet timeout=600
      </Proxy>

      <FilesMatch "\.php$">
        <If "-f %{REQUEST_FILENAME}">
          SetHandler "proxy:fcgi://127.0.0.1:9000/"
        </If>
      </FilesMatch>
    | EOT

  $vhost_params = {
    'custom_fragment' => $php_fpm_config,
    'directories'     => [
      {
        'path'     => "/srv/www/${servername}",
        'options'  => ['Indexes', 'FollowSymLinks', 'MultiViews'],
        'rewrites' => [
          { 'rewrite_rule' => ['.* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]'] },
          { 'rewrite_base' => '/' },
          { 'rewrite_rule' => ['^index\.php$ - [L]'] },
          {
            'rewrite_cond' => [
              '%{REQUEST_FILENAME} !-f',
              '%{REQUEST_FILENAME} !-d',
            ],
            'rewrite_rule' => ['. /index.php [L]'],
          },
        ],
      },
    ],
  }

  nest::lib::virtual_host { $name:
    priority      => $priority,
    servername    => $servername,
    serveraliases => $serveraliases,
    ip            => $ip,
    ssl           => $ssl,
    extra_params  => $vhost_params + $extra_vhost_params,
    zfs_docroot   => true,
  }
}
