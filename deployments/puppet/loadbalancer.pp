class nginx_load_balancer {
  package { 'nginx':
    ensure => installed,
  }

  $ssl_dir = '/etc/nginx/ssl'
  $cert_file = "${ssl_dir}/site.localdomain.lan.crt"
  $key_file = "${ssl_dir}/site.localdomain.lan.key"

  # S'assurer que le répertoire pour les certificats existe
  file { $ssl_dir:
    ensure => directory,
  }

  # Générer un certificat auto-signé
  exec { 'generate_ssl_certificate':
    command => "/usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${key_file} -out ${cert_file} -subj '/CN=site.localdomain.lan/O=My Company Name/C=FR'",
    path    => ['/usr/bin', '/bin'],
    creates => $cert_file,
    require => File[$ssl_dir],
  }

  file { '/etc/nginx/nginx.conf':
    ensure  => file,
    content => template('nginx/nginx.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }

  service { 'nginx':
    ensure    => running,
    enable    => true,
    require   => Package['nginx'],
    subscribe => File['/etc/nginx/nginx.conf'],
  }
}

node /^loadbalancer\d+\.localdomain\.lan$/ {
  include nginx_load_balancer
}