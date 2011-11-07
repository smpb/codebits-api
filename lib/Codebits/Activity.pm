package Codebits::Activity;

use namespace::autoclean;
use Moose;
use DateTime;

has [ 'title', 'placename' ] => (
  is  => 'rw',
  isa => 'Str',
);

has 'place' => (
  is  => 'rw',
  isa => 'Int',
);

has 'start' => (
  is      => 'rw',
  isa     => 'DateTime',
  lazy    => 1,
  default => sub { return DateTime->now; },
);

has 'end' => (
  isa         => 'rw',
  isa         => 'DateTime',
  lazy_build  => 1,
);

# by default, the event ends 45 minutes later than its start
sub _build_end
{
  my $self = shift;
  return DateTime->from_epoch($self->start->epoch + 2700);
}


42;
