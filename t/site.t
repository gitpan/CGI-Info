#!perl -w

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
	use_ok('CGI::Info');
}

HOSTNAMES: {
	my $i = new_ok('CGI::Info');

	my $hostname = `hostname`;
	chomp $hostname;

	ok($i->host_name() eq $hostname);
	ok($i->cgi_host_url() eq "http://$hostname");

	if($hostname =~ /^www\.(.+)/) {
		ok($i->domain_name() eq $1);
	} else {
		ok($i->domain_name() eq $hostname);
	}
}
