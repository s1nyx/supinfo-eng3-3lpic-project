#!/bin/bash

# Mettre à jour les paquets et installer Pacemaker et Corosync
apt-get update
apt-get install -y pacemaker corosync crmsh

# Configurer Corosync
cat > /etc/corosync/corosync.conf <<EOF
totem {
    version: 2
    cluster_name: mycluster
    transport: udpu
    interface {
        ringnumber: 0
        bindnetaddr: 192.168.236.0
        broadcast: yes
        mcastport: 5405
    }
}

nodelist {
    node {
        ring0_addr: 192.168.236.142
        nodeid: 1
    }
    node {
        ring0_addr: 192.168.236.143
        nodeid: 2
    }
    node {
        ring0_addr: 192.168.236.140
        nodeid: 3
    }
    node {
        ring0_addr: 192.168.236.144
        nodeid: 4
    }
    node {
        ring0_addr: 192.168.236.133
        nodeid: 5
    }
    node {
        ring0_addr: 192.168.236.145
        nodeid: 6
    }
}

quorum {
    provider: corosync_votequorum
    two_node: 0
}

logging {
    to_syslog: yes
}
EOF


# Démarrer Corosync et Pacemaker
systemctl enable corosync
systemctl enable pacemaker
systemctl start corosync
systemctl start pacemaker

# Vérifier l'état du cluster
corosync-cfgtool -s
crm status

sudo crm

# Si elle n'est pas déjà installée, installer l'IP virtuelle
configure primitive p_nginx_vip ocf:heartbeat:IPaddr2 \
  params ip=192.168.236.150 cidr_netmask=24 \
  op monitor interval=10s

# Configurer le service Nginx
configure primitive p_nginx_service ocf:heartbeat:nginx \
  params configfile="/etc/nginx/nginx.conf" \
  op monitor interval=10s
