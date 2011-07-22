#!perl -Tw

use strict;
use warnings;
use Test::More tests => 15;

BEGIN {
	use_ok('CGI::Info');
}

PATHS: {
	delete $ENV{'SERVER_PORT'};
	delete $ENV{'SCRIPT_URI'};
	delete $ENV{'SCRIPT_PROTOCOL'};

	my $i = new_ok('CGI::Info');
	ok(!defined($i->protocol()));

	$ENV{'SCRIPT_URI'} = 'http://www.example.com';
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'http');

	$ENV{'SCRIPT_URI'} = 'https://www.example.com';
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'https');

	$ENV{'SERVER_PORT'} = 443;
        delete $ENV{'SCRIPT_URI'};
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'https');

	$ENV{'SERVER_PORT'} = 80;
        delete $ENV{'SCRIPT_URI'};
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'http');

	$ENV{'SERVER_PORT'} = 21;
        delete $ENV{'SCRIPT_URI'};
	$i = new_ok('CGI::Info');
	ok(!defined($i->protocol()));

	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	delete $ENV{'SERVER_PORT'};
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'http');
}
