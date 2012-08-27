#!perl -wT

use strict;
use warnings;
use Test::More;

if($ENV{RELEASE_TESTING}) {
	use Test::Requires {
		'warnings::unused' => 0.04
	};
}

BEGIN {
	use_ok('CGI::Info');
	if($ENV{RELEASE_TESTING}) {
		use warnings::unused -global;
	}
}

if(not $ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

new_ok('CGI::Info');
plan tests => 2;
