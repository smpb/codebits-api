package Codebits::User;

use Moose;
use Moose::Util::TypeConstraints;
use Regexp::Common qw/URI/;

enum 'Skill', [ qw/php perl ruby python erlang cc cocoa dotnet java javascript css api web embbeded mobile hardware microformats security sysadmin desktop design/ ];

# TODO - I don't yet know the designation for the rejected users
enum 'Status', [ qw/undefined accepted review/ ];


has 'id' => (
  is  => 'ro',
  isa => subtype( 'Int' => where { $_ > 0 } ),
);

has 'blog' => (
  is  => 'rw',
  isa => subtype( 'Str' => where { $_ eq '' or $_ =~ /$RE{URI}{HTTP}/ } ),
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
  isa => subtype( 'Str' => where { $_ => /[0-9a-f]{32}/i } ),
);


no Moose::Util::TypeConstraints;
no Moose;
1;
