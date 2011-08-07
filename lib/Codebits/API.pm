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

has 'password' => (
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

has 'user_agent' => (
  is => 'ro',
  isa => 'LWP::UserAgent',
  default => sub { LWP::UserAgent->new( agent => 'Codebits::API' ) },

);

# methods

sub login
{
  my $self  = shift;
  my $url   = "https://services.sapo.pt/Codebits/gettoken";

  unless ((defined $self->email) && (defined $self->password))
  {
    $self->_set_errstr('invalid e-mail and/or password provided');
    return 0;
  }
  
  my $response = $self->user_agent->post($url, [ user => $self->email, password => $self->password ]);

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
