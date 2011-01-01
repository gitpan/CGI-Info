#!perl -w

use strict;
use warnings;
use Test::More tests => 19;

BEGIN {
	use_ok('CGI::Info');
}

PARAMS: {
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'foo=bar';

	my $i = CGI::Info->new();
	ok(defined $i);
	ok($i->isa('CGI::Info'));

	my %p = %{$i->params()};
	ok($p{foo} eq 'bar');
	ok(!defined($p{fred}));

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';

	$i = CGI::Info->new();
	ok(defined $i);
	ok($i->isa('CGI::Info'));

	%p = %{$i->params()};
	ok($p{foo} eq 'bar');
	ok($p{fred} eq 'wilma');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&foo=baz';

	$i = CGI::Info->new();
	ok(defined $i);
	ok($i->isa('CGI::Info'));

	%p = %{$i->params()};
	ok($p{foo} eq 'bar, baz');
	ok($p{fred} eq 'wilma');

	delete $ENV{'QUERY_STRING'};
	$i = CGI::Info->new();
	ok(defined $i);
	ok($i->isa('CGI::Info'));
	ok(!$i->params());

	$ENV{'REQUEST_METHOD'} = 'HEAD';
	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';
	$i = CGI::Info->new();
	ok(defined $i);
	ok($i->isa('CGI::Info'));
	ok(!$i->params());
}
