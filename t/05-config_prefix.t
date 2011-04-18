use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Plugin::HTML::Strip;
use Template::Test;

#$Template::Test::DEBUG = 1;

my $test = q([% stanza = BLOCK %]
<p>I'm a little teapot,</p>
Short and sad <em>and</em> stout,
<strong>Here</strong> is my handle,
Here is my <span style="color:blue">spout.</span>
Gobble, gobble.
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
[% stanza FILTER html_strip FILTER remove(' and sad') FILTER truncate(74, '') FILTER upper %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods %]
$test
[% stanza.filter('html_strip').filter('remove', ' and sad').filter('truncate', 74, '').filter('upper') %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods('upper', 'remove', 'truncate', 'html_strip') %]
$test
[% stanza.f_html_strip.f_remove(' and sad').f_truncate(74, '').f_upper %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods(':all') %]
$test
[% stanza.f_html_strip.filter('lower').remove(' and sad').f_truncate(74, '').f_upper %]
-- expect --
$expect
);

test_expect($data, { POST_CHOMP => 1, FVM_PREFIX => 'f_' } );
