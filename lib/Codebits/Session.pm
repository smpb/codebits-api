package Codebits::Session;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;
use Regexp::Common qw/URI/;

use Codebits::User;
use DateTime;

has 'id' => (
  is  => 'ro',
  isa => subtype( 'Int' => where { $_ > 0 } ),
);

has 'speakers' => (
  is  => 'rw',
  isa => 'ArrayRef[Codebits::User]',
);

has 'place' => (
  is  => 'rw',
  isa => subtype( 'Int' => where { $_ > 0 } ),
);

has [ 'lang', 'pfile', 'slideshare', 'description', 'placename', 'title' ] => (
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

has 'start' => (
  is  => 'rw',
  isa => 'DateTime',
);


# builders

sub _session_speakers
{
  my ($self, $sp) = @_;

  print STDERR "pois\n";

  my $speakers = [];
  foreach my $u (@{$sp})
  {
    push(@{$speakers}, Codebits::User->new($u));
  }

  return $speakers;
}

sub _start_date
{
  my ($self, $d) = @_;

  if ($d =~ /([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+):([0-9]+)/)
  {
    return DateTime->new($1, $2, $3, $4, $5, $6);
  }
}


42;
