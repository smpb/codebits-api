package Codebits::API;

use namespace::autoclean;
use LWP;
use JSON;
use Moose;
use Moose::Util::TypeConstraints;
use Email::Valid;
use DateTime;

use Codebits::User;
use Codebits::Talk;
use Codebits::Badge;
use Codebits::Activity;
use Codebits::Session;
use Codebits::Project;

our $AUTHORITY = 'SMPB';
our $timezone = DateTime::TimeZone->new( name => 'local' );

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

    if (defined $obj->{error})
    {
      $self->_set_errstr($obj->{error}->{msg});
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
  my $url = "https://services.sapo.pt/Codebits/user/";

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

    my $user = Codebits::User->new($u);
    return $user;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_user_friends
{
  my ($self, $uid, %options) = @_;
  my $url = "https://services.sapo.pt/Codebits/foaf/";
  %options = map { lc $_ => $options{$_} } keys %options;

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

      if ($options{verbose})
      {
        $user = $self->get_user($u->{id});
        $user->md5mail($u->{md5mail});
      }
      else
      {
        $user = Codebits::User->new($u);
      }

      $user->set_foaf_state($uid, $u->{state});
      push(@{$friends}, $user);
    }

    return $friends;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub friend_accept
{
  my ($self, $id) = @_;
  my $url = "https://services.sapo.pt/Codebits/foafadd/";

  return $self->_foaf($url, $id);
}

sub friend_reject
{
  my ($self, $id) = @_;
  my $url = "https://services.sapo.pt/Codebits/foafreject/";

  return $self->_foaf($url, $id);
}

sub _foaf
{
  my ($self, $url, $id) = @_;

  unless (defined $id)
  {
    $self->_set_errstr('valid user id needed');
    return 0;
  }

  my $response = $self->user_agent->post($url . $id, [ token => $self->token ]);

  if ($response->is_success)
  {
    if ($response->content ne '')
    {
      my $obj = decode_json($response->content);

      if (defined $obj->{error})
      {
        $self->_set_errstr($obj->{error}->{msg});
        return 0;
      }

      return $obj;
    }

    return 1;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_accepted_users
{
  my ($self, %options) = @_;
  my $url = "https://services.sapo.pt/Codebits/users/";
  %options = map { lc $_ => $options{$_} } keys %options;
  $url .= $options{skill} if ($options{skill});

  my $response = $self->user_agent->post($url, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $users = [];

    foreach my $u (@{decode_json($response->content)})
    {
      my $user;

      if ($options{verbose})
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
  my $url = "https://services.sapo.pt/Codebits/usersessions/";
  %options = map { lc $_ => $options{$_} } keys %options;

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
      # AFAIK, this value always comes as 'undef' in this call
      # this is probably because of a bug in the API, so I don't care for it
      delete $s->{lang} unless(defined $s->{lang});

      # this is another bug in this API call:
      # 'place' should be an integer id and 'placename' is its string name
      if ($s->{place} =~ /[a-z]+/i)
      {
        $s->{placename} = $s->{place};
        delete $s->{place};
      }

      for my $date (qw/ start end /)
      {
        if ((defined $s->{$date}) and
            ($s->{$date} =~ /([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+)/))
        {
          $s->{$date} = DateTime->new(
            year      => $1,
            month     => $2,
            day       => $3,
            hour      => $4,
            minute    => $5,
            time_zone => $timezone,
          );
        }
      }

      my $session = Codebits::Session->new($s);

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
  my $url = "https://services.sapo.pt/Codebits/session/";

  unless (defined $sid)
  {
    $self->_set_errstr('valid session id needed');
    return 0;
  }

  my $response = $self->user_agent->post($url . $sid, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $raw_session = decode_json($response->content);

    if (defined $raw_session->{error})
    {
      $self->_set_errstr($raw_session->{error}->{msg});
      return 0;
    }

    my $speakers = [];
    foreach my $u (@{$raw_session->{speakers}})
    {
      push(@{$speakers}, Codebits::User->new($u));
    }
    $raw_session->{speakers} = $speakers;

    for my $date (qw/ start end /)
    {
      if ((defined $raw_session->{$date}) and
          ($raw_session->{$date} =~ /([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+)/))
      {
        $raw_session->{$date} = DateTime->new(
          year      => $1,
          month     => $2,
          day       => $3,
          hour      => $4,
          minute    => $5,
          time_zone => $timezone,
        );
      }
    }

    return Codebits::Session->new($raw_session);
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_proposed_talks
{
  my $self = shift;
  my $url = "https://services.sapo.pt/Codebits/calltalks/";

  my $response = $self->user_agent->post($url);

  if ($response->is_success)
  {
    my $talks = [];
    foreach my $raw_talk (@{decode_json($response->content)})
    {
      $raw_talk->{user} = $self->get_user($raw_talk->{userid});
      delete $raw_talk->{userid};

      if ($raw_talk->{regdate} =~ /([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+)/)
      {
        $raw_talk->{regdate} = DateTime->new(
          year      => $1,
          month     => $2,
          day       => $3,
          hour      => $4,
          minute    => $5,
          time_zone => $timezone,
        );
      }

      push(@$talks, Codebits::Talk->new($raw_talk));
    }

    return $talks;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub talk_upvote
{
  my ($self, $id) = @_;
  my $url = "https://services.sapo.pt/Codebits/calluptalk/";

  return $self->_vote_talk($url, $id);
}

sub talk_downvote
{
  my ($self, $id) = @_;
  my $url = "https://services.sapo.pt/Codebits/calldowntalk/";

  return $self->_vote_talk($url, $id);
}

sub _vote_talk
{
  my ($self, $url, $id) = @_;

  unless (defined $id)
  {
    $self->_set_errstr('valid proposed talk id needed');
    return 0;
  }

  my $response = $self->user_agent->post($url . $id, [ token => $self->token ]);

  if ($response->is_success)
  {
    if ($response->content ne '')
    {
      my $obj = decode_json($response->content);

      if (defined $obj->{error})
      {
        $self->_set_errstr($obj->{error}->{msg});
        return 0;
      }

      return $obj;
    }

    return 1;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_badges
{
  my $self = shift;
  my $url = "https://services.sapo.pt/Codebits/listbadges";

  my $response = $self->user_agent->post($url);

  if ($response->is_success)
  {
    my $badges = [];
    my $content = decode_json($response->content);

    if ((ref($content) eq 'HASH') and (defined $content->{error}))
    {
      $self->_set_errstr($content->{error}->{msg});
      return 0;
    }

    foreach my $raw_badge (@$content)
    {
      push(@$badges, Codebits::Badge->new($raw_badge));
    }

    return $badges;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_badges_users
{
  my ($self, $id, %options) = @_;
  my $url = "https://services.sapo.pt/Codebits/badgesusers/";
  %options = map { lc $_ => $options{$_} } keys %options;

  my $response = $self->user_agent->post($url . $id);

  if ($response->is_success)
  {
    my $users = [];

    foreach my $u (@{decode_json($response->content)})
    {
      my $user;

      $u->{id} = delete $u->{uid};

      if ($options{verbose})
      {
        $user = $self->get_user($u->{id});
        $user->md5mail($u->{md5mail});
      }
      else
      {
        $user = Codebits::User->new($u);
      }

      push(@{$users}, { user => $user, proofurl => $u->{proofurl} });
    }

    return $users;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_calendar
{
  my $self = shift;
  my $url = "https://services.sapo.pt/Codebits/calendar/";

  my $response = $self->user_agent->post($url, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $calendar = [];

    foreach my $raw_activity (@{decode_json($response->content)})
    {
      for my $date (qw/ start end /)
      {
        if ((defined $raw_activity->{$date}) and
            ($raw_activity->{$date} =~ /([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+)/))
        {
          $raw_activity->{$date} = DateTime->new(
            year      => $1,
            month     => $2,
            day       => $3,
            hour      => $4,
            minute    => $5,
            time_zone => $timezone,
          );
        }
      }

      my $activity;

      if (defined $raw_activity->{'id'}) # is it a session?
      {
        my $speakers = [];
        foreach my $sp (@{$raw_activity->{speakers}})
        {
          my $speaker = $self->get_user($sp->{id});
          $speaker->md5mail($sp->{md5mail});
          $speaker->sapo($sp->{sapo});
          $speaker->teesize($sp->{teesize});

          push(@$speakers, $speaker);
        }
        $raw_activity->{speakers} = $speakers;
        $activity = Codebits::Session->new($raw_activity);
      }
      else # it's a generic codebits activity
      {
        $activity = Codebits::Activity->new($raw_activity);
      }

      push(@$calendar, $activity);
    }

    return $calendar;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_projects
{
  my $self = shift;
  my $url = "https://services.sapo.pt/Codebits/projects";

  my $response = $self->user_agent->post($url, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $projects = [];

    foreach my $raw_project (@{decode_json($response->content)})
    {
      # AFAIK, this value always comes as 'undef' in this call
      # besides, what we want is 'date_created' and 'date_modified' fields,
      # so I don't care for it
      delete $raw_project->{regdate};
      my $project = Codebits::Project->new($raw_project);

      push(@$projects, $project);
    }

    return $projects;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_project
{
  my ($self, $pid, %options) = @_;
  my $url = "https://services.sapo.pt/Codebits/project/";
  %options = map { lc $_ => $options{$_} } keys %options;

  unless (defined $pid)
  {
    $self->_set_errstr('valid project id needed');
    return 0;
  }

  my $response = $self->user_agent->post($url . $pid, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $raw_project = decode_json($response->content);

    if (defined $raw_project->{error})
    {
      $self->_set_errstr($raw_project->{error}->{msg});
      return 0;
    }

    my $users = [];
    foreach my $u (@{$raw_project->{users}})
    {
      my $user;
      if ($options{verbose})
      {
        $user = $self->get_user($u->{id});
        $user->md5mail($u->{md5mail});
      }
      else
      {
        $user = Codebits::User->new($u);
      }

      for my $date (qw/ date_created date_modified /)
      {
        if ((defined $raw_project->{$date}) and
            ($raw_project->{$date} =~ /([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+)/))
        {
          $raw_project->{$date} = DateTime->new(
            year      => $1,
            month     => $2,
            day       => $3,
            hour      => $4,
            minute    => $5,
            time_zone => $timezone,
          );
        }
      }

      push(@$users, $user);
    }
    $raw_project->{users} = $users;

    return Codebits::Project->new($raw_project);
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub get_project_votes
{
  my ($self, %options) = @_;
  my $url = "https://services.sapo.pt/Codebits/votes/";
  %options = map { lc $_ => $options{$_} } keys %options;

  my $response = $self->user_agent->post($url);

  if ($response->is_success)
  {
    my $votes = decode_json($response->content);

    if ($options{verbose})
    {
      $votes->{project} = $self->get_project($votes->{project});
    }

    return $votes;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}

sub project_upvote
{
  my ($self, %options) = @_;

  return $self->_vote_project(1, %options);
}

sub project_downvote
{
  my ($self, %options) = @_;

  return $self->_vote_project(0, %options);
}

sub _vote_project
{
  my ($self, $vote, %options) = @_;
  my $url = "https://services.sapo.pt/Codebits/vote/";
  %options = map { lc $_ => $options{$_} } keys %options;

  my $response = $self->user_agent->post($url . $vote, [ token => $self->token ]);

  if ($response->is_success)
  {
    my $vote = decode_json($response->content);

    if (defined $vote->{error})
    {
      $self->_set_errstr($vote->{error}->{msg});
      return 0;
    }

    if ($options{verbose})
    {
      $vote->{project} = $self->get_project($vote->{project});
    }

    return $vote;
  }

  $self->_set_errstr($response->status_line);
  return 0;
}


42;
