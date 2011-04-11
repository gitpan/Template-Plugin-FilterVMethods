use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Test;

#$Template::Test::DEBUG = 1;

my $test = q([% stanza = BLOCK %]
I'm a little teapot,
Short and stout,
Here is my handle,
Here is my spout.
[% END %]);

my $expect = q(I'M A LITTLE TEAPOT,
SHORT AND STOUT,
HERE IS MY HANDLE,
HERE IS MY SPOUT.);

my $data = qq(
-- test --
$test
[% stanza FILTER upper %]
-- expect --
$expect
-- test --
[% USE FilterVMethods %]
$test
[% stanza.filter('upper') %]
-- expect --
$expect
-- test --
[% USE FilterVMethods('upper') %]
$test
[% stanza.upper %]
-- expect --
$expect
-- test --
[% USE FilterVMethods(':all') %]
$test
[% stanza.upper %]
-- expect --
$expect
);

test_expect($data, { POST_CHOMP => 1 } );
