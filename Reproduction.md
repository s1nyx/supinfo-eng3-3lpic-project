2 VM de Serveurs Web, 2 VMs de BDD


- J'ai créé une template debian 12
- J'ai setups les autres VMs avec cette template
- J'ai setup une VM qui sera le Master de Puppet sur du Debian 11 car sinon y'a des pbs de compatibilités
- J'ai installé puppetserver sur le Master

- Pour chaque VM, j'ai exécuté la commande pour recup l'ip : `sudo ip addr show`
  J'ai mit en place ces hosts dans /etc/hosts pour éviter les pbs de résolution de nom

```bash
192.168.236.136 puppetmaster puppetmaster.localdomain.lan puppet puppet.localdomain.lan
192.168.236.141 web1 web1.localdomain.lan
192.168.236.140 db1 db1.localdomain.lan
```

Il faut également leur définir un nouveau hostname avec la commande `sudo hostnamectl set-hostname web1.localdomain.lan` par exemple pour la VM web1 (faire de même pour les autres VMs)


- J'ai installé puppet-agent sur les autres VMs
```bash
sudo wget https://apt.puppet.com/puppet8-release-bullseye.deb
sudo dpkg -i puppet8-release-bullseye.deb
sudo apt update
sudo apt install puppet-agent -y

sudo ln -s /opt/puppetlabs/bin/puppet /usr/local/bin/puppet
sudo puppet ssl bootstrap
```


- Suivre https://www.puppet.com/docs/puppet/7/install_agents#installAnAgent pour installer l'agent puppet sur les VMs agents
- Il faut ensuite signer les certificats sur le master avec la commande `sudo puppetserver ca sign --all` (après `sudo puppet ssl boostrap`)
- Pour les agents, il faut modifier le fichier /etc/puppetlabs/puppet/puppet.conf pour ajouter le nom du master
```bash
[main]
server = puppet
```
IMPORTANT:
- Il faut installer le module apt pour utiliser le package manager apt (sur le Master) quand on va vouloir installer des packages comme nginx...
```bash
sudo puppet module install puppetlabs-apt
```
- Pour nginx: `sudo puppet module install puppet-nginx`
- Pour mongodb: `sudo puppet module install puppetlabs-mongodb`
- Pour git: `sudo puppet module install theforeman-git`
- Pour nodejs: `sudo puppet module install puppet-nodejs`
- Pour mysql: `sudo puppet module install puppetlabs-mysql --version 15.0.0`

Pour ajouter une configuration à un agent, il faut créer un fichier .pp dans /etc/puppetlabs/code/environments/production/manifests/ et ajouter la configuration voulue (exemple ici:)
```bash
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
```

Pour appliquer la configuration, il faut exécuter la commande `sudo puppet agent -t` sur l'agent