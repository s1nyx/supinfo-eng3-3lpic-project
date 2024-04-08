node 'web1.localdomain.lan', 'web2.localdomain.lan' {
  include nginx

  $ssl_dir = '/etc/nginx/ssl'
  $cert_file = "${ssl_dir}/web1.localdomain.lan.crt"
  $key_file = "${ssl_dir}/web1.localdomain.lan.key"

  # S'assurer que le répertoire pour les certificats existe
  file { $ssl_dir:
    ensure => directory,
  }

  # Générer un certificat auto-signé
  exec { 'generate_ssl_certificate':
    command => "/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${key_file} -out ${cert_file} -subj '/CN=web1.localdomain.lan/O=My Company Name/C=FR'",
    path    => ['/usr/bin', '/bin'],
    creates => $cert_file,
    require => File[$ssl_dir],
  }

  nginx::resource::server { 'my_node_app':
    ensure       => present,
    listen_port  => 443,
    ssl          => true,
    ssl_cert     => '/etc/nginx/ssl/web1.localdomain.lan.crt',
    ssl_key      => '/etc/nginx/ssl/web1.localdomain.lan.key',
    use_default_location => false,
    locations    => {
      '/' => {
        proxy => 'http://127.0.0.1:3000', # Remplacer par le port de votre application Node.js
      },
    },
  }

  # Pour la redirection HTTP vers HTTPS
  nginx::resource::server { 'redirect_to_https':
    ensure      => present,
    listen_port => 80,
    server_name => ['web1.localdomain.lan', 'web2.localdomain.lan'],
    rewrite_rules => [ '^ https://$host$request_uri? permanent' ],
  }

  package { 'git':
    ensure => installed,
  }

  file { '/var/www':
    ensure => directory,
  }

  # Répertoire où le projet sera cloné
  $project_dir = '/var/www/my_node_app'
  $repo_url = 'https://github.com/s1nyx/supinfo-eng3-3lpic-project.git'

  # S'assurer que le répertoire du projet existe
  file { $project_dir:
    ensure => directory,
    require => Package['git'],
  }

  # Cloner le projet depuis le dépôt Git
  exec { 'clean_project_dir':
    command     => "/bin/rm -rf ${project_dir}",
    onlyif      => "/usr/bin/test -d ${project_dir}/.git",
    path        => ['/bin', '/usr/bin'],
    require     => File[$project_dir],
    before      => Exec['clone_project'],
  }

  exec { 'clone_project':
    command     => "/usr/bin/git clone ${repo_url} ${project_dir}",
    unless      => "/usr/bin/test -d ${project_dir}/.git",
    path        => ['/usr/bin', '/bin'],
    require     => [Package['git'], File[$project_dir]],
    before      => Exec['install_node_dependencies'],
  }

  package { 'nodejs':
    ensure => installed,
  }

  package { 'npm':
    ensure  => installed,
    require => Package['nodejs'],
  }

  # Installer PM2 globalement
  exec { 'install_pm2':
    command => '/usr/bin/npm install pm2@latest -g',
  }

  exec { 'install_node_dependencies':
    command => "/usr/bin/npm install",
    cwd     => "${project_dir}/website",
    require => Exec['clone_project'],
  }

  exec { 'run_node_app':
    command => "/usr/local/bin/pm2 start ${project_dir}/website/app.js --name 'my_node_app'",
    cwd     => "${project_dir}/website",
    require => Exec['install_node_dependencies'],
    unless  => "/usr/local/bin/pm2 list | grep 'my_node_app'",
  }
}