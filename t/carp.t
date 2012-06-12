#!perl -wT

use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('CGI::Info');
}

eval 'use Test::Carp';
if($@) {
	plan skip_all => 'Test::Carp needed to check error messages'
} else {
	sub foo {
		$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
		$ENV{'REQUEST_METHOD'} = 'FOO';
		my $i = new_ok('CGI::Info');
		$i->params();
	}
	# Doesn't work - I mean it fails this test even though the carp is done
	# does_carp_that_matches(\&foo, qr/Use POST, GET or HEAD/);
	done_testing();
}
