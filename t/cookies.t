#!perl -wT

use strict;
use warnings;
use Test::More tests => 14;

BEGIN {
	use_ok('CGI::Info');
}

COOKIES: {
	my $i = new_ok('CGI::Info');

	ok(!defined($i->get_cookie(cookie_name => 'foo')));

	$ENV{'HTTP_COOKIE'} = 'foo=bar';
	$i = new_ok('CGI::Info');
	ok($i->get_cookie(cookie_name => 'foo') eq 'bar');
	ok($i->get_cookie(cookie_name => 'foo') eq 'bar');
	ok(!defined($i->get_cookie(cookie_name => 'bar')));

	$ENV{'HTTP_COOKIE'} = 'fred=wilma;foo=bar';
	$i = new_ok('CGI::Info');
	ok($i->get_cookie(cookie_name => 'foo') eq 'bar');
	ok($i->get_cookie(cookie_name => 'fred') eq 'wilma');
	ok($i->get_cookie({cookie_name => 'fred'}) eq 'wilma');
	ok(!defined($i->get_cookie(cookie_name => 'bar')));
	ok(!defined($i->get_cookie({cookie_name => 'bar'})));

	local $SIG{__WARN__} = sub { die $_[0] };
	eval {
		$i->get_cookie();
	};
	ok($@ =~ /cookie_name argument not given/);
}
