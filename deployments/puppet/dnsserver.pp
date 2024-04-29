node 'dns.localdomain.lan' {
  class { 'bind':
    listen_on         => [ '127.0.0.1', '192.168.236.147' ],
    listen_on_v6      => [ 'none' ],
    allow_query       => [ 'localhost', '192.168.236.0/24', 'any' ],
    allow_query_cache => [ 'localhost', '192.168.236.0/24', 'any' ],
    allow_recursion   => [ 'localhost', '192.168.236.0/24', 'any' ],
  }

  bind::zone::primary { 'localdomain.lan':
    source => 'puppet:///modules/bind/localdomain.lan.zone',
  }
}
