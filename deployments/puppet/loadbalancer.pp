class nginx_load_balancer {
  package { 'nginx':
    ensure => installed,
  }

  package { ['pacemaker', 'crmsh']:
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

  exec { 'crm_create_nginx_resource':
    command => '/usr/sbin/crm configure primitive nginx_service ocf:heartbeat:nginx',
    unless  => '/usr/sbin/crm configure show nginx_service',
    require => [Package['pacemaker'], Exec['crm_disable_stonith']],
  }

  exec { 'crm_create_nginx_vip':
    command => '/usr/sbin/crm configure primitive nginx_vip ocf:heartbeat:IPaddr2 params ip="192.168.236.100" nic="ens160" cidr_netmask="24"',
    unless  => '/usr/sbin/crm configure show nginx_vip',
    require => [Package['pacemaker'], Exec['crm_disable_stonith']],
  }

  exec { 'crm_create_nginx_group':
    command => '/usr/sbin/crm configure group nginx_group nginx_vip nginx_service',
    unless  => '/usr/sbin/crm configure show nginx_group',
    require => [Exec['crm_create_nginx_resource'], Exec['crm_create_nginx_vip']],
  }

  exec { 'crm_disable_stonith':
    command => '/usr/sbin/crm configure property stonith-enabled=false',
    unless  => '/usr/sbin/crm configure show | grep "stonith-enabled=false"',
    require => Package['pacemaker'],
    before  => [
      Exec['crm_create_nginx_resource'],
      Exec['crm_create_nginx_vip'],
      Exec['crm_create_nginx_group'],
    ],
  }

  service { 'pacemaker':
    ensure  => running,
    enable  => true,
    require => Package['pacemaker'],
  }

  package { 'corosync':
    ensure => installed,
  }

  file { '/etc/corosync/corosync.conf':
    ensure  => file,
    content => template('nginx/corosync.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['corosync'],
    notify  => Service['corosync'],
  }

  service { 'corosync':
    ensure  => running,
    enable  => true,
    require => [
      Package['corosync'],
      File['/etc/corosync/corosync.conf'],
    ],
  }
}

node /^loadbalancer\d+\.localdomain\.lan$/ {
  include dns_config
  include nginx_load_balancer
}