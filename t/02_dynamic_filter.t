use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Test;

#$Template::Test::DEBUG = 1;

my $test = q([% stanza = BLOCK %]
I'm a little teapot,
Short and sad and stout,
Here is my handle,
Here is my spout.
[% END %]);

my $expect = q(I'm a little teapot,
Short and stout,
Here is my handle,
Here is my spout.);

my $data = qq(
-- test --
$test
[% stanza FILTER remove(' and sad') %]
-- expect --
$expect
-- test --
[% USE FilterVMethods %]
$test
[% stanza.filter('remove', ' and sad') %]
-- expect --
$expect
-- test --
[% USE FilterVMethods('remove') %]
$test
[% stanza.remove(' and sad') %]
-- expect --
$expect
-- test --
[% USE FilterVMethods(':all') %]
$test
[% stanza.remove(' and sad') %]
-- expect --
$expect
);

test_expect($data, { POST_CHOMP => 1 } );
