package Codebits::Session;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;
use Regexp::Common qw/URI/;

use Codebits::User;

extends 'Codebits::Activity';

has 'id' => (
  is  => 'ro',
  isa => subtype( 'Int' => where { $_ > 0 } ),
);

has 'speakers' => (
  is  => 'rw',
  isa => 'ArrayRef[Codebits::User]',
);

has [ 'lang', 'pfile', 'slideshare', 'description' ] => (
  is  => 'rw',
  isa => 'Str',
);

has 'video' => (
  is  => 'rw',
  isa => subtype( 'Str' => where { $_ =~ s/https/http/i;
      $_ eq '' or
      $_ =~ /$RE{URI}{HTTP}/
    } ),
);


42;
