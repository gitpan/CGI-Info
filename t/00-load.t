#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Info' ) || print "Bail out!
";
}

diag( "Testing CGI::Info $CGI::Info::VERSION, Perl $], $^X" );
