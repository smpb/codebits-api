use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Codebits',
    AUTHOR              => q{Sérgio Bernardino <me@sergiobernardino.net>},
    VERSION_FROM        => 'lib/Codebits/API.pm',
    ABSTRACT            => 'Codebits API implementation.',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'JSON'          => 0,
        'Moose'         => 1,
        'LWP'           => 1,
        'Crypt::SSLeay' => 0.5,
        'LWP::Protocol::https'  => 1,
    },
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean   => { FILES => 'Codebits-*' },
);
