package Codebits::Project;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;
use Regexp::Common qw/URI/;
use DateTime;

use Codebits::User;

enum 'Status', [ qw/open closed/ ];

has [ 'id', 'owner_id' ] => (
  is  => 'ro',
  isa => subtype( 'Int' => where { $_ > 0 } ),
);

has [ 'edition', 'order', 'presentation_position' ] => (
  is  => 'rw',
  isa => subtype( 'Int' => where { $_ >= 0 } ),
);

has 'users' => (
  is  => 'rw',
  isa => 'ArrayRef[Codebits::User]',
);

has [ 'date_created', 'date_modified' ] => (
  is  => 'rw',
  isa => 'DateTime',
);

has 'status' => (
  is  => 'rw',
  isa => 'Status',
);

has [ 'title', 'abstract', 'description', 'location', 'video_offset', 'skype' ] => (
  is  => 'rw',
  isa => 'Str',
);

has [ 'url', 'videourl' ] => (
  is  => 'rw',
  isa => subtype( 'Str' => where { $_ =~ s/https/http/i;
      $_ eq '' or
      $_ =~ /$RE{URI}{HTTP}/
    } ),
);


42;
