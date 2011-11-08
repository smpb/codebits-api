#!perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Codebits::API',
  dist_version  => '0.01',
  dist_author   => 'Sérgio Bernardino <me@sergiobernardino.net>',
  dist_abstract => 'Codebits API implementation.',
  license       => 'perl',
  requires      => {
    'perl'                  => '5.10.1',
    'autodie'               => 2,
    'JSON'                  => 0,
    'Moose'                 => 1,
    'LWP'                   => 1,
    'Crypt::SSLeay'         => 0.5,
    'Email::Valid'          => 0.1,
    'Regexp::Common'        => 1,
    'namespace::autoclean'  => 0,
    'LWP::Protocol::https'  => 1,
    'URI::Escape'           => 3,
  },
  build_requires      => { 'Test::More'     => 0 },
  configure_requires  => { 'Module::Build'  => 0 },
  add_to_cleanup      => [ 'Codebits-*', '*META.*'  ],
);

$build->create_build_script;
