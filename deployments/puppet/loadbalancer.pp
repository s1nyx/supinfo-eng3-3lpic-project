class nginx_load_balancer {
  package { 'nginx':
    ensure => installed,
  }

  # S'assurer que le répertoire pour les certificats existe
  $ssl_dir = '/etc/nginx/ssl'

  file { $ssl_dir:
    ensure => directory,
  }

  # Copier le certificat SSL
  file { '/etc/nginx/ssl/site.localdomain.lan.crt':
    ensure  => file,
    source  => 'puppet:///modules/nginx/site.localdomain.lan.crt',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/nginx/ssl'],
  }

  # Copier la clé privée
  file { '/etc/nginx/ssl/site.localdomain.lan.key':
    ensure  => file,
    source  => 'puppet:///modules/nginx/site.localdomain.lan.key',
    owner   => 'root',
    group   => 'root',
    mode    => '0600', # Important pour que la clé soit en lecture seule par root
    require => File['/etc/nginx/ssl'],
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