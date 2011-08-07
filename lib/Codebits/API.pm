package Codebits::API;

use LWP;
use JSON;
use Moose;

use Data::Dumper;

our $VERSION  = '0.1';
our $AUTHORITY = 'SMPB';

has 'email' => (
  is    => 'ro',
  isa   => 'Str',
);

has 'pass' => (
  is    => 'ro',
  isa   => 'Str',
);

has 'token' => (
  is        => 'ro',
  writer    => '_set_token',
  predicate => 'has_token',
);

has 'errstr' => (
  is        => 'ro',
  writer => '_set_errstr',
  isa   => 'Str',
);

# methods

sub login
{
  my $self  = shift;
  my $ua    = LWP::UserAgent->new;

  unless ((defined $self->email) && (defined $self->pass))
  {
    $self->_set_errstr('invalid e-mail and/or password provided');
    return 0;
  }
  
  my $request   = "https://services.sapo.pt/Codebits/gettoken?user=" . $self->email . "&password=" . $self->pass;
  my $response = $ua->get($request);

  if ($response->is_success)
  {
    my $obj = decode_json($response->content);
    if (defined $obj->{'error'})
    {
      $self->_set_errstr($obj->{'error'}->{'msg'});
      return 0;
    }

    $self->_set_token($obj->{'token'});
    return $obj->{'uid'};
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

no Moose;
1;
