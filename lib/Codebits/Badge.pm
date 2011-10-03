package Codebits::Badge;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;
use Regexp::Common qw/URI/;


has 'id' => (
  is  => 'ro',
  isa => subtype( 'Int' => where { $_ > 0 } ), 
);

has 'usercount' => (
  is  => 'rw',
  isa => subtype( 'Int' => where { $_ > 0 } ), 
);

has [ 'title', 'description' ] => (
  is  => 'rw',
  isa => 'Str',
);

has 'img' => (
  is  => 'rw',
  isa => subtype( 'Str' => where { $_ =~ s/https/http/i;
      $_ eq '' or
      $_ =~ /$RE{URI}{HTTP}/
    } ),
);


42;
