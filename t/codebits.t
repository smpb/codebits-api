#!perl
use 5.10.1;

use strict;
use autodie;
use warnings;

use Test::More;
use Test::Moose;
use Term::UI;
use Term::ReadLine;

use Codebits::API;
use Codebits::User;
use Codebits::Badge;
use Codebits::Activity;
use Codebits::Session;
use Codebits::Project;
use Codebits::Bot;

BEGIN
{
  use_ok('Codebits::API');
  use_ok('Codebits::User');
  use_ok('Codebits::Badge');
  use_ok('Codebits::Activity');
  use_ok('Codebits::Session');
  use_ok('Codebits::Project');
  use_ok('Codebits::Bot');
}

my $term = Term::ReadLine->new('Test questions');

my $bool = $term->ask_yn(
  prompt  => "Do you wish to continue? ",
  default => "y",
  print_me => "These tests require valid authentication for 'http://codebits.eu/',",
);

SKIP:
{
  skip "User chose to abort authenticated tests", 1 unless ($bool);

  my $email = $term->get_reply(
    prompt => "'codebits.eu' email: ",
  );

  my $password = $term->get_reply(
    prompt => "'codebits.eu' password: ",
  );

  my $api = new_ok('Codebits::API' => [ 'email', $email, 'password', $password ]);
  meta_ok($api);

  has_attribute_ok($api, 'email', "API has an email.");
  has_attribute_ok($api, 'password', "API has a password.");
  has_attribute_ok($api, 'errstr', "API has an error string.");
  has_attribute_ok($api, 'token', "API has a token.");
  can_ok($api, qw/ login get_user get_user_friends get_accepted_users
                   friend_accept friend_reject get_badges get_badges_users
                   get_proposed_talks talk_downvote talk_upvote
                   get_calendar get_session get_user_sessions /);

  my $user_id = $api->login;
  ok($user_id > 0, 'Login sucessful.');

  my $user = $api->get_user($user_id);
  meta_ok($user);
  isa_ok($user, 'Codebits::User');
  has_attribute_ok($user, 'id', "User has an id.");
  has_attribute_ok($user, 'karma', "User has karma.");
  has_attribute_ok($user, 'blog', "User has a blog.");
  has_attribute_ok($user, 'coderep', "User has a coderep.");

  isa_ok(shift $api->get_user_friends($user_id), 'Codebits::User');

  my $user_with_badge = shift $api->get_badges_users(2);
  ok(defined $user_with_badge->{proofurl}, "There's a 'proofurl' field.");
  ok(defined $user_with_badge->{user}, "There's a 'user' field.");
  isa_ok($user_with_badge->{user}, 'Codebits::User');
  isa_ok(shift $api->get_badges, 'Codebits::Badge');

  isa_ok($api->get_session(186), 'Codebits::Session');
  isa_ok(shift $api->get_user_sessions($user_id), 'Codebits::Session');

  isa_ok(shift $api->get_proposed_talks, 'Codebits::Talk');

  isa_ok(shift $api->get_calendar, 'Codebits::Activity');

  isa_ok(shift $api->get_projects, 'Codebits::Project');
  isa_ok($api->get_project(253), 'Codebits::Project');

  my $votes = $api->get_project_votes;
  ok($votes->{yes} =~ /\d+/, 'We have the number of "yes" from the votes');
  ok($votes->{no} =~ /\d+/, 'We have the number of "no" from the votes');
  ok($votes->{project} =~ /\d+/, 'We have a project id from the votes');
  $votes = $api->get_project_votes(verbose => 1);
  isa_ok($votes->{project}, 'Codebits::Project');
  my $vote = $api->project_downvote;
  ok($vote->{project} =~ /\d+/, 'We have a project id from the vote');
  ok($vote->{result} =~ /\d+/, 'We have a result from our vote');
  $vote = $api->project_upvote(verbose => 1);
  isa_ok($vote->{project}, 'Codebits::Project');

  isa_ok($api->get_user_bot(10), 'Codebits::Bot');
};

done_testing;
