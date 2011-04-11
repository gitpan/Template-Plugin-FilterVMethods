use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Plugin::HTML::Strip;
use Template::Test;

#$Template::Test::DEBUG = 1;

my $test = q([% stanza = BLOCK %]
<p>I'm a little teapot,</p>
Short <em>and</em> stout,
<strong>Here</strong> is my handle,
Here is my <span style="color:blue">spout.</span>
[% END %]);

my $expect = q(I'm a little teapot,
Short and stout,
Here is my handle,
Here is my spout.);

my $data = qq(
-- test --
$test
[% USE HTML.Strip %]
[% stanza FILTER html_strip %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods %]
$test
[% stanza.filter('html_strip') %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods('html_strip') %]
$test
[% stanza.html_strip %]
-- expect --
$expect
-- test --
[% USE HTML.Strip %]
[% USE FilterVMethods(':all') %]
$test
[% stanza.html_strip %]
-- expect --
$expect
);

test_expect($data, { POST_CHOMP => 1 } );
