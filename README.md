# Introduction
Coursero vise à mettre en place un système d'évaluation automatique de code pour les exercices des étudiants. 
Ce système permet d'assigner automatiquement une note à un code soumis par un étudiant pour un exercice spécifique.

# Architecture du Projet
https://app.eraser.io/workspace/2rNhCBxY4HGygX4Wp8wa

# Composants Principaux
- Serveurs Web: Deux serveurs VM NGINX pour gérer les requêtes HTTP(S).
- Base de Données (BDD): Deux serveurs VM MySQL configurés en réplication Master/Slave pour la haute disponibilité et la répartition de charge.
- Puppet Master: Une VM pour gérer la configuration automatique des autres VMs via Puppet.
- Load Balancers: NGINX pour équilibrer la charge et optimiser la distribution des requêtes entrantes.
- DNS: Serveur BIND9 pour la résolution de noms de domaine interne.

# Sécurité et Haute Disponibilité
- HTTPS pour sécuriser les communications.
- Isolation d'exécution pour sécuriser l'exécution des scripts étudiants.
- Haute disponibilité configurée avec Corosync pour les serveurs web et bases de données.

# Mise en Place
## Prérequis
- Debian 11 sur toutes les VMs.
- Puppet pour la gestion de configuration.
- NGINX pour le load balancing et reverse proxy.
- MySQL pour la gestion des bases de données.
- BIND9 pour le serveur DNS interne.

## Configuration des VMs
### Installation et Configuration de Puppet
- Installation sur le Master Puppet:
```bash
sudo wget https://apt.puppet.com/puppet8-release-bullseye.deb
sudo dpkg -i puppet8-release-bullseye.deb
sudo apt update
sudo apt install puppetserver -y
sudo systemctl start puppetserver
sudo systemctl enable puppetserver
```

- Installation sur les Agents:
```bash
sudo wget https://apt.puppet.com/puppet8-release-bullseye.deb
sudo dpkg -i puppet8-release-bullseye.deb
sudo apt update
sudo apt install puppet-agent -y
sudo ln -s /opt/puppetlabs/bin/puppet /usr/local/bin/puppet
sudo puppet ssl bootstrap
```

- Configuration sur les Agents:
Ajouter le serveur Puppet dans /etc/puppetlabs/puppet/puppet.conf:
```bash
[main]
server = puppetmaster.localdomain.lan
```

- Signature des Certificats sur le Master:
```bash
sudo puppetserver ca sign --all
```

### Configuration Réseau
Configurer /etc/hosts pour la résolution de nom interne:

```bash
192.168.236.136 puppetmaster.localdomain.lan
```

# Ajouter les autres IPs et hostnames selon la configuration
## Déploiement de l'Infrastructure
Utiliser les fichiers manifestes Puppet pour déployer les configurations sur les agents, par exemple pour NGINX ou MySQL.

### Processus de Correction
- Upload du fichier par l'étudiant via le site web sécurisé.
- File en attente avant traitement pour assurer l'ordre de traitement et la sécurité.
- Exécution isolée du fichier de l'étudiant comparé à un fichier de référence avec des arguments prédéfinis.
- Comparaison des sorties et attribution d'une note basée sur le pourcentage de réussite.