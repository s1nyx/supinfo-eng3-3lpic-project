node 'web1.localdomain.lan', 'web2.localdomain.lan' {
  include nginx

  nginx::resource::server { 'my_node_app':
    ensure       => present,
    listen_port  => 80,
    use_default_location => false,
    locations    => {
      '/' => {
        proxy => 'http://127.0.0.1:9000', # Remplacer par le port de votre application Node.js
      },
    },
  }

  # Assurez-vous que le fichier de configuration par défaut de Nginx est supprimé
  file { '/etc/nginx/conf.d/default.conf':
    ensure => absent,
    notify => Service['nginx'], # Ceci notifiera le service Nginx qu'un redémarrage est nécessaire
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

  exec { 'install_node_dependencies':
    command => "/usr/bin/npm install",
    cwd     => "${project_dir}/website",
    require => Exec['clone_project'],
  }

  exec { 'run_node_app':
    command => "/usr/bin/nohup /usr/bin/npm start &",
    cwd     => "${project_dir}/website",
    require => Exec['install_node_dependencies'],
  }
}

