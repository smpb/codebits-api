package Codebits::API;

use LWP;
use JSON;
use Moose;
use Moose::Util::TypeConstraints;
use Email::Valid;

use Codebits::User;

our $VERSION  = '0.1';
our $AUTHORITY = 'SMPB';


has 'email' => (
  is    => 'ro',
  isa   => subtype( 'Str' => where { Email::Valid->address($_) } ),
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
  my $url   = "https://services.sapo.pt/Codebits/gettoken/";

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

sub get_user
{
  my ($self, $uid) = @_;
  my $url  = "https://services.sapo.pt/Codebits/user/";

  my $response = $self->user_agent->post($url . $uid, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $u = decode_json($response->content);

    # this value comes as undef if the user hasn't applied yet
    # and I don't really like that
    $u->{status} = 'undefined' unless(defined $u->{status});
    my $user = Codebits::User->new($u);
    return $user;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_user_friends
{
  my ($self, $uid, %options) = @_;
  my $url  = "https://services.sapo.pt/Codebits/foaf/";

  my $response = $self->user_agent->post($url . $uid, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $friends = [];

    foreach my $u (@{decode_json($response->content)})
    {
      my $user;

      if ($options{verbose} or $options{VERBOSE})
      {
        $user = $self->get_user($u->{id});
        $user->md5mail($u->{md5mail});
      }
      else
      {
        $user = Codebits::User->new($u);
      }

      push(@{$friends}, $user);
    }

    return $friends;
  }

  $self->_set_errstr($response->status_line);
  return 0;

}

sub get_accepted_users
{

}


no Moose;
1;
