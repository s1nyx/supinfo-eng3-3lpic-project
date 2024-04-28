class dns_config {
  file { '/etc/resolv.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "nameserver 192.168.236.147\nsearch localdomain.lan\n",
  }
}

class nginx_web {
  include nginx

  nginx::resource::server { 'my_node_app':
    ensure               => present,
    listen_port          => 80,
    use_default_location => false,
    locations            => {
      '/' => {
        proxy => 'http://127.0.0.1:9000',
      },
    },
  }

  file { '/etc/nginx/conf.d/default.conf':
    ensure => absent,
    notify => Service['nginx'],
  }
}

class git {
  package { 'git':
    ensure => installed,
  }
}

class node_app {
  include git

  $project_dir = '/var/www/my_node_app'
  $repo_url    = 'https://github.com/s1nyx/supinfo-eng3-3lpic-project.git'

  file { '/var/www':
    ensure => directory,
  }

  file { $project_dir:
    ensure  => directory,
    require => Package['git'],
  }

  exec { 'clean_project_dir':
    command => "/bin/rm -rf ${project_dir}",
    onlyif  => "/usr/bin/test -d ${project_dir}/.git",
    path    => ['/bin', '/usr/bin'],
    require => File[$project_dir],
    before  => Exec['clone_project'],
  }

  exec { 'clone_project':
    command => "/usr/bin/git clone ${repo_url} ${project_dir}",
    unless  => "/usr/bin/test -d ${project_dir}/.git",
    path    => ['/usr/bin', '/bin'],
    require => [Package['git'], File[$project_dir]],
    before  => Exec['install_node_dependencies'],
  }

  package { 'nodejs':
    ensure => installed,
  }

  package { 'npm':
    ensure  => installed,
    require => Package['nodejs'],
  }

  exec { 'install_node_dependencies':
    command => '/usr/bin/npm install',
    cwd     => "${project_dir}/website",
    require => Exec['clone_project'],
  }

  exec { 'run_node_app':
    command => '/usr/bin/nohup /usr/bin/npm start &',
    cwd     => "${project_dir}/website",
    require => Exec['install_node_dependencies'],
  }
}

class ha_tools {
  package { 'pacemaker':
    ensure => installed,
  }

  package { 'crmsh':
    ensure => installed,
  }

  package { 'corosync':
    ensure => installed,
  }

  file { '/etc/corosync/corosync.conf':
    ensure  => file,
    content => template('nginx/corosync-reverseproxy.conf.erb'),
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

  service { 'pacemaker':
    ensure  => running,
    enable  => true,
    require => Package['pacemaker'],
  }

  exec { 'crm_create_nginx_resource':
    command => '/usr/sbin/crm configure primitive nginx_service ocf:heartbeat:nginx',
    unless  => '/usr/sbin/crm configure show nginx_service',
    require => [Package['pacemaker'], Service['corosync']],
  }

  exec { 'crm_create_nginx_vip':
    command => '/usr/sbin/crm configure primitive nginx_vip ocf:heartbeat:IPaddr2 params ip="192.168.236.150" nic="ens160" cidr_netmask="24"',
    unless  => '/usr/sbin/crm configure show nginx_vip',
    require => [Package['pacemaker'], Service['corosync']],
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
}

node /^web\d+\.localdomain\.lan$/ {
  include dns_config
  include nginx_web
  include node_app
  include ha_tools
}