use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Codebits',
    AUTHOR              => q{Sérgio Bernardino <me@sergiobernardino.net>},
    VERSION_FROM        => 'lib/Codebits/API.pm',
    ABSTRACT            => 'Codebits API implementation.',
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More'      => 0,
        'JSON'            => 0,
        'Moose'           => 1,
        'LWP'             => 1,
        'Crypt::SSLeay'   => 0.5,
        'Email::Valid'    => 0.1,
        'Regexp::Common'  => 1,
        'namespace::autoclean'  => 0,
        'LWP::Protocol::https'  => 1,
    },
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean   => { FILES => 'Codebits-*' },
);
