use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Plugin::HTML::Strip;
use Template::Test;

$Template::Test::DEBUG = 1;

my $test = q([% stanza = BLOCK %]
<p>I'm a little teapot,</p>
Short <em>and</em> stout,
<strong>Here</strong> is my handle,
Here is my <span style="color:blue">spout.</span>
Gobble,<br />gobble.
[% END %]);

my $expect = q(I'M A LITTLE TEAPOT,
SHORT AND STOUT,
HERE IS MY HANDLE,
HERE IS MY SPOUT.);

my $data = qq(
-- test --
$test
[% USE HTML.Strip %]
[% USE FilterVMethods %]
[% stanza FILTER html_strip FILTER truncate(74, '') FILTER upper %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods %]
$test
[% stanza.filter('html_strip').filter('truncate', 74, '').filter('upper') %]
-- expect --
$expect
-- test --
[% USE HTML.Strip
	emit_spaces = 0
%]
[% USE FilterVMethods('upper', 'truncate', 'html_strip') %]
$test
[% stanza.html_strip.truncate(74, '').upper %]
-- expect --
$expect
-- test --
[% USE HTML.Strip
	emit_spaces = 0
%]
[% USE FilterVMethods(':all') %]
$test
[% stanza.html_strip.filter('lower').truncate(74, '').upper %]
-- expect --
$expect
);

test_expect($data, { POST_CHOMP => 1 } );
