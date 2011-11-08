package Codebits::Bot;

use namespace::autoclean;
use Moose;
use URI::Escape;

has [ 'balloon', 'botfile' ] => (
  is      => 'rw',
  isa     => 'Str',
  default => '',
);

has [ 'arms', 'bgcolor', 'body', 'eyes', 'grad', 'head', 'legs', 'mouth' ] => (
  is      => 'rw',
  isa     => 'Int',
  default => 0,
);

# Format is as follows:
# body,bgcolor,grad,eyes,mouth,legs,head,arms,balloon. 
sub serialize
{
  my $self = shift;

  my $output = join ',',
    ($self->_normalize($self->body),
     $self->_normalize($self->bgcolor),
     $self->_normalize($self->grad),
     $self->_normalize($self->eyes),
     $self->_normalize($self->mouth),
     $self->_normalize($self->legs),
     $self->_normalize($self->head),
     $self->_normalize($self->arms)
    );

  if ((defined $self->balloon) and ($self->balloon ne ''))
  {
    $output .= ',' . uri_escape($self->balloon);
  }

  return $output;
}

sub _normalize
{
  my ($self, $value) = @_;

  return sprintf("%02d", $value) if ($value > 0 and $value < 10);
  return $value;
}


42;
