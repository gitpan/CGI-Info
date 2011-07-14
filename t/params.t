#!perl -wT

use strict;
use warnings;
use Test::More tests => 22;

BEGIN {
	use_ok('CGI::Info');
}

PARAMS: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'foo=bar';

	my $i = new_ok('CGI::Info');
	my %p = %{$i->params()};
	ok($p{foo} eq 'bar');
	ok(!defined($p{fred}));

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';

	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok($p{foo} eq 'bar');
	ok($p{fred} eq 'wilma');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&foo=baz';

	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok($p{foo} eq 'bar, baz');
	ok($p{fred} eq 'wilma');

	# Reading twice should yield the same result
	%p = %{$i->params()};
	ok($p{foo} eq 'bar, baz');

	$ENV{'QUERY_STRING'} = 'foo=&fred=wilma';
	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok(!defined($p{foo}));
	ok($p{fred} eq 'wilma');

	$ENV{'QUERY_STRING'} = 'foo%41=%20bar';
	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok($p{'fooA'} eq ' bar');

	delete $ENV{'QUERY_STRING'};
	$i = new_ok('CGI::Info');
	ok(!$i->params());

	$ENV{'REQUEST_METHOD'} = 'HEAD';
	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';
	$i = new_ok('CGI::Info');
	ok(!$i->params());

	# FIXME: Gives "Undefined subroutine &Test::Carp::does_carp_that_matches"
	# SKIP: {
		# eval { 'require Test:Carp' };

		# if($@) {
			# diag('Test::Carp not installed');
			# skip "Test::Carp not installed", 1;
		# }

		# $ENV{'REQUEST_METHOD'} = 'FOO';
		# $i = new_ok('CGI::Info');
		# Test::Carp::does_carp_that_matches(\$i->params(), qr/Use Get or Post/);
	# }

	$ENV{'REQUEST_METHOD'} = 'FOO';
	$i = new_ok('CGI::Info');

	local $SIG{__WARN__} = sub { die $_[0] };
	eval { $i->params() };
	ok($@ =~ /Use Post or Get/);
}
