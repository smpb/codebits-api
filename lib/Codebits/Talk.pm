package Codebits::Talk;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

use Codebits::User;
use DateTime;

has [ 'id', 'down', 'up' ] => (
  is  => 'ro',
  isa => subtype( 'Int' => where { $_ > 0 } ),
);

has 'user' => (
  is  => 'rw',
  isa => 'Codebits::User',
);

has ['lang', 'title', 'description', 'rated'] => (
  is  => 'rw',
  isa => 'Str',
);

has 'regdate' => (
  is  => 'rw',
  isa => 'DateTime',
);


1;
