node 'db1.localdomain.lan' {
  class { '::mysql::server':
    root_password           => 'strong_root_password',
    override_options        => {
      'mysqld' => {
        'server-id'               => '1',
        'log_bin'                 => 'mysql-bin',
        'binlog_do_db'            => 'your_database_name',
        'expire_logs_days'        => '10',
        'max_binlog_size'         => '100M',
        'bind-address'            => '0.0.0.0',
      }
    },
    restart                 => true,
  }

  mysql::db { 'your_database_name':
    user     => 'replication_user',
    password => 'strong_replication_password',
    host     => '%',
  }

  exec { 'grant-replication-privilege':
    command => "/usr/bin/mysql --defaults-extra-file=/root/.my.cnf -e \"GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%'\"",
    require => Class['::mysql::server'],
  }

  package { 'corosync':
    ensure => installed,
  }

  package { ['pacemaker', 'crmsh']:
    ensure => installed,
  }

  file { '/etc/corosync/corosync.conf':
    ensure  => file,
    content => template('mysql/corosync.conf.erb'),
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

  exec { 'crm_create_mysql_resource':
    command => '/usr/sbin/crm configure primitive mysql ocf:heartbeat:mysql params config="/etc/mysql/my.cnf" binary="/usr/bin/mysqld_safe" socket="/var/run/mysqld/mysqld.sock" datadir="/var/lib/mysql" pid="/var/run/mysqld/mysqld.pid"',
    unless  => '/usr/sbin/crm configure show mysql',
    require => Package['pacemaker'],
  }

  exec { 'crm_create_mysql_vip':
    command => '/usr/sbin/crm configure primitive mysql_vip ocf:heartbeat:IPaddr2 params ip="192.168.236.200" nic="ens160" cidr_netmask="24"',
    unless  => '/usr/sbin/crm configure show mysql_vip',
    require => Package['pacemaker'],
  }

  exec { 'crm_create_mysql_group':
    command => '/usr/sbin/crm configure group mysql_group mysql_vip mysql',
    unless  => '/usr/sbin/crm configure show mysql_group',
    require => [Exec['crm_create_mysql_resource'], Exec['crm_create_mysql_vip']],
  }

  exec { 'crm_disable_stonith':
    command => '/usr/sbin/crm configure property stonith-enabled=false',
    unless  => '/usr/sbin/crm configure show | grep "stonith-enabled=false"',
    require => Package['pacemaker'],
    before  => [
      Exec['crm_create_mysql_resource'],
      Exec['crm_create_mysql_vip'],
      Exec['crm_create_mysql_group'],
    ],
  }

  service { 'pacemaker':
    ensure  => running,
    enable  => true,
    require => Package['pacemaker'],
  }
}

node /^db[2-9]\.localdomain\.lan$/ {
  $node_number = regsubst($trusted['certname'], '^db(\d+)\.localdomain\.lan$', '\1')

  class { '::mysql::server':
    root_password    => 'strong_root_password',
    override_options => {
      'mysqld' => {
        'relay-log'               => 'mysql-relay-bin',
        'log_bin'                 => 'mysql-bin',
        'binlog_do_db'            => 'your_database_name',
        'read_only'               => '1',
        'bind-address'            => '0.0.0.0',
        'server-id' => $node_number,
      }
    },
    restart          => true,
  }

  mysql::db { 'your_database_name':
    user     => 'replication_user',
    password => 'strong_replication_password',
    host     => '%',
    grant    => ['SELECT', 'EXECUTE', 'SHOW VIEW'],
  }

  exec { 'grant-replication-privilege':
    command => "/usr/bin/mysql --defaults-extra-file=/root/.my.cnf -e \"GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%'\"",
    require => Class['::mysql::server'],
  }

  exec { 'grant-replication-admin-privilege':
    command => "/usr/bin/mysql --defaults-extra-file=/root/.my.cnf -e \"GRANT REPLICATION SLAVE ADMIN ON *.* TO 'replication_user'@'%' IDENTIFIED BY 'strong_replication_password'; FLUSH PRIVILEGES;\"",
    require => Class['::mysql::server'],
    before  => Exec['mysql_change_master'],
  }

  exec { 'mysql_change_master':
    command => "/usr/bin/mysql -u replication_user --password=strong_replication_password -e \"CHANGE MASTER TO MASTER_HOST='db1.localdomain.lan', MASTER_USER='replication_user', MASTER_PASSWORD='strong_replication_password', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=  107;\"",
    require => Class['::mysql::server'],
    unless  => "/usr/bin/mysql -u replication_user --password=strong_replication_password -e 'SHOW SLAVE STATUS\\G' | grep 'Slave_IO_Running: Yes'",
  }

  exec { 'mysql_start_slave':
    command => "/usr/bin/mysql -u replication_user --password=strong_replication_password -e 'START SLAVE;'",
    require => Exec['mysql_change_master'],
    unless  => "/usr/bin/mysql -u replication_user --password=strong_replication_password -e 'SHOW SLAVE STATUS\\G' | grep 'Slave_IO_Running: Yes'",
  }

  package { 'corosync':
    ensure => installed,
  }

  package { ['pacemaker', 'crmsh']:
    ensure => installed,
  }

  file { '/etc/corosync/corosync.conf':
    ensure  => file,
    content => template('mysql/corosync.conf.erb'),
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
}