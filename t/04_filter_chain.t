use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Plugin::HTML::Strip;
use Template::Test;

#$Template::Test::DEBUG = 1;

my $test = q([% stanza = BLOCK %]
<p>I'm a little teapot,</p>
Tall <em>and</em> stout,
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
[% stanza FILTER upper FILTER replace('TALL', 'SHORT') FILTER html_strip %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods %]
$test
[% stanza.filter('upper').filter('replace', 'TALL', 'SHORT').filter('html_strip') %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods('upper', 'replace', 'html_strip') %]
$test
[% stanza.upper.replace('TALL', 'SHORT').html_strip %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods(':all') %]
$test
[% stanza.upper.filter('lower').replace('tall', 'short').html_strip.filter('upper') %]
-- expect --
$expect
);

test_expect($data, { POST_CHOMP => 1 } );
