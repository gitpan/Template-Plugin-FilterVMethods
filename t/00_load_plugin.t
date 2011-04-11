use strict;
use warnings;
use Test::More tests => 2;
use Template::Context;
use ok 'Template::Plugin::FilterVMethods';

my $context = Template::Context->new;
ok( my $plugin = Template::Plugin::FilterVMethods->new($context) );
