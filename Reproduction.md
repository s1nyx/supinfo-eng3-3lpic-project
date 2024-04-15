2 VM de Serveurs Web, 2 VMs de BDD


- J'ai créé une template debian 11 
- J'ai setups les autres VMs avec cette template
- J'ai setup une VM qui sera le Master de Puppet sur du Debian 11 car sinon y'a des pbs de compatibilités
- J'ai installé puppetserver sur le Master

- Pour chaque VM, j'ai exécuté la commande pour recup l'ip : `sudo ip addr show`
  J'ai mit en place ces hosts dans /etc/hosts pour éviter les pbs de résolution de nom

```bash
192.168.236.136 puppetmaster puppetmaster.localdomain.lan puppet puppet.localdomain.lan
192.168.236.142 web1 web1.localdomain.lan
192.168.236.143 web2 web2.localdomain.lan
192.168.236.140 db1 db1.localdomain.lan
192.168.236.144 db2 db2.localdomain.lan
192.168.236.146 loadbalancer1 loadbalancer1.localdomain.lan
192.168.236.145 loadbalancer2 loadbalancer2.localdomain.lan
192.168.236.139 dns.localdomain.lan
```

IP Virtuel Cluster Loadbalancer: 192.168.236.100
IP Virtual Cluster MySQL: 192.168.236.200

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
- Sur le Master, il faut générer le certificat SSL pour site.localdomain.lan afin qu'il puisse être copié par puppet
- Il faut installer le module apt pour utiliser le package manager apt (sur le Master) quand on va vouloir installer des packages comme nginx...
```bash
sudo puppet module install puppetlabs-apt
```
- Pour nginx: `sudo puppet module install puppet-nginx`
- Pour mongodb: `sudo puppet module install puppetlabs-mongodb`
- Pour git: `sudo puppet module install theforeman-git`
- Pour nodejs: `sudo puppet module install puppet-nodejs`
- Pour mysql: `sudo puppet module install puppetlabs-mysql --version 15.0.0`

Pour ajouter une configuration à un agent, il faut créer un fichier .pp dans /etc/puppetlabs/code/environments/production/manifests/ et ajouter la configuration voulue 
Pour ajouter une template à un agent, il faut créer un fichier .erb dans /etc/puppetlabs/code/environments/production/modules/nginx/templates/nginx.conf.erb et ajouter la template voulue (exemple avec nginx)

Mettre files/site.localdomain.lan.zone dans /etc/puppetlabs/code/environments/production/modules/bind/files/site.localdomain.lan.zone
Mettre templates/nginx/nginx.conf.erb dans /etc/puppetlabs/code/environments/production/modules/nginx/templates/nginx.conf.erb
Mettre templates/nginx/corosync.conf.erb dans /etc/puppetlabs/code/environments/production/modules/nginx/templates/corosync.conf.erb
Mettre templates/mysql/corosync.conf.erb dans /etc/puppetlabs/code/environments/production/modules/mysql/templates/corosync.conf.erb

Pour appliquer la configuration, il faut exécuter la commande `sudo puppet agent -t` sur l'agent

Si le MySQL Slave,
```bash
mysql -u root -p 

STOP SLAVE;
RESET SLAVE;
START SLAVE;

SHOW SLAVE STATUS\G
```

Penser à ajouter l'ip du serveur DNS sur sa machine hôte en premier pour qu'elle soit prioritaire dans la résolution de nom



# Corosync

Pour vérifier qu'il fonctionne et bascule automatiquement sur le serveur actif en cas de panne:
Executer `sudo crm status` pour voir les ressources actives
Executer `sudo systemctl stop corosync pacemaker` sur le serveur avec les resource group "Started"
