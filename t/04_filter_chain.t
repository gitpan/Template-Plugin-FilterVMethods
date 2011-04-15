use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Plugin::HTML::Strip;
use Template::Test;

$Template::Test::DEBUG = 1;

my $test = q([% stanza = BLOCK %]
<p>I'm a little teapot,</p>
Short and sad <em>and</em> stout,
<strong>Here</strong> is my handle,
Here is my <span style="color:blue">spout.</span>
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
[% stanza FILTER upper FILTER remove(' AND SAD') FILTER html_strip %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods %]
$test
[% stanza.filter('upper').filter('remove', ' AND SAD').filter('html_strip') %]
-- expect --
$expect
-- test --
[% USE HTML.Strip
	emit_spaces = 0
%]
[% USE FilterVMethods('upper', 'removed', 'html_strip') %]
$test
[% stanza.upper.remove(' AND SAD').html_strip %]
-- expect --
$expect
-- test --
[% USE HTML.Strip
	emit_spaces = 0
%]
[% USE FilterVMethods(':all') %]
$test
[% stanza.filter('lower').remove(' and sad').html_strip.upper %]
-- expect --
$expect
);

test_expect($data, { POST_CHOMP => 1 } );
