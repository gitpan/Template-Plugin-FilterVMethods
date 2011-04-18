use utf8;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Template::Plugin::FilterVMethods',
	AUTHOR        => q{Richard Simões <rsimoes@cpan.org>},
	VERSION_FROM  => 'lib/Template/Plugin/FilterVMethods.pm',
	ABSTRACT_FROM => 'lib/Template/Plugin/FilterVMethods.pm',
	( $ExtUtils::MakeMaker::VERSION >= 6.3002
		? ( 'LICENSE' => 'perl' )
		: () ),
	PL_FILES       => {},
	BUILD_REQUIRES => {
		'ok'                            => '0.02',
		'Test::More'                    => '0.88',
		'Template::Plugin::HTML::Strip' => '0.01',
	},
	PREREQ_PM => {
		'namespace::autoclean'   => '0.09',
		'List::AllUtils'         => '0.02',
		'Moose'                  => '1.24',
		'MooseX::ClassAttribute' => '0.24',
		'MooseX::FollowPBP'      => '0.05',
		'MooseX::NonMoose'       => '0.20',
		'MooseX::Types::Moose'   => '0.25',
		'Template'               => '2.22',
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'Template-Plugin-FilterVMethods-*' },
);

