package Codebits::User;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;
use Regexp::Common qw/URI/;

enum 'Skill', [ qw/api cc clojure cocoa cooking css dbdesign design desktop dotnet embbeded erlang hardware java javascript max microformats mobile nosql perl php processing python ruby scala security sysadmin visualization web/ ];

enum 'Status', [ qw/notapplied accepted rejected canceled review/ ];


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

has '_foaf_state' => (
  is      => 'rw',
  isa     => 'HashRef',
  traits  => [ 'Hash' ],
  handles => {
    has_foaf_state  => 'exists',
    ids_foaf_state  => 'keys',
    get_foaf_state  => 'get',
    set_foaf_state  => 'set',
  },
);


42;
