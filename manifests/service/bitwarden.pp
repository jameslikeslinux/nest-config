class nest::service::bitwarden (
  String $admin_token,
  String $database_password,
  String $smtp_password,
) {
  nest::lib::srv { 'bitwarden': }
  ->
  file { '/srv/bitwarden/data':
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }
  ->
  nest::lib::container { 'bitwarden':
    image   => 'vaultwarden/server',
    dns     => '172.22.4.2',
    env     => [
      'DOMAIN=https://vault.thesatelliteoflove.net',
      "ADMIN_TOKEN=${admin_token}",
      "DATABASE_URL=mysql://bitwarden:${database_password}@web.nest/bitwarden",
      'ENABLE_DB_WAL=false',
      'INVITATION_ORG_NAME=Bitwarden',
      'IP_HEADER=X-Forwarded-For',
      'SIGNUPS_ALLOWED=false',
      'SHOW_PASSWORD_HINT=false',
      'SMTP_HOST=smtp.gmail.com',
      'SMTP_FROM=bitwarden@thesatelliteoflove.net',
      'SMTP_FROM_NAME=Bitwarden',
      'SMTP_USERNAME=system@james.tl',
      "SMTP_PASSWORD=${smtp_password}",
      'WEBSOCKET_ENABLED=true',
    ],
    publish => ['8080:80', '3012:3012'],
    volumes => ['/srv/bitwarden/data:/data'],
  }
}
