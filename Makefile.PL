use utf8;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::FilterVMethods',
    AUTHOR              => q{Richard Simões <rsimoes@cpan.org>},
    VERSION_FROM        => 'lib/Template/Plugin/FilterVMethods.pm',
    ABSTRACT_FROM       => 'lib/Template/Plugin/FilterVMethods.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES      => {
        'ok'                            => 0,
        'Test::More'                    => 0,
        'Template::Plugin::HTML::Strip' => 0,
    },
    PREREQ_PM => {
        'namespace::autoclean'          => 0,
        'List::AllUtils'                => 0,
        'Template'                      => 0,
        'Moose'                         => 0,
        'MooseX::ClassAttribute'        => 0,
        'MooseX::FollowPBP'             => 0,
        'MooseX::NonMoose'              => 0,
        'MooseX::Types::Moose'          => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-FilterVMethods-*' },
);

