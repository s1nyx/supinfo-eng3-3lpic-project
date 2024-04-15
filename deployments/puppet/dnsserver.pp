node 'dns.localdomain.lan' {
  class { 'bind':
    listen_on         => [ '127.0.0.1', '192.168.236.139' ], # Remplacez la deuxième IP par l'adresse IP de votre serveur DNS
    listen_on_v6      => [ 'none' ],
    allow_query       => [ 'localhost', '192.168.236.0/24', 'any' ], # Ajustez le sous-réseau selon votre environnement
    allow_query_cache => [ 'localhost', '192.168.236.0/24', 'any' ],
    allow_recursion   => [ 'localhost', '192.168.236.0/24', 'any' ],
  }

  # Exemple pour définir une zone primaire pour site.localdomain.lan
  bind::zone::primary { 'site.localdomain.lan':
    source => 'puppet:///modules/bind/site.localdomain.lan.zone',
  }

  bind::zone::primary { 'localdomain.lan':
    source => 'puppet:///modules/bind/localdomain.lan.zone',
  }
}
