# mysql_replication.pp

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

  # Définition de la base de données sans spécifier les privilèges ici
  mysql::db { 'your_database_name':
    user     => 'replication_user',
    password => 'strong_replication_password',
    host     => '%',
  }

  # Commande exec pour accorder le privilège REPLICATION SLAVE au niveau global
  exec { 'grant-replication-privilege':
    command => "/usr/bin/mysql --defaults-extra-file=/root/.my.cnf -e \"GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%'\"",
    require => Class['::mysql::server'],
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

  # Définition de la base de données pour les nœuds esclaves
  mysql::db { 'your_database_name':
    user     => 'replication_user',
    password => 'strong_replication_password',
    host     => '%',
    grant    => ['SELECT', 'EXECUTE', 'SHOW VIEW'], # Privilèges spécifiques pour l'usage des esclaves
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
}
