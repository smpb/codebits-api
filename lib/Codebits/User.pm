package Codebits::User;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;
use Regexp::Common qw/URI/;

enum 'Skill', [ qw/api cc clojure cocoa cooking css dbdesign design desktop dotnet embbeded erlang hardware java javascript max microformats mobile nosql perl php processing python ruby scala security sysadmin visualization web/ ];

# TODO - I don't yet know the designation for the rejected users
enum 'Status', [ qw/undefined notapplied accepted review/ ];


has [ 'id', 'karma' ] => (
  is  => 'ro',
  isa => subtype( 'Int' => where { $_ > 0 } ),
);

has [ 'blog', 'coderep' ] => (
  is  => 'rw',
  isa => subtype( 'Str' => where { $_ =~ s/https/http/i;
      $_ eq '' or
      $_ =~ /$RE{URI}{HTTP}/
    } ),
);

has 'status' => (
  is  => 'rw',
  isa => 'Status',
);

has [ 'bio', 'name', 'nick', 'twitter' ] => (
  is  => 'rw',
  isa => 'Str',
);

has 'skills' => (
  is  => 'rw',
  isa => 'ArrayRef[Skill]',
);

has 'md5mail' => (
  is  => 'rw',
  isa => subtype( 'Str' => where { $_ =~ /[0-9a-f]{32}/i } ),
);


42;
