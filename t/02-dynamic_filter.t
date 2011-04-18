use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Test;

$Template::Test::DEBUG = 1;

my $test = q([% stanza = BLOCK %]
I'm a little teapot,
Short and stout,
Here is my handle,
Here is my spout.
Gobble, gobble.
[% END %]);

my $expect = q(I'm a little teapot,
Short and stout,
Here is my handle,
Here is my spout.);

my $data = qq(
-- test --
$test
[% stanza FILTER truncate(74, '') %]
-- expect --
$expect
-- test --
[% USE FilterVMethods %]
$test
[% stanza.filter('truncate', 74, '') %]
-- expect --
$expect
-- test --
[% USE FilterVMethods('truncate') %]
$test
[% stanza.truncate(74, '') %]
-- expect --
$expect
-- test --
[% USE FilterVMethods(':all') %]
$test
[% stanza.truncate(74, '') %]
-- expect --
$expect
);

test_expect($data, { POST_CHOMP => 1 } );
