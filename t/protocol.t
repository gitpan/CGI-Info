#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 24;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

PROTOCOL: {
	delete $ENV{'SERVER_PORT'};
	delete $ENV{'SCRIPT_URI'};
	delete $ENV{'SCRIPT_PROTOCOL'};

	my $i = new_ok('CGI::Info');
	ok(!defined($i->protocol()));
	ok(!defined(CGI::Info->protocol()));

	$ENV{'SCRIPT_URI'} = 'http://www.example.com';
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'http');

	$ENV{'SCRIPT_URI'} = 'xyzzy';
	$i = new_ok('CGI::Info');
	ok(!defined($i->protocol()));

	$ENV{'SCRIPT_URI'} = 'https://www.example.com';
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'https');

	$ENV{'SERVER_PORT'} = 443;
        delete $ENV{'SCRIPT_URI'};
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'https');
	ok(CGI::Info->protocol() eq 'https');

	$ENV{'SERVER_PORT'} = 80;
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'http');

	$ENV{'SERVER_PORT'} = 21;
	$i = new_ok('CGI::Info');
	ok(!defined($i->protocol()));
	ok(!defined(CGI::Info->protocol()));

	$ENV{'SERVER_PROTOCOL'} = 'HTTP/1.1';
	$i = new_ok('CGI::Info');
	ok($i->protocol() eq 'http');
	ok(CGI::Info->protocol() eq 'http');

	delete $ENV{'SERVER_PORT'};
	$ENV{'SERVER_PROTOCOL'} = 'UNKNOWN';
	$i = new_ok('CGI::Info');
	ok(!defined($i->protocol()));
}
