#!/bin/bash

# Définition des chemins et des noms de fichiers
ssl_dir="/etc/puppetlabs/code/environments/production/modules/nginx/files"
cert_file_name="site.localdomain.lan.crt"
key_file_name="site.localdomain.lan.key"

# Création du répertoire pour les certificats s'il n'existe pas
mkdir -p "$ssl_dir"

# Génération du certificat auto-signé
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout "${ssl_dir}/${key_file_name}" \
-out "${ssl_dir}/${cert_file_name}" \
-subj "/CN=site.localdomain.lan/O=My Company Name/C=FR"

# Attribution des permissions pour les récupérer depuis les configs Puppet
chmod 644 "${ssl_dir}/${cert_file_name}"
chmod 644 "${ssl_dir}/${key_file_name}"

echo "Certificat et clé générés dans ${ssl_dir}"