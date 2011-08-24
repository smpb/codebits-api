package Codebits::API;

use namespace::autoclean;
use LWP;
use JSON;
use Moose;
use Moose::Util::TypeConstraints;
use Email::Valid;
use DateTime;

use Codebits::User;
use Codebits::Session;

our $VERSION  = '0.1';
our $AUTHORITY = 'SMPB';


has 'email' => (
  is  => 'ro',
  isa => subtype( 'Str' => where { Email::Valid->address($_) } ),
);

has 'password' => (
  is  => 'ro',
  isa => 'Str',
);

has 'token' => (
  is        => 'ro',
  writer    => '_set_token',
  predicate => 'has_token',
);

has 'errstr' => (
  is      => 'ro',
  writer  => '_set_errstr',
  isa     => 'Str',
);

has 'user_agent' => (
  is      => 'ro',
  isa     => 'LWP::UserAgent',
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

  unless (defined $uid)
  {
    $self->_set_errstr('valid user id needed');
    return 0;
  }

  my $response = $self->user_agent->post($url . $uid, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $u = decode_json($response->content);

    if (defined $u->{error})
    {
      $self->_set_errstr($u->{error}->{msg});
      return 0;
    }

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

  unless (defined $uid)
  {
    $self->_set_errstr('valid user id needed');
    return 0;
  }

  my $response = $self->user_agent->post($url . $uid, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $friends = [];
    my $content = decode_json($response->content);

    if ((ref($content) eq 'HASH') and (defined $content->{error}))
    {
      $self->_set_errstr($content->{error}->{msg});
      return 0;
    }

    foreach my $u (@{$content})
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

# TODO - It should've been possible to filter this list by skill, but the API appears
# to be buggy and doesn't behave as advertised
sub get_accepted_users
{
  my ($self, %options) = @_;
  my $url  = "https://services.sapo.pt/Codebits/users/";

  my $response = $self->user_agent->post($url, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $users = [];

    foreach my $u (@{decode_json($response->content)})
    {
      my $user;

      if ($options{verbose} or $options{VERBOSE})
      {
        $user = $self->get_user($u->{id});
      }
      else
      {
        $user = Codebits::User->new($u);
      }

      push(@{$users}, $user);
    }

    return $users;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_user_sessions
{
  my ($self, $uid, %options) = @_;
  my $url  = "https://services.sapo.pt/Codebits/usersessions/";

  unless (defined $uid)
  {
    $self->_set_errstr('valid user id needed');
    return 0;
  }

  my $response = $self->user_agent->post($url . $uid, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $sessions = [];

    foreach my $s (@{decode_json($response->content)})
    {
      my $session = Codebits::Session->new($s);

      if ($options{verbose} or $options{VERBOSE})
      {
        my $user;
        # TODO
      }

      push(@{$sessions}, $session);
    }

    return $sessions;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_session
{
  my ($self, $sid) = @_;
  my $url  = "https://services.sapo.pt/Codebits/session/";

  unless (defined $sid)
  {
    $self->_set_errstr('valid session id needed');
    return 0;
  }

  my $response = $self->user_agent->post($url . $sid, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $raw_session = decode_json($response->content);

    my $speakers = [];
    foreach my $u (@{$raw_session->{speakers}})
    {
      push(@{$speakers}, Codebits::User->new($u));
    }
    $raw_session->{speakers} = $speakers;

    my $date;
    if ($raw_session->{start} =~ /([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+):([0-9]+)/)
    {
      $raw_session->{start} = DateTime->new(
        year    => $1,
        month   => $2,
        hour    => $3,
        day     => $4,
        minute  => $5,
        second  => $6,
      );
    }

    return Codebits::Session->new($raw_session);
  }

  $self->_set_errstr($response->status_line);
  return 0;
}


1;
