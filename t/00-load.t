#!perl -T

use strict;

use Test::More tests => 2;

BEGIN {
    use_ok('CGI::Info') || print 'Bail out!';
}

require_ok('CGI::Info') || print 'Bail out!';

diag( "Testing CGI::Info $CGI::Info::VERSION, Perl $], $^X" );
