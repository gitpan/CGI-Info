#!perl -w

use strict;
use warnings;
use Test::Most tests => 13;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

HOSTNAMES: {
        delete $ENV{'HTTP_HOST'};
        delete $ENV{'SERVER_NAME'};

	my $i = new_ok('CGI::Info');

	my $hostname = `hostname`;
	chomp $hostname;

	ok($i->host_name() eq $hostname);
	ok($i->cgi_host_url() eq "http://$hostname");

	# Check rereading returns the same value
	ok($i->host_name() eq $hostname);

	if($i->host_name() =~ /^www\.(.+)/) {
		ok($i->domain_name() eq $1);
	} else {
		ok($i->domain_name() eq $hostname);
	}

	$ENV{'HTTP_HOST'} = 'www.example.com';
	$i = $i->new();	# Test creating a new object from an existing object
	ok($i->domain_name() eq 'example.com');
	ok($i->host_name() eq 'www.example.com');

	# Check rereading returns the same value
	ok($i->domain_name() eq 'example.com');

        delete $ENV{'HTTP_HOST'};

	$ENV{'SERVER_NAME'} = 'www.bandsman.co.uk';
	$i = new_ok('CGI::Info');
	ok($i->cgi_host_url() eq 'http://www.bandsman.co.uk');;
	ok($i->host_name() eq 'www.bandsman.co.uk');
}
